"""Nöbetçi eczane servisi (FAZ 6).

CollectAPI entegrasyonu — API anahtarı yoksa veya servis erişilemezse
boş liste döner; frontend "yakında aktif olacak" mesajını gösterir.

API anahtarı .env dosyasına COLLECT_API_KEY olarak eklenir.
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from math import atan2, cos, radians, sin, sqrt
from typing import Any

import httpx

from app.core.config import get_settings

logger = logging.getLogger(__name__)

_COLLECT_API_URL = "https://api.collectapi.com/health/dutyPharmacy"


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """İki koordinat arasındaki mesafeyi kilometre cinsinden hesaplar."""
    R = 6371.0
    dlat = radians(lat2 - lat1)
    dlon = radians(lon2 - lon1)
    a = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon / 2) ** 2
    )
    return R * 2 * atan2(sqrt(a), sqrt(1 - a))


async def get_nearby_pharmacies(
    lat: float,
    lon: float,
    il: str = "",
    ilce: str = "",
) -> list[dict[str, Any]]:
    """En yakın nöbetçi eczaneleri döndürür.

    CollectAPI üzerinden il/ilçe bazlı eczane listesi çeker ve mesafeye
    göre sıralar. API anahtarı yoksa boş liste döner.
    """
    settings = get_settings()
    api_key: str = getattr(settings, "collect_api_key", "")

    if not api_key:
        logger.info(
            "COLLECT_API_KEY yapılandırılmamış; nöbetçi eczane listesi boş döndü."
        )
        return []

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                _COLLECT_API_URL,
                params={"il": il, "ilce": ilce},
                headers={
                    "authorization": f"apikey {api_key}",
                    "content-type": "application/json",
                },
            )
            resp.raise_for_status()
            payload = resp.json()
    except httpx.HTTPStatusError as exc:
        logger.warning("CollectAPI HTTP hatası: %s", exc)
        return []
    except Exception as exc:  # noqa: BLE001
        logger.warning("CollectAPI erişim hatası: %s", exc)
        return []

    raw_list: list[dict] = payload.get("result", [])
    pharmacies: list[dict] = []

    for item in raw_list:
        # CollectAPI koordinat alanları her zaman dolu olmayabilir
        try:
            p_lat = float(item.get("lat") or 0)
            p_lon = float(item.get("lng") or 0)
        except (TypeError, ValueError):
            p_lat = p_lon = 0.0

        distance_km = _haversine_km(lat, lon, p_lat, p_lon) if p_lat and p_lon else None

        pharmacies.append(
            {
                "name": item.get("name", ""),
                "address": item.get("address", ""),
                "phone": item.get("phone", ""),
                "district": item.get("dist", ""),
                "lat": p_lat or None,
                "lon": p_lon or None,
                "distance_km": round(distance_km, 2)
                if distance_km is not None
                else None,
            }
        )

    # Mesafesi bilinenleri öne al, geri kalanlar sona
    pharmacies.sort(
        key=lambda p: p["distance_km"] if p["distance_km"] is not None else float("inf")
    )
    return pharmacies
