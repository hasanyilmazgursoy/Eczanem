"""Google AI Studio (Gemini API) üzerinden ilaç bilgisi sorgulama."""

import base64
from io import BytesIO
import json

import httpx
from fastapi import HTTPException
from PIL import Image, ImageOps

from app.core.config import get_settings

DRUG_SEARCH_PROMPT = """Sen bir eczacı asistanısın. Kullanıcı sana bir ilaç adı verecek.
Aşağıdaki bilgileri Türkçe olarak SADECE JSON formatında döndür, başka hiçbir şey yazma:
{
  "ilac_adi": "İlacın ticari adı",
  "etken_madde": "Etken madde adı",
  "ne_icin_kullanilir": "Kısa açıklama",
  "dozaj_bilgisi": "Önerilen dozaj",
  "kullanim_sekli": "Aç/tok karnına, sabah/akşam vb.",
  "yan_etkiler": ["yan etki 1", "yan etki 2"],
  "uyarilar": ["uyarı 1", "uyarı 2"],
  "kimler_kullanmamali": ["grup 1", "grup 2"]
}

ÖNEMLİ: Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz.
Emin olmadığın bilgileri uydurma, "Bilgi bulunamadı" yaz."""

DRUG_IMAGE_PROMPT = """Sen bir eczacı asistanısın. Kullanıcı sana bir ilaç kutusu,
blister, şişe veya ilaç etiketi fotoğrafı verdi.

Görselde gördüğün ilacı mümkünse tespit et ve aşağıdaki alanları Türkçe olarak
SADECE JSON formatında döndür, başka hiçbir şey yazma:
{
  "ilac_adi": "İlacın ticari adı",
    "aday_ilaclar": ["Muhtemel ilaç 1", "Muhtemel ilaç 2"],
  "etken_madde": "Etken madde adı",
  "ne_icin_kullanilir": "Kısa açıklama",
  "dozaj_bilgisi": "Önerilen dozaj",
  "kullanim_sekli": "Aç/tok karnına, sabah/akşam vb.",
  "yan_etkiler": ["yan etki 1", "yan etki 2"],
  "uyarilar": ["uyarı 1", "uyarı 2"],
  "kimler_kullanmamali": ["grup 1", "grup 2"]
}

Eğer tek ilaç net görünüyorsa `aday_ilaclar` alanını boş liste bırak.
Birden fazla ilaç görünüyor ya da net emin değilsen `aday_ilaclar` içine en olası seçenekleri yaz.
Eğer ilacı net seçemiyorsan bunu alanlarda açıkça belirt ama veri uydurma.
Türkçe cevap ver.
ÖNEMLİ: Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."""

PROSPECTUS_PROMPT = """Sen bir eczacı asistanısın. Kullanıcı sana bir ilacın prospektüs,
kutu arkası veya kullanım talimatı görselini verdi.

Görselden okunabilen bilgileri kullanarak aşağıdaki alanları Türkçe ve SADECE JSON
formatında döndür. Bilgi net değilse uydurma; ilgili alana kısa ve dürüst bir açıklama yaz.

{
    "ilac_adi": "İlaç adı veya görselde okunabilen ürün adı",
    "prospektus_turu": "kutu / prospektus / etiket / bilinmiyor",
    "ne_icin_kullanilir": "Kısa özet",
    "nasil_kullanilir": ["madde 1", "madde 2"],
    "dikkat_edilmesi_gerekenler": ["uyarı 1", "uyarı 2"],
    "yan_etkiler": ["yan etki 1", "yan etki 2"],
    "saklama_kosullari": ["koşul 1", "koşul 2"],
    "ne_zaman_doktora_basvurulmali": ["durum 1", "durum 2"]
}

ÖNEMLİ: Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."""

MAX_IMAGE_DIMENSION = 1400
OPTIMIZED_IMAGE_QUALITY = 82


def _build_gemini_url() -> str:
    settings = get_settings()
    return (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent?key={settings.gemini_api_key}"
    )


def _extract_json_payload(response: httpx.Response) -> dict:
    try:
        data = response.json()
        content = data["candidates"][0]["content"]["parts"][0]["text"]
        content = content.strip()
        # Bazen markdown code block içinde gelebilir.
        if content.startswith("```"):
            content = content.split("\n", 1)[1].rsplit("```", 1)[0]
        return json.loads(content)
    except (json.JSONDecodeError, KeyError, IndexError) as exc:
        raise HTTPException(status_code=502, detail=f"Gemini yanıtı işlenemedi: {exc}")


async def _post_gemini_request(payload: dict) -> httpx.Response:
    settings = get_settings()

    if not settings.gemini_api_key:
        raise HTTPException(status_code=500, detail="Gemini API key yapılandırılmamış.")

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            _build_gemini_url(),
            headers={"Content-Type": "application/json"},
            json=payload,
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini API yanıt vermedi: {response.status_code}",
        )

    return response


async def query_drug_info(drug_name: str) -> dict:
    """Google AI Studio Gemini API üzerinden ilaç bilgisi sorgular."""
    response = await _post_gemini_request(
        {
            "contents": [
                {"parts": [{"text": f"{DRUG_SEARCH_PROMPT}\n\nİlaç adı: {drug_name}"}]}
            ],
            "generationConfig": {
                "temperature": 0.3,
                "responseMimeType": "application/json",
            },
        }
    )
    return _extract_json_payload(response)


def _optimize_image_for_gemini(image_bytes: bytes, mime_type: str) -> tuple[bytes, str]:
    """Büyük görselleri backend tarafında da küçülterek maliyeti dengeler."""
    try:
        with Image.open(BytesIO(image_bytes)) as raw_image:
            normalized_image = ImageOps.exif_transpose(raw_image)
            resized_image = normalized_image.copy()
            resized_image.thumbnail((MAX_IMAGE_DIMENSION, MAX_IMAGE_DIMENSION))

            if resized_image.mode not in ("RGB", "L"):
                resized_image = resized_image.convert("RGB")

            if resized_image.mode == "L":
                resized_image = resized_image.convert("RGB")

            output = BytesIO()
            resized_image.save(
                output,
                format="JPEG",
                quality=OPTIMIZED_IMAGE_QUALITY,
                optimize=True,
            )
            return output.getvalue(), "image/jpeg"
    except Exception:
        # Optimizasyon başarısız olursa orijinal akış bozulmasın.
        return image_bytes, mime_type


async def query_drug_info_from_image(image_bytes: bytes, mime_type: str) -> dict:
    """Gemini multimodal ile görselden ilaç bilgisi çıkarmaya çalışır."""
    image_bytes, mime_type = _optimize_image_for_gemini(image_bytes, mime_type)
    encoded_image = base64.b64encode(image_bytes).decode("utf-8")

    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {"text": DRUG_IMAGE_PROMPT},
                        {
                            "inlineData": {
                                "mimeType": mime_type,
                                "data": encoded_image,
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }
    )
    return _extract_json_payload(response)


async def query_prospectus_summary_from_image(
    image_bytes: bytes, mime_type: str
) -> dict:
    """Prospektüs veya kutu görselinden kısa kullanım özeti çıkarmaya çalışır."""
    image_bytes, mime_type = _optimize_image_for_gemini(image_bytes, mime_type)
    encoded_image = base64.b64encode(image_bytes).decode("utf-8")

    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {"text": PROSPECTUS_PROMPT},
                        {
                            "inlineData": {
                                "mimeType": mime_type,
                                "data": encoded_image,
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
        }
    )
    return _extract_json_payload(response)
