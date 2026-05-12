"""Nöbetçi eczane servisi.

eczaneler.gen.tr sitesini HTML olarak çekip parse eder; herhangi bir
API anahtarı gerektirmez.
"""

from __future__ import annotations

import logging
import re
from typing import Any

import httpx
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

# Türkçe özel karakterlerin ASCII karşılıkları (URL slug için)
_TR_MAP: dict[str, str] = {
    "ç": "c",
    "Ç": "c",
    "ğ": "g",
    "Ğ": "g",
    "ı": "i",
    "İ": "i",
    "ö": "o",
    "Ö": "o",
    "ş": "s",
    "Ş": "s",
    "ü": "u",
    "Ü": "u",
}

_BASE_URL = "https://www.eczaneler.gen.tr"
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0.0.0 Safari/537.36"
    ),
    "Accept-Language": "tr-TR,tr;q=0.9",
}


def _to_slug(text: str) -> str:
    """Türkçe il/ilçe adını URL slug'ına dönüştürür.

    Örn: "Afyonkarahisar" → "afyonkarahisar", "Çanakkale" → "canakkale"
    """
    for tr_char, ascii_char in _TR_MAP.items():
        text = text.replace(tr_char, ascii_char)
    # Küçük harfe al, boşlukları tire yap, ardışık tireleri tekle
    slug = re.sub(r"-{2,}", "-", text.lower().replace(" ", "-").strip())
    return slug


def _parse_pharmacies(html: str) -> list[dict[str, Any]]:
    """HTML kaynağından eczane listesini ayrıştırır."""
    soup = BeautifulSoup(html, "html.parser")
    pharmacies: list[dict[str, Any]] = []

    for row in soup.find_all("tr"):
        name_tag = row.find("span", class_="isim")
        if not name_tag:
            continue

        name: str = name_tag.get_text(strip=True)

        # Adres bloğu: col-lg-6 div'inin <br> öncesi kısmı
        addr_div = row.find("div", class_="col-lg-6")
        address = ""
        if addr_div:
            # <br> öncesindeki saf metin düğümlerini birleştir
            for content in addr_div.contents:
                tag_name = getattr(content, "name", None)
                if tag_name == "br":
                    break
                if tag_name is None:  # NavigableString
                    address += str(content)
                # İsim/anchor gibi inline etiketlerin içini ekle
                elif tag_name in ("a", "strong", "b"):
                    address += content.get_text()
            address = address.strip()

        # İlçe: bg-info renkli badge (ilk olanı al)
        dist_badge = addr_div and addr_div.find(
            "span", class_=lambda c: c and "bg-info" in c
        )
        district: str = dist_badge.get_text(strip=True) if dist_badge else ""

        # Telefon: py-lg-2 class'ına sahip div (sadece telefon div'inde mevcut)
        phone_div = row.find("div", class_="py-lg-2")
        phone: str = phone_div.get_text(strip=True) if phone_div else ""

        pharmacies.append(
            {
                "name": name,
                "address": address,
                "phone": phone,
                "district": district,
                "lat": None,
                "lon": None,
                "distance_km": None,
            }
        )

    return pharmacies


async def _reverse_geocode(lat: float, lon: float) -> tuple[str, str]:
    """Nominatim ile koordinatları Türkiye'deki il/ilçe adına çevirir.

    Dönen tuple: (il, ilçe). Hata ya da sonuç bulunamazsa ("", "") döner.
    """
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(
                "https://nominatim.openstreetmap.org/reverse",
                params={
                    "lat": lat,
                    "lon": lon,
                    "format": "json",
                    "accept-language": "tr",
                },
                # Nominatim kullanım politikası: User-Agent zorunlu
                headers={"User-Agent": "EczanemApp/1.0 (personal-use)"},
            )
            resp.raise_for_status()
            data = resp.json()
        address = data.get("address", {})
        # Türkiye idari yapısı: state/province = il, county = ilçe
        il_name: str = (
            address.get("province") or address.get("state") or address.get("city") or ""
        )
        ilce_name: str = (
            address.get("county")
            or address.get("city_district")
            or address.get("town")
            or ""
        )
        return il_name.strip(), ilce_name.strip()
    except Exception as exc:  # noqa: BLE001
        logger.warning("Reverse geocoding hatası: %s", exc)
        return "", ""


async def get_nearby_pharmacies(
    lat: float,
    lon: float,
    il: str = "",
    ilce: str = "",
) -> list[dict[str, Any]]:
    """eczaneler.gen.tr'den il/ilçe bazlı nöbetçi eczaneleri çeker.

    `il` boşsa ancak lat/lon sıfır değilse Nominatim ile reverse geocoding
    yapılır ve otomatik il/ilçe tespit edilir.
    İlçe belirtilmezse tüm il listelenir.
    """
    # Koordinat verildi ama il girilmedi → otomatik tespit
    if not il.strip() and (lat != 0.0 or lon != 0.0):
        il, ilce_auto = await _reverse_geocode(lat, lon)
        if not ilce.strip():
            ilce = ilce_auto
        logger.info("Reverse geocoding sonucu: il=%s, ilçe=%s", il, ilce)

    if not il.strip():
        return []

    il_slug = _to_slug(il.strip())
    ilce_slug = _to_slug(ilce.strip()) if ilce.strip() else ""

    url = f"{_BASE_URL}/nobetci-{il_slug}"
    if ilce_slug:
        url += f"-{ilce_slug}"

    logger.info("eczaneler.gen.tr isteği: %s", url)

    try:
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=_HEADERS)
            resp.raise_for_status()
            html = resp.text
    except httpx.HTTPStatusError as exc:
        logger.warning("eczaneler.gen.tr HTTP hatası: %s", exc)
        return []
    except Exception as exc:  # noqa: BLE001
        logger.warning("eczaneler.gen.tr erişim hatası: %s", exc)
        return []

    return _parse_pharmacies(html)
