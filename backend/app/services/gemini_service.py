"""Google AI Studio (Gemini API) Ã¼zerinden ilaÃ§ bilgisi sorgulama."""

import base64
from io import BytesIO
import json

import httpx
from fastapi import HTTPException
from PIL import Image, ImageOps

from app.core.config import get_settings

DRUG_SEARCH_PROMPT = """Sen bir eczacÄ± asistanÄ±sÄ±n. KullanÄ±cÄ± sana bir ilaÃ§ adÄ± verecek.
AÅŸaÄŸÄ±daki bilgileri TÃ¼rkÃ§e olarak SADECE JSON formatÄ±nda dÃ¶ndÃ¼r, baÅŸka hiÃ§bir ÅŸey yazma:
{
  "ilac_adi": "Ä°lacÄ±n ticari adÄ±",
  "etken_madde": "Etken madde adÄ±",
  "ne_icin_kullanilir": "KÄ±sa aÃ§Ä±klama",
  "dozaj_bilgisi": "Ã–nerilen dozaj",
  "kullanim_sekli": "AÃ§/tok karnÄ±na, sabah/akÅŸam vb.",
  "yan_etkiler": ["yan etki 1", "yan etki 2"],
  "uyarilar": ["uyarÄ± 1", "uyarÄ± 2"],
  "kimler_kullanmamali": ["grup 1", "grup 2"],
  "alternatifler": [{"ad": "doğal alternatif", "tur": "Bitki/Çay/Gıda", "aciklama": "ne işe yarar", "dikkat": "kullanım uyarısı"}]
}

Ã–NEMLÄ°: Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz.
Emin olmadÄ±ÄŸÄ±n bilgileri uydurma, "Bilgi bulunamadÄ±" yaz."""

DRUG_IMAGE_PROMPT = """Sen bir eczacÄ± asistanÄ±sÄ±n. KullanÄ±cÄ± sana bir ilaÃ§ kutusu,
blister, ÅŸiÅŸe veya ilaÃ§ etiketi fotoÄŸrafÄ± verdi.

GÃ¶rselde gÃ¶rdÃ¼ÄŸÃ¼n ilacÄ± mÃ¼mkÃ¼nse tespit et ve aÅŸaÄŸÄ±daki alanlarÄ± TÃ¼rkÃ§e olarak
SADECE JSON formatÄ±nda dÃ¶ndÃ¼r, baÅŸka hiÃ§bir ÅŸey yazma:
{
  "ilac_adi": "Ä°lacÄ±n ticari adÄ±",
    "aday_ilaclar": ["Muhtemel ilaÃ§ 1", "Muhtemel ilaÃ§ 2"],
  "etken_madde": "Etken madde adÄ±",
  "ne_icin_kullanilir": "KÄ±sa aÃ§Ä±klama",
  "dozaj_bilgisi": "Ã–nerilen dozaj",
  "kullanim_sekli": "AÃ§/tok karnÄ±na, sabah/akÅŸam vb.",
  "yan_etkiler": ["yan etki 1", "yan etki 2"],
  "uyarilar": ["uyarÄ± 1", "uyarÄ± 2"],
  "kimler_kullanmamali": ["grup 1", "grup 2"],
  "alternatifler": [{"ad": "doğal alternatif", "tur": "Bitki/Çay/Gıda", "aciklama": "ne işe yarar", "dikkat": "kullanım uyarısı"}]
}

EÄŸer tek ilaÃ§ net gÃ¶rÃ¼nÃ¼yorsa `aday_ilaclar` alanÄ±nÄ± boÅŸ liste bÄ±rak.
Birden fazla ilaÃ§ gÃ¶rÃ¼nÃ¼yor ya da net emin deÄŸilsen `aday_ilaclar` iÃ§ine en olasÄ± seÃ§enekleri yaz.
EÄŸer ilacÄ± net seÃ§emiyorsan bunu alanlarda aÃ§Ä±kÃ§a belirt ama veri uydurma.
TÃ¼rkÃ§e cevap ver.
Ã–NEMLÄ°: Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz."""

