"""OpenRouter API üzerinden Gemini ile ilaç bilgisi sorgulama."""

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


async def query_drug_info(drug_name: str) -> dict:
    """OpenRouter API üzerinden ilaç bilgisi sorgular."""
    settings = get_settings()

    if not settings.openrouter_api_key:
        raise HTTPException(
            status_code=500, detail="OpenRouter API key yapılandırılmamış."
        )

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.openrouter_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.openrouter_model,
                "messages": [
                    {"role": "system", "content": DRUG_SEARCH_PROMPT},
                    {"role": "user", "content": f"İlaç adı: {drug_name}"},
                ],
                "temperature": 0.3,
            },
        )

    if response.status_code != 200:
        raise HTTPException(status_code=502, detail="AI servisi yanıt vermedi.")

    try:
        content = response.json()["choices"][0]["message"]["content"]
        # JSON bloğunu çıkar (bazen markdown code block içinde gelebilir)
        content = content.strip()
        if content.startswith("```"):
            content = content.split("\n", 1)[1].rsplit("```", 1)[0]
        return json.loads(content)
    except (json.JSONDecodeError, KeyError, IndexError) as e:
        raise HTTPException(status_code=502, detail=f"AI yanıtı işlenemedi: {e}")
