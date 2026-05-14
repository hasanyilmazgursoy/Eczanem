"""İlaç sorgulama endpoint'leri."""

from fastapi import APIRouter, File, HTTPException, Request, UploadFile
from pydantic import BaseModel

from app.services.drug_search_guard import query_drug_info_with_guard
from app.services.gemini_service import (
    query_drug_interactions,
    query_natural_alternatives,
    query_drug_info_from_image,
    query_prospectus_summary_from_image,
    query_pharmacist_chat,
    query_symptom_analysis,
)

router = APIRouter()


class DrugSearchRequest(BaseModel):
    query: str


class DrugInteractionRequest(BaseModel):
    drugs: list[str]


class NaturalAlternativesRequest(BaseModel):
    drug_name: str


class ChatMessage(BaseModel):
    role: str  # "user" veya "model"
    content: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []


class ChatResponse(BaseModel):
    reply: str
    disclaimer: str = (
        "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
    )


class SymptomRequest(BaseModel):
    description: str


class SymptomAnalysisResponse(BaseModel):
    semptomlar_ozeti: str
    olasilik_nedenler: list[str]
    acil_durum: bool
    tavsiyeler: list[str]
    doktora_ne_zaman: str
    dikkat: str
    disclaimer: str = "Bu analiz tıbbi teşhis değildir. Kesin tanı için doktora veya eczacıya başvurun."


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
        "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
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
        "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
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
        "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
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
            detail="Yalnızca görsel dosyaları analiz edilebilir.",
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


@router.post("/analyze-image", response_model=DrugImageAnalyzeResponse)
async def analyze_drug_image(file: UploadFile = File(...)):
    """İlaç fotoğrafını Gemini ile analiz ederek muhtemel ilaç bilgisini döndürür."""
    _validate_image_upload(file)

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Yüklenen görsel boş olamaz.")

    result = await query_drug_info_from_image(
        image_bytes=image_bytes,
        mime_type=file.content_type,
    )
    return result


@router.post("/prospectus", response_model=ProspectusSummaryResponse)
async def summarize_prospectus_image(file: UploadFile = File(...)):
    """Prospektüs veya kutu görselinden kısa özet çıkarır."""
    _validate_image_upload(file)

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Yüklenen görsel boş olamaz.")

    result = await query_prospectus_summary_from_image(
        image_bytes=image_bytes,
        mime_type=file.content_type,
    )
    return result


@router.post("/interaction", response_model=DrugInteractionResponse)
async def analyze_drug_interactions(request: DrugInteractionRequest):
    """İlaç listesi için olası etkileşimleri özetler."""
    normalized_drugs = [drug.strip() for drug in request.drugs if drug.strip()]
    unique_drugs = list(dict.fromkeys(normalized_drugs))

    if len(unique_drugs) < 2:
        raise HTTPException(
            status_code=400,
            detail="Etkileşim analizi için en az iki ilaç gereklidir.",
        )

    result = await query_drug_interactions(unique_drugs)
    return result


@router.post("/natural-alternatives", response_model=NaturalAlternativesResponse)
async def get_natural_alternatives(request: NaturalAlternativesRequest):
    """İlaçla ilişkili doğal destek seçeneklerini özetler."""
    drug_name = request.drug_name.strip()
    if not drug_name:
        raise HTTPException(status_code=400, detail="İlaç adı boş olamaz.")

    result = await query_natural_alternatives(drug_name)
    return result


@router.post("/chat", response_model=ChatResponse)
async def pharmacist_chat(request: ChatRequest):
    """Eczacı asistanıyla çok turlu sohbet; geçmişi dahil ederek yanıt üretir."""
    message = request.message.strip()
    if not message:
        raise HTTPException(status_code=400, detail="Mesaj boş olamaz.")

    history = [{"role": m.role, "content": m.content} for m in request.history]
    reply = await query_pharmacist_chat(message, history)
    return ChatResponse(reply=reply)


@router.post("/symptom-check", response_model=SymptomAnalysisResponse)
async def check_symptoms(request: SymptomRequest):
    """Kullanıcının semptomlarını analiz ederek olası nedenleri ve tavsiyeleri döndürür."""
    description = request.description.strip()
    if not description:
        raise HTTPException(status_code=400, detail="Semptom açıklaması boş olamaz.")

    result = await query_symptom_analysis(description)
    return result
