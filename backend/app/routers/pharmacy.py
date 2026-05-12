"""Nöbetçi eczane endpoint'leri (FAZ 6)."""

from __future__ import annotations

from fastapi import APIRouter, Query
from pydantic import BaseModel

from app.services.pharmacy_service import get_nearby_pharmacies

router = APIRouter()


class PharmacyItem(BaseModel):
    name: str
    address: str
    phone: str
    district: str
    lat: float | None
    lon: float | None
    distance_km: float | None


class NearbyPharmaciesResponse(BaseModel):
    pharmacies: list[PharmacyItem]
    count: int
    api_available: bool
    # Nominatim ile tespit edilen il/ilçe (konum butonu kullanıldığında dolu olur)
    detected_il: str = ""
    detected_ilce: str = ""


@router.get("/nearby", response_model=NearbyPharmaciesResponse)
async def nearby_pharmacies(
    il: str = Query(default="", description="İl adı (örn: Istanbul)"),
    ilce: str = Query(default="", description="İlçe adı (örn: Kadikoy)"),
    lat: float = Query(default=0.0, description="Kullanıcı enlemi (opsiyonel)"),
    lon: float = Query(default=0.0, description="Kullanıcı boyilamı (opsiyonel)"),
):
    """Koordinat ve il/ilçe bilgisine göre nöbetçi eczaneleri listeler.

    eczaneler.gen.tr'den HTML scrape ile veri çeker; API anahtarı gerekmez.
    """
    result = await get_nearby_pharmacies(lat=lat, lon=lon, il=il, ilce=ilce)
    pharmacies = result["pharmacies"]
    return NearbyPharmaciesResponse(
        pharmacies=pharmacies,
        count=len(pharmacies),
        api_available=bool(pharmacies),
        detected_il=result["detected_il"],
        detected_ilce=result["detected_ilce"],
    )
