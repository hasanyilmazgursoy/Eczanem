"""İlaç sorgulama endpoint'leri."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.services.openrouter_service import query_drug_info

router = APIRouter()


class DrugSearchRequest(BaseModel):
    query: str


class DrugSearchResponse(BaseModel):
    ilac_adi: str
    etken_madde: str
    ne_icin_kullanilir: str
    dozaj_bilgisi: str
    kullanim_sekli: str
    yan_etkiler: list[str]
    uyarilar: list[str]
    kimler_kullanmamali: list[str]
    disclaimer: str = (
        "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
    )


@router.post("/search", response_model=DrugSearchResponse)
async def search_drug(request: DrugSearchRequest):
    """İlaç adıyla arama yapıp detaylı bilgi döndürür."""
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="İlaç adı boş olamaz.")

    result = await query_drug_info(request.query.strip())
    return result
