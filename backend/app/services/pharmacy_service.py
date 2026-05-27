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
) -> dict[str, Any]:
    """eczaneler.gen.tr'den il/ilçe bazlı nöbetçi eczaneleri çeker.

    `il` boşsa ancak lat/lon sıfır değilse Nominatim ile reverse geocoding
    yapılır ve otomatik il/ilçe tespit edilir.
    İlçe belirtilmezse tüm il listelenir.

    Döner: {"pharmacies": [...], "detected_il": str, "detected_ilce": str}
    """
    # Koordinat verildi ama il girilmedi → otomatik tespit
    if not il.strip() and (lat != 0.0 or lon != 0.0):
        il, ilce_auto = await _reverse_geocode(lat, lon)
        if not ilce.strip():
            ilce = ilce_auto
        logger.warning("Reverse geocoding sonucu: il=%s, ilçe=%s", il, ilce)

    detected_il = il.strip()
    detected_ilce = ilce.strip()

    if not detected_il:
        return {"pharmacies": [], "detected_il": "", "detected_ilce": ""}

    il_slug = _to_slug(detected_il)
    ilce_slug = _to_slug(detected_ilce) if detected_ilce else ""

    async def _fetch_pharmacies(url: str) -> list[dict[str, Any]]:
        """Verilen URL'den eczane listesini çekip parse eder; hata durumunda [] döner."""
        try:
            async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
                resp = await client.get(url, headers=_HEADERS)
                resp.raise_for_status()
                return _parse_pharmacies(resp.text)
        except httpx.HTTPStatusError as exc:
            logger.warning("eczaneler.gen.tr HTTP hatası: %s", exc)
            return []
        except Exception as exc:  # noqa: BLE001
            logger.warning("eczaneler.gen.tr erişim hatası: %s", exc)
            return []

    url = f"{_BASE_URL}/nobetci-{il_slug}"
    if ilce_slug:
        url += f"-{ilce_slug}"

    logger.info("eczaneler.gen.tr isteği: %s", url)
    pharmacies = await _fetch_pharmacies(url)

    # İlçe belirtildi ama sonuç boş → il geneline düş
    fallback_to_il = False
    if ilce_slug and not pharmacies:
        fallback_url = f"{_BASE_URL}/nobetci-{il_slug}"
        logger.info(
            "İlçe '%s' için sonuç yok, il geneline düşülüyor: %s",
            detected_ilce,
            fallback_url,
        )
        pharmacies = await _fetch_pharmacies(fallback_url)
        if pharmacies:
            fallback_to_il = True

    return {
        "pharmacies": pharmacies,
        "detected_il": detected_il,
        "detected_ilce": detected_ilce,
        "fallback_to_il": fallback_to_il,
    }


async def get_districts(il: str) -> list[str]:
    """eczaneler.gen.tr'nin il sayfasındaki İlçe Seç kenar çubuğundan
    o ile ait gerçek ilçe adlarını çeker.

    Döner: Sıralı ilçe adları listesi (Türkçe karakterler korunur).
    Hata ya da il bulunamazsa boş liste döner.
    """
    if not il.strip():
        return []

    il_slug = _to_slug(il.strip())
    url = f"{_BASE_URL}/nobetci-{il_slug}"

    try:
        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            resp = await client.get(url, headers=_HEADERS)
            resp.raise_for_status()

        soup = BeautifulSoup(resp.text, "html.parser")
        prefix = f"/nobetci-{il_slug}-"
        seen: set[str] = set()
        districts: list[str] = []

        # Önce "İlçe Seç" başlığının bulunduğu container'a bak
        ilce_sec = soup.find(string=lambda t: t and "İlçe Seç" in t)
        search_root = None
        if ilce_sec:
            search_root = ilce_sec.find_parent(["div", "section", "aside", "ul", "nav"])

        # Container bulunamazsa tüm sayfayı tara (fallback)
        if search_root is None:
            search_root = soup

        for a in search_root.find_all("a", href=True):
            href: str = a["href"]
            if href.startswith(prefix):
                name = a.get_text(strip=True)
                # Uzun ve anlamsız metin olanları filtrele (navigasyon linkleri)
                if name and len(name) < 60 and name not in seen:
                    seen.add(name)
                    districts.append(name)

        return sorted(districts)

    except Exception as exc:  # noqa: BLE001
        logger.warning("İlçe listesi alınamadı (il=%s): %s", il, exc)
        return []
