"""İlaç sorgulama endpoint'leri."""

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from pydantic import BaseModel

from app.services.drug_search_guard import query_drug_info_with_guard
from app.services.gemini_service import query_drug_info_from_image

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


@router.post("/analyze-image", response_model=DrugSearchResponse)
async def analyze_drug_image(file: UploadFile = File(...)):
    """İlaç fotoğrafını Gemini ile analiz ederek muhtemel ilaç bilgisini döndürür."""
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="Yalnızca görsel dosyaları analiz edilebilir.",
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Yüklenen görsel boş olamaz.")

    result = await query_drug_info_from_image(
        image_bytes=image_bytes,
        mime_type=file.content_type,
    )
    return result
