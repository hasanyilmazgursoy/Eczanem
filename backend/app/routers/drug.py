"""İlaç sorgulama endpoint'leri."""

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel

from app.services.drug_search_guard import query_drug_info_with_guard

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


def _resolve_client_key(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",", 1)[0].strip()

    return request.client.host if request.client else "unknown-client"


@router.post("/search", response_model=DrugSearchResponse)
async def search_drug(request: DrugSearchRequest, http_request: Request):
    """İlaç adıyla arama yapıp detaylı bilgi döndürür."""
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="İlaç adı boş olamaz.")

    result = await query_drug_info_with_guard(
        request.query.strip(),
        client_key=_resolve_client_key(http_request),
    )
    return result
