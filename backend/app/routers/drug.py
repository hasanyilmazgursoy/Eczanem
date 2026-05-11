"""Ä°laÃ§ sorgulama endpoint'leri."""

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from pydantic import BaseModel

from app.services.drug_search_guard import query_drug_info_with_guard
from app.services.gemini_service import (
    query_drug_interactions,
    query_natural_alternatives,
    query_drug_info_from_image,
    query_prospectus_summary_from_image,
)

router = APIRouter()


class DrugSearchRequest(BaseModel):
    query: str


class DrugInteractionRequest(BaseModel):
    drugs: list[str]


class NaturalAlternativesRequest(BaseModel):
    drug_name: str


class NaturalAlternativeItem(BaseModel):
    ad: str
    tur: str
    aciklama: str
    dikkat: str

class DrugSearchResponse(BaseModel):
    ilac_adi: str
    etken_madde: str
    ne_icin_kullanilir: str
    dozaj_bilgisi: str
    kullanim_sekli: str
    yan_etkiler: list[str]
    uyarilar: list[str]
    kimler_kullanmamali: list[str]
    alternatifler: list[NaturalAlternativeItem] = []
    disclaimer: str = (
        "Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz."
    )


class DrugImageAnalyzeResponse(DrugSearchResponse):
    aday_ilaclar: list[str] = []


class ProspectusSummaryResponse(BaseModel):
    ilac_adi: str
    prospektus_turu: str
    ne_icin_kullanilir: str
    nasil_kullanilir: list[str]
    dikkat_edilmesi_gerekenler: list[str]
    yan_etkiler: list[str]
    saklama_kosullari: list[str]
    ne_zaman_doktora_basvurulmali: list[str]
    disclaimer: str = (
        "Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz."
    )


class DrugInteractionItem(BaseModel):
    ilaclar: list[str]
    risk_seviyesi: str
    neden: str
    oneri: str


class DrugInteractionResponse(BaseModel):
    genel_risk_seviyesi: str
    ozet: str
    dikkat_edilmesi_gerekenler: list[str]
    etkilesimler: list[DrugInteractionItem]
    disclaimer: str = (
        "Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz."
    )



class NaturalAlternativesResponse(BaseModel):
    ilac_adi: str
    hedef: str
    alternatifler: list[NaturalAlternativeItem]
    uyari: str


def _validate_image_upload(file: UploadFile) -> None:
    if not file.content_type or not file.content_type.startswith("image/"):
        raise HTTPException(
            status_code=400,
            detail="YalnÄ±zca gÃ¶rsel dosyalarÄ± analiz edilebilir.",
        )


def _resolve_client_key(request: Request) -> str:
    forwarded_for = request.headers.get("x-forwarded-for")
    if forwarded_for:
        return forwarded_for.split(",", 1)[0].strip()

    return request.client.host if request.client else "unknown-client"


@router.post("/search", response_model=DrugSearchResponse)
async def search_drug(request: DrugSearchRequest, http_request: Request):
    """Ä°laÃ§ adÄ±yla arama yapÄ±p detaylÄ± bilgi dÃ¶ndÃ¼rÃ¼r."""
    if not request.query.strip():
        raise HTTPException(status_code=400, detail="Ä°laÃ§ adÄ± boÅŸ olamaz.")

    result = await query_drug_info_with_guard(
        request.query.strip(),
        client_key=_resolve_client_key(http_request),
    )
    return result


@router.post("/analyze-image", response_model=DrugImageAnalyzeResponse)
async def analyze_drug_image(file: UploadFile = File(...)):
    """Ä°laÃ§ fotoÄŸrafÄ±nÄ± Gemini ile analiz ederek muhtemel ilaÃ§ bilgisini dÃ¶ndÃ¼rÃ¼r."""
    _validate_image_upload(file)

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="YÃ¼klenen gÃ¶rsel boÅŸ olamaz.")

    result = await query_drug_info_from_image(
        image_bytes=image_bytes,
        mime_type=file.content_type,
    )
    return result


@router.post("/prospectus", response_model=ProspectusSummaryResponse)
async def summarize_prospectus_image(file: UploadFile = File(...)):
    """ProspektÃ¼s veya kutu gÃ¶rselinden kÄ±sa Ã¶zet Ã§Ä±karÄ±r."""
    _validate_image_upload(file)

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="YÃ¼klenen gÃ¶rsel boÅŸ olamaz.")

    result = await query_prospectus_summary_from_image(
        image_bytes=image_bytes,
        mime_type=file.content_type,
    )
    return result


@router.post("/interaction", response_model=DrugInteractionResponse)
async def analyze_drug_interactions(request: DrugInteractionRequest):
    """Ä°laÃ§ listesi iÃ§in olasÄ± etkileÅŸimleri Ã¶zetler."""
    normalized_drugs = [drug.strip() for drug in request.drugs if drug.strip()]
    unique_drugs = list(dict.fromkeys(normalized_drugs))

    if len(unique_drugs) < 2:
        raise HTTPException(
            status_code=400,
            detail="EtkileÅŸim analizi iÃ§in en az iki ilaÃ§ gereklidir.",
        )

    result = await query_drug_interactions(unique_drugs)
    return result


@router.post("/natural-alternatives", response_model=NaturalAlternativesResponse)
async def get_natural_alternatives(request: NaturalAlternativesRequest):
    """Ä°laÃ§la iliÅŸkili doÄŸal destek seÃ§eneklerini Ã¶zetler."""
    drug_name = request.drug_name.strip()
    if not drug_name:
        raise HTTPException(status_code=400, detail="Ä°laÃ§ adÄ± boÅŸ olamaz.")

    result = await query_natural_alternatives(drug_name)
    return result