PROSPECTUS_PROMPT = """Sen bir eczacÄ± asistanÄ±sÄ±n. KullanÄ±cÄ± sana bir ilacÄ±n prospektÃ¼s,
kutu arkasÄ± veya kullanÄ±m talimatÄ± gÃ¶rselini verdi.

GÃ¶rselden okunabilen bilgileri kullanarak aÅŸaÄŸÄ±daki alanlarÄ± TÃ¼rkÃ§e ve SADECE JSON
formatÄ±nda dÃ¶ndÃ¼r. Bilgi net deÄŸilse uydurma; ilgili alana kÄ±sa ve dÃ¼rÃ¼st bir aÃ§Ä±klama yaz.

{
    "ilac_adi": "Ä°laÃ§ adÄ± veya gÃ¶rselde okunabilen Ã¼rÃ¼n adÄ±",
    "prospektus_turu": "kutu / prospektus / etiket / bilinmiyor",
    "ne_icin_kullanilir": "KÄ±sa Ã¶zet",
    "nasil_kullanilir": ["madde 1", "madde 2"],
    "dikkat_edilmesi_gerekenler": ["uyarÄ± 1", "uyarÄ± 2"],
    "yan_etkiler": ["yan etki 1", "yan etki 2"],
    "saklama_kosullari": ["koÅŸul 1", "koÅŸul 2"],
    "ne_zaman_doktora_basvurulmali": ["durum 1", "durum 2"]
}

Ã–NEMLÄ°: Bu bilgiler genel bilgilendirme amaÃ§lÄ±dÄ±r. TÄ±bbi tavsiye niteliÄŸi taÅŸÄ±maz."""

DRUG_INTERACTION_PROMPT = """Sen dikkatli Ã§alÄ±ÅŸan bir eczacÄ± asistanÄ±sÄ±n.
KullanÄ±cÄ± sana birlikte kullanÄ±lmasÄ± muhtemel ilaÃ§larÄ±n listesini verecek.

SADECE aÅŸaÄŸÄ±daki JSON formatÄ±nda cevap ver:
{
    "genel_risk_seviyesi": "dusuk | orta | yuksek",
    "ozet": "KÄ±sa genel deÄŸerlendirme",
    "dikkat_edilmesi_gerekenler": ["madde 1", "madde 2"],
    "etkilesimler": [
        {
            "ilaclar": ["Ä°laÃ§ A", "Ä°laÃ§ B"],
            "risk_seviyesi": "dusuk | orta | yuksek",
            "neden": "EtkileÅŸimin nedeni veya klinik aÃ§Ä±klama",
            "oneri": "Pratik ve gÃ¼venli yaklaÅŸÄ±m"
        }
    ]
}

Kurallar:
- TÃ¼rkÃ§e cevap ver.
- Emin olmadÄ±ÄŸÄ±n bilgiyi kesinlik gibi sunma.
- Ciddi risk yoksa bile kullanÄ±cÄ±yÄ± doktor/eczacÄ± onayÄ± konusunda uyar.
- EtkileÅŸim bulunamazsa `etkilesimler` alanÄ±nÄ± boÅŸ liste dÃ¶ndÃ¼r ama yine kÄ±sa bir Ã¶zet yaz.
- TÄ±bbi tavsiye verme, gÃ¼venlik odaklÄ± ol."""

