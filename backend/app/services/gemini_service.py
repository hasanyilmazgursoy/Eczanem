"""Google AI Studio (Gemini API) üzerinden ilaç bilgisi sorgulama."""

import base64
import json
from io import BytesIO

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
  "kimler_kullanmamali": ["grup 1", "grup 2"],
  "alternatifler": [{"ad": "doğal alternatif", "tur": "Bitki/Çay/Gıda", "aciklama": "ne işe yarar", "dikkat": "kullanım uyarısı"}]
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
  "kimler_kullanmamali": ["grup 1", "grup 2"],
  "alternatifler": [{"ad": "doğal alternatif", "tur": "Bitki/Çay/Gıda", "aciklama": "ne işe yarar", "dikkat": "kullanım uyarısı"}]
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

DRUG_INTERACTION_PROMPT = """Sen dikkatli çalışan bir eczacı asistanısın.
Kullanıcı sana birlikte kullanılması muhtemel ilaçların listesini verecek.

SADECE aşağıdaki JSON formatında cevap ver:
{
    "genel_risk_seviyesi": "dusuk | orta | yuksek",
    "ozet": "Kısa genel değerlendirme",
    "dikkat_edilmesi_gerekenler": ["madde 1", "madde 2"],
    "etkilesimler": [
        {
            "ilaclar": ["İlaç A", "İlaç B"],
            "risk_seviyesi": "dusuk | orta | yuksek",
            "neden": "Etkileşimin nedeni veya klinik açıklama",
            "oneri": "Pratik ve güvenli yaklaşım"
        }
    ]
}

Kurallar:
- Türkçe cevap ver.
- Emin olmadığın bilgiyi kesinlik gibi sunma.
- Ciddi risk yoksa bile kullanıcıyı doktor/eczacı onayı konusunda uyar.
- Etkileşim bulunamazsa `etkilesimler` alanını boş liste döndür ama yine kısa bir özet yaz.
- Tıbbi tavsiye verme, güvenlik odaklı ol."""

NATURAL_ALTERNATIVES_PROMPT = """Sen temkinli bir eczacı asistanısın.
Kullanıcı sana bir ilaç adı verecek. Bu ilacın kullanım amacına destek olabilecek,
ilaç yerine geçmeyen doğal veya yaşam tarzı temelli destek seçeneklerini özetle.

SADECE aşağıdaki JSON formatında cevap ver:
{
    "ilac_adi": "İlaç adı",
    "hedef": "İlacın genel kullanım amacı / semptom alanı",
    "alternatifler": [
        {
            "ad": "Öneri adı",
            "tur": "bitkisel | beslenme | yaşam tarzı | destekleyici alışkanlık",
            "aciklama": "Kısa açıklama",
            "dikkat": "Kimler dikkat etmeli / ne zaman kaçınmalı"
        }
    ],
    "uyari": "Bu önerilerin ilaç tedavisinin yerine geçmediğini belirten kısa uyarı"
}

Kurallar:
- Türkçe cevap ver.
- Kesin tedavi iddiasında bulunma.
- Riskli veya yanıltıcı öneri uydurma.
- Alternatif yoksa bunu dürüstçe belirt ve listeyi boş döndür."""

PHARMACIST_CHAT_PROMPT = """Sen Eczanem uygulamasının yapay zeka destekli eczacı asistanısın.
Kullanıcıların ilaçlar, semptomlar, yan etkiler, dozaj, ilaç etkileşimleri
ve genel sağlık soruları hakkındaki sorularını yanıtlarsın.

Kurallar:
- Her zaman Türkçe yanıt ver.
- Kullanıcıya saygılı ve empatik ol.
- Kesin tıbbi teşhis koyma; gerektiğinde doktor veya eczacıya yönlendir.
- Yanıtlarını açık ve anlaşılır tut; gereksiz tekrar yapma.
- Konuşma geçmişini dikkate al; tutarlı ol.
- Tehlikeli veya acil durumlarda kullanıcıyı 112 Acil Servis'e yönlendir.
- Yanıt sonuna disclaimer ekleme; uygulama zaten gösteriyor."""

SYMPTOM_ANALYSIS_PROMPT = """Sen Eczanem uygulamasının yapay zeka destekli eczacı asistanısın.
Kullanıcı sana yaşadığı semptomları anlatacak. Bu semptomları değerlendir ve aşağıdaki
bilgileri SADECE JSON formatında döndür, başka hiçbir şey yazma:
{
    "semptomlar_ozeti": "Kullanıcının belirttiği semptomların kısa özeti",
    "olasilik_nedenler": ["Olası neden 1", "Olası neden 2", "Olası neden 3"],
    "acil_durum": false,
    "tavsiyeler": ["Tavsiye 1", "Tavsiye 2"],
    "doktora_ne_zaman": "Doktora ne zaman başvurulması gerektiğini açıkla",
    "dikkat": "Bu analiz tıbbi teşhis değildir uyarısı"
}

Kurallar:
- Türkçe yanıt ver.
- `acil_durum` alanını yalnızca gerçekten acil olan durumlarda (göğüs ağrısı, nefes darlığı vb.) true yap.
- Kesin ilaç adı önerme; genel tavsiyeyle sınırlı kal.
- Uydurma; emin olmadığın durumları "belirsiz" veya "doktora danışın" şeklinde yaz."""

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


def _extract_text_payload(response: httpx.Response) -> str:
    """Gemini yanıtından düz metin çıkarır (JSON değil)."""
    try:
        data = response.json()
        return data["candidates"][0]["content"]["parts"][0]["text"].strip()
    except (KeyError, IndexError) as exc:
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

    if response.status_code == 429:
        raise HTTPException(
            status_code=503,
            detail="AI servisi şu an meşgul, lütfen biraz bekleyip tekrar deneyin.",
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


async def query_drug_interactions(drug_names: list[str]) -> dict:
    """Birlikte kullanılan ilaçlar için olası etkileşimleri özetler."""
    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"{DRUG_INTERACTION_PROMPT}\n\n"
                                f"İlaç listesi: {', '.join(drug_names)}"
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
    """Bir ilacın kullanım amacına yönelik doğal destek önerilerini listeler."""
    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"{NATURAL_ALTERNATIVES_PROMPT}\n\n"
                                f"İlaç adı: {drug_name}"
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


async def query_pharmacist_chat(message: str, history: list[dict]) -> str:
    """Eczacı asistanıyla çok turlu sohbet — geçmişi dahil ederek yanıt üretir."""
    # Önceki turları Gemini'nin beklediği contents formatına dönüştür.
    contents = [
        {
            "role": turn["role"],
            "parts": [{"text": turn["content"]}],
        }
        for turn in history
    ]
    # Yeni kullanıcı mesajını ekle.
    contents.append({"role": "user", "parts": [{"text": message}]})

    response = await _post_gemini_request(
        {
            "system_instruction": {
                "parts": [{"text": PHARMACIST_CHAT_PROMPT}],
            },
            "contents": contents,
            "generationConfig": {
                "temperature": 0.4,
            },
        }
    )
    return _extract_text_payload(response)


async def query_symptom_analysis(description: str) -> dict:
    """Semptom açıklamasını analiz ederek olası nedenler ve tavsiyeler sunar."""
    response = await _post_gemini_request(
        {
            "contents": [
                {
                    "parts": [
                        {
                            "text": (
                                f"{SYMPTOM_ANALYSIS_PROMPT}\n\n"
                                f"Semptomlar: {description}"
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
