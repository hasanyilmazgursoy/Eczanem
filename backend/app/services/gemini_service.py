"""Google AI Studio (Gemini API) üzerinden ilaç bilgisi sorgulama."""

import base64
import json

import httpx
from fastapi import HTTPException

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
  "etken_madde": "Etken madde adı",
  "ne_icin_kullanilir": "Kısa açıklama",
  "dozaj_bilgisi": "Önerilen dozaj",
  "kullanim_sekli": "Aç/tok karnına, sabah/akşam vb.",
  "yan_etkiler": ["yan etki 1", "yan etki 2"],
  "uyarilar": ["uyarı 1", "uyarı 2"],
  "kimler_kullanmamali": ["grup 1", "grup 2"]
}

Eğer ilacı net seçemiyorsan bunu alanlarda açıkça belirt ama veri uydurma.
ÖNEMLİ: Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."""


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


async def query_drug_info_from_image(image_bytes: bytes, mime_type: str) -> dict:
    """Gemini multimodal ile görselden ilaç bilgisi çıkarmaya çalışır."""
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