NATURAL_ALTERNATIVES_PROMPT = """Sen temkinli bir eczacÄ± asistanÄ±sÄ±n.
KullanÄ±cÄ± sana bir ilaÃ§ adÄ± verecek. Bu ilacÄ±n kullanÄ±m amacÄ±na destek olabilecek,
ilaÃ§ yerine geÃ§meyen doÄŸal veya yaÅŸam tarzÄ± temelli destek seÃ§eneklerini Ã¶zetle.

SADECE aÅŸaÄŸÄ±daki JSON formatÄ±nda cevap ver:
{
    "ilac_adi": "Ä°laÃ§ adÄ±",
    "hedef": "Ä°lacÄ±n genel kullanÄ±m amacÄ± / semptom alanÄ±",
    "alternatifler": [
        {
            "ad": "Ã–neri adÄ±",
            "tur": "bitkisel | beslenme | yaÅŸam tarzÄ± | destekleyici alÄ±ÅŸkanlÄ±k",
            "aciklama": "KÄ±sa aÃ§Ä±klama",
            "dikkat": "Kimler dikkat etmeli / ne zaman kaÃ§Ä±nmalÄ±"
        }
    ],
    "uyari": "Bu Ã¶nerilerin ilaÃ§ tedavisinin yerine geÃ§mediÄŸini belirten kÄ±sa uyarÄ±"
}

Kurallar:
- TÃ¼rkÃ§e cevap ver.
- Kesin tedavi iddiasÄ±nda bulunma.
- Riskli veya yanÄ±ltÄ±cÄ± Ã¶neri uydurma.
- Alternatif yoksa bunu dÃ¼rÃ¼stÃ§e belirt ve listeyi boÅŸ dÃ¶ndÃ¼r."""

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
        # Bazen markdown code block iÃ§inde gelebilir.
        if content.startswith("```"):
            content = content.split("\n", 1)[1].rsplit("```", 1)[0]
        return json.loads(content)
    except (json.JSONDecodeError, KeyError, IndexError) as exc:
        raise HTTPException(status_code=502, detail=f"Gemini yanÄ±tÄ± iÅŸlenemedi: {exc}")


async def _post_gemini_request(payload: dict) -> httpx.Response:
    settings = get_settings()

    if not settings.gemini_api_key:
        raise HTTPException(status_code=500, detail="Gemini API key yapÄ±landÄ±rÄ±lmamÄ±ÅŸ.")

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            _build_gemini_url(),
            headers={"Content-Type": "application/json"},
            json=payload,
        )

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Gemini API yanÄ±t vermedi: {response.status_code}",
        )

    return response


async def query_drug_info(drug_name: str) -> dict:
    """Google AI Studio Gemini API Ã¼zerinden ilaÃ§ bilgisi sorgular."""
    response = await _post_gemini_request(
        {
            "contents": [
                {"parts": [{"text": f"{DRUG_SEARCH_PROMPT}\n\nÄ°laÃ§ adÄ±: {drug_name}"}]}
            ],
            "generationConfig": {
                "temperature": 0.3,
                "responseMimeType": "application/json",
            },
        }
    )
    return _extract_json_payload(response)


def _optimize_image_for_gemini(image_bytes: bytes, mime_type: str) -> tuple[bytes, str]:
    """BÃ¼yÃ¼k gÃ¶rselleri backend tarafÄ±nda da kÃ¼Ã§Ã¼lterek maliyeti dengeler."""
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
        # Optimizasyon baÅŸarÄ±sÄ±z olursa orijinal akÄ±ÅŸ bozulmasÄ±n.
        return image_bytes, mime_type


async def query_drug_info_from_image(image_bytes: bytes, mime_type: str) -> dict:
    """Gemini multimodal ile gÃ¶rselden ilaÃ§ bilgisi Ã§Ä±karmaya Ã§alÄ±ÅŸÄ±r."""
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
    """ProspektÃ¼s veya kutu gÃ¶rselinden kÄ±sa kullanÄ±m Ã¶zeti Ã§Ä±karmaya Ã§alÄ±ÅŸÄ±r."""
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


async def query_drug_interactions(drug_names: list[str]) -> dict:
    """Birlikte kullanÄ±lan ilaÃ§lar iÃ§in olasÄ± etkileÅŸimleri Ã¶zetler."""
    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"{DRUG_INTERACTION_PROMPT}\n\n"
                                f"Ä°laÃ§ listesi: {', '.join(drug_names)}"
                            )
                        }
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


async def query_natural_alternatives(drug_name: str) -> dict:
    """Bir ilacÄ±n kullanÄ±m amacÄ±na yÃ¶nelik doÄŸal destek Ã¶nerilerini listeler."""
    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"{NATURAL_ALTERNATIVES_PROMPT}\n\n"
                                f"Ä°laÃ§ adÄ±: {drug_name}"
                            )
                        }
                    ]
                }
            ],
            "generationConfig": {
                "temperature": 0.3,
                "responseMimeType": "application/json",
            },
        }
    )
    return _extract_json_payload(response)




