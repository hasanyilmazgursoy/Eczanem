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


@router.get("/nearby", response_model=NearbyPharmaciesResponse)
async def nearby_pharmacies(
    lat: float = Query(..., description="Kullanıcı enlemi"),
    lon: float = Query(..., description="Kullanıcı boyilamı"),
    il: str = Query(default="", description="İl adı (örn: Istanbul)"),
    ilce: str = Query(default="", description="İlçe adı (örn: Kadikoy)"),
):
    """Koordinat ve il/ilçe bilgisine göre nöbetçi eczaneleri listeler.

    CollectAPI anahtarı yapılandırılmamışsa `api_available: false` ve boş
    liste döner; bu durumda frontend uygun bir mesaj gösterebilir.
    """
    pharmacies = await get_nearby_pharmacies(lat=lat, lon=lon, il=il, ilce=ilce)
    return NearbyPharmaciesResponse(
        pharmacies=pharmacies,
        count=len(pharmacies),
        api_available=bool(pharmacies),
    )
