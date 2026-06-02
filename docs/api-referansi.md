# API Referans Kılavuzu

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**API Sürümü:** 0.1.0
**Temel URL:** `http://<host>:8000`
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Genel Bilgiler](#1-genel-bilgiler)
2. [Kimlik Doğrulama](#2-kimlik-doğrulama)
3. [Health Endpoint'leri](#3-health-endpointleri)
4. [Auth Endpoint'leri](#4-auth-endpointleri)
5. [İlaç (Drug) Endpoint'leri](#5-i̇laç-drug-endpointleri)
6. [Profil (Profile) Endpoint'leri](#6-profil-profile-endpointleri)
7. [Eczane (Pharmacy) Endpoint'leri](#7-eczane-pharmacy-endpointleri)
8. [Hata Kodları](#8-hata-kodları)

---

## 1. Genel Bilgiler

### 1.1 İstek ve Yanıt Formatı

- **İçerik türü:** `application/json` (dosya yükleme endpoint'lerinde `multipart/form-data`)
- **Karakter seti:** UTF-8
- **Sürüm yönetimi:** URL tabanlı (ilerideki sürümler `/v2/` prefixi alabilir)

### 1.2 Yetkilendirme

Korumalı endpoint'ler, `Authorization` başlığında `Bearer` token gerektirir:

```
Authorization: Bearer <JWT_TOKEN>
```

Token `POST /auth/signup` veya `POST /auth/login` ile alınır. Geçerlilik süresi **7 gündür**.

### 1.3 Rate Limiting

| Endpoint Grubu | Limit |
|---|---|
| Auth endpoint'leri | IP başına 20 istek / 60 saniye |
| İlaç arama (`/api/drug/search`) | IP başına 10 istek / 60 saniye |
| Diğer endpoint'ler | Sınırsız (sunucu kapasitesiyle sınırlı) |

Limit aşıldığında `429 Too Many Requests` döner.

### 1.4 Swagger UI

Yalnızca `DEBUG=True` modunda etkindir:
- Swagger UI: `http://<host>:8000/docs`
- ReDoc: `http://<host>:8000/redoc`

---

## 2. Kimlik Doğrulama

JWT (JSON Web Token) kullanılır. Token taşıması **Bearer** şemasıyla yapılır.

**Token yapısı:**
```json
{
  "sub": "<kullanıcı_uuid>",
  "exp": <unix_timestamp>
}
```

---

## 3. Health Endpoint'leri

### `GET /health`

Servis ve bağımlılık sağlık kontrolü.

**Yetkilendirme:** Gerekmez

**Yanıt — 200 OK (tüm servisler sağlıklı):**
```json
{
  "status": "ok",
  "service": "eczanem-api",
  "version": "0.1.0",
  "checks": {
    "redis": "ok"
  }
}
```

**Yanıt — 503 Service Unavailable (herhangi bir bağımlılık sorunlu):**
```json
{
  "status": "degraded",
  "service": "eczanem-api",
  "version": "0.1.0",
  "checks": {
    "redis": "degraded"
  }
}
```

> **Not:** Redis yalnızca `DRUG_SEARCH_REDIS_ENABLED=true` olduğunda denetlenir. Redis `degraded` olsa da uygulama bellek içi cache ile çalışmaya devam eder.

---

## 4. Auth Endpoint'leri

**Prefix:** `/auth`

### `POST /auth/signup`

Yeni kullanıcı kaydı.

**Yetkilendirme:** Gerekmez
**Rate limit:** 20 req / 60s

**İstek gövdesi:**
```json
{
  "name": "string (1–120 karakter)",
  "email": "string (3–255 karakter)",
  "password": "string (6–255 karakter)"
}
```

**Yanıt — 200 OK:**
```json
{
  "access_token": "<JWT>",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "created_at": "ISO 8601 datetime"
  }
}
```

**Hata:**
- `400` — E-posta zaten kayıtlı
- `429` — Rate limit aşıldı

---

### `POST /auth/login`

Kullanıcı girişi.

**Yetkilendirme:** Gerekmez
**Rate limit:** 20 req / 60s

**İstek gövdesi:**
```json
{
  "email": "string",
  "password": "string"
}
```

**Yanıt — 200 OK:** (signup ile aynı yapı)

**Hata:**
- `401` — Geçersiz e-posta veya şifre
- `429` — Rate limit aşıldı

---

### `GET /auth/me`

Giriş yapmış kullanıcının bilgilerini döndürür.

**Yetkilendirme:** ✅ Bearer Token

**Yanıt — 200 OK:**
```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "created_at": "ISO 8601 datetime"
}
```

**Hata:**
- `401` — Token geçersiz veya eksik

---

### `POST /auth/logout`

Çıkış yapar (istemci tarafında token silinmesi beklenir).

**Yetkilendirme:** ✅ Bearer Token

**Yanıt — 200 OK:**
```json
{ "message": "Çıkış başarılı." }
```

---

### `POST /auth/forgot-password`

Şifre sıfırlama bağlantısı gönderir.

**Yetkilendirme:** Gerekmez
**Rate limit:** 20 req / 60s

**İstek gövdesi:**
```json
{ "email": "string" }
```

**Yanıt — 200 OK:**
```json
{ "message": "Şifre sıfırlama bağlantısı gönderildi." }
```

> **Not:** Mevcut sürümde e-posta gönderimi stub'dır; FAZ 3'te gerçek e-posta sağlayıcısı bağlanacak.

---

### `PUT /auth/change-password`

Giriş yapmış kullanıcının şifresini değiştirir.

**Yetkilendirme:** ✅ Bearer Token

**İstek gövdesi:**
```json
{
  "current_password": "string (1–255 karakter)",
  "new_password": "string (6–255 karakter)"
}
```

**Yanıt — 200 OK:**
```json
{ "message": "Şifre başarıyla güncellendi." }
```

**Hata:**
- `400` — Mevcut şifre yanlış
- `401` — Token geçersiz

---

## 5. İlaç (Drug) Endpoint'leri

**Prefix:** `/api/drug`

### `POST /api/drug/search`

İlaç adıyla Gemini AI tabanlı arama.

**Yetkilendirme:** Gerekmez
**Rate limit:** 10 req / 60s (IP başına, cache hit'lerde sayılmaz)

**İstek gövdesi:**
```json
{
  "query": "string (2–200 karakter)"
}
```

**Yanıt — 200 OK:**
```json
{
  "ilac_adi": "Aspirin",
  "etken_madde": "Asetilsalisilik asit",
  "ne_icin_kullanilir": "Ağrı kesici, ateş düşürücü, kan sulandırıcı",
  "dozaj_bilgisi": "Yetişkinlerde 500 mg günde 3–4 kez",
  "kullanim_sekli": "Bol su ile yutularak alınır",
  "yan_etkiler": ["Mide bulantısı", "Mide kanaması riski"],
  "uyarilar": ["Mide ülseri olanlarda dikkat", "Çocuklarda Reye sendromu riski"],
  "kimler_kullanmamali": ["Hamile kadınlar (3. trimester)", "ASA alerjisi olanlar"],
  "alternatifler": [],
  "disclaimer": "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
}
```

---

### `POST /api/drug/analyze-image`

İlaç fotoğrafını görsel analiz eder.

**Yetkilendirme:** Gerekmez
**İstek formatı:** `multipart/form-data`

**Form parametresi:**

| Alan | Tür | Açıklama |
|---|---|---|
| `file` | `UploadFile` | JPEG/PNG görsel, maks. 10 MB |

**Yanıt — 200 OK:**
```json
{
  "ilac_adi": "Aspirin",
  "etken_madde": "Asetilsalisilik asit",
  "ne_icin_kullanilir": "...",
  "dozaj_bilgisi": "...",
  "kullanim_sekli": "...",
  "yan_etkiler": ["..."],
  "uyarilar": ["..."],
  "kimler_kullanmamali": ["..."],
  "alternatifler": [],
  "aday_ilaclar": ["Aspirin", "Coraspin"],
  "disclaimer": "..."
}
```

> `aday_ilaclar` listesi boşsa tek bir ilaç tanındı, dolu ise birden fazla eşleşme var.

**Hata:**
- `400` — Görsel dosyası değil veya boş
- `413` — Dosya 10 MB'ı aşıyor

---

### `POST /api/drug/prospectus`

Prospektüs veya kutu görselinden özet çıkarır.

**Yetkilendirme:** Gerekmez
**İstek formatı:** `multipart/form-data`

**Form parametresi:**

| Alan | Tür | Açıklama |
|---|---|---|
| `file` | `UploadFile` | JPEG/PNG görsel, maks. 10 MB |

**Yanıt — 200 OK:**
```json
{
  "ilac_adi": "Augmentin 1 g",
  "prospektus_turu": "Kullanma Talimatı",
  "ne_icin_kullanilir": "Bakteriyel enfeksiyonların tedavisi",
  "nasil_kullanilir": ["Bol su ile yutun", "Öğün öncesi veya sonrasında alınabilir"],
  "dikkat_edilmesi_gerekenler": ["Penisilin alerjisi olanlarda kontrendike"],
  "yan_etkiler": ["İshal", "Bulantı", "Döküntü"],
  "saklama_kosullari": ["25°C altında, kuru yerde saklayın"],
  "ne_zaman_doktora_basvurulmali": ["Şiddetli ishal", "Döküntü görülmesi"],
  "disclaimer": "..."
}
```

---

### `POST /api/drug/interaction`

İlaç etkileşim analizi.

**Yetkilendirme:** Gerekmez

**İstek gövdesi:**
```json
{
  "drugs": ["Warfarin", "Aspirin", "Metformin"]
}
```

> `drugs` listesi min. 2, maks. 20 eleman içerebilir.

**Yanıt — 200 OK:**
```json
{
  "genel_risk_seviyesi": "Yüksek",
  "ozet": "Warfarin ile Aspirin birlikte kullanıldığında kanama riski önemli ölçüde artmaktadır.",
  "dikkat_edilmesi_gerekenler": ["Düzenli INR takibi yapılmalıdır"],
  "etkilesimler": [
    {
      "ilaclar": ["Warfarin", "Aspirin"],
      "risk_seviyesi": "Yüksek",
      "neden": "Her iki ilaç da kanın pıhtılaşma yeteneğini azaltır",
      "oneri": "Doktor gözetiminde kullanılmalıdır"
    }
  ],
  "disclaimer": "..."
}
```

**Hata:**
- `400` — 2'den az benzersiz ilaç gönderildi

---

### `POST /api/drug/natural-alternatives`

İlacın doğal alternatiflerini listeler.

**Yetkilendirme:** Gerekmez

**İstek gövdesi:**
```json
{
  "drug_name": "İbuprofen"
}
```

**Yanıt — 200 OK:**
```json
{
  "ilac_adi": "İbuprofen",
  "hedef": "Ağrı ve iltihap giderimi",
  "alternatifler": [
    {
      "ad": "Zerdeçal",
      "tur": "Bitkisel",
      "aciklama": "Kurkumin bileşeni anti-inflamatuar etki gösterir",
      "dikkat": "Kan sulandırıcı ilaçlarla etkileşebilir"
    }
  ],
  "uyari": "Bu bilgiler ilaç tedavisinin yerini almaz."
}
```

---

### `POST /api/drug/chat`

Eczacı asistanıyla çok turlu sohbet.

**Yetkilendirme:** Gerekmez

**İstek gövdesi:**
```json
{
  "message": "Aspirin mide ülserinde kullanılabilir mi?",
  "history": [
    {
      "role": "user",
      "content": "Merhaba"
    },
    {
      "role": "model",
      "content": "Merhaba! Size nasıl yardımcı olabilirim?"
    }
  ]
}
```

> `message`: 1–2000 karakter; `history`: maks. 50 mesaj; her mesaj `role` (`user` | `model`) ve `content` (1–4000 karakter) içerir.

**Yanıt — 200 OK:**
```json
{
  "reply": "Aspirin, aktif mide ülserinde kullanılmamalıdır...",
  "disclaimer": "Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."
}
```

---

### `POST /api/drug/symptom-check`

Semptom analizi ve yönlendirme.

**Yetkilendirme:** Gerekmez

**İstek gövdesi:**
```json
{
  "description": "Sabahtan beri göğsümde ağrı ve sol kolumda uyuşma var."
}
```

> `description`: 5–2000 karakter

**Yanıt — 200 OK:**
```json
{
  "semptomlar_ozeti": "Göğüs ağrısı ve sol kol uyuşması",
  "olasilik_nedenler": ["Kardiyak kökenli ağrı", "Miyokard enfarktüsü belirtisi"],
  "acil_durum": true,
  "tavsiyeler": ["Hemen 112'yi arayın", "Hareketi kısıtlayın"],
  "doktora_ne_zaman": "Derhal — acil servise başvurun",
  "dikkat": "Bu belirtiler acil tıbbi müdahale gerektirebilir",
  "disclaimer": "Bu analiz tıbbi teşhis değildir."
}
```

> `acil_durum: true` döndüğünde mobil uygulama kırmızı uyarı banner'ı ve 112 araması yönlendirmesi gösterir.

---

## 6. Profil (Profile) Endpoint'leri

**Prefix:** `/api/profile`
**Yetkilendirme:** Tüm endpoint'ler için ✅ Bearer Token

### `GET /api/profile/family/`

Kullanıcının tüm aile üyelerini listeler.

**Yanıt — 200 OK:**
```json
[
  {
    "id": "uuid",
    "user_id": "uuid",
    "name": "Anne",
    "relationship": "Anne",
    "age": 65,
    "emoji": "👩",
    "drugs": [
      {
        "id": "uuid",
        "drug_name": "Metformin",
        "dosage": "500 mg",
        "frequency": "Günde 2",
        "notes": "Yemekle",
        "added_at": "ISO 8601 datetime"
      }
    ],
    "created_at": "ISO 8601 datetime",
    "updated_at": "ISO 8601 datetime"
  }
]
```

---

### `POST /api/profile/family/`

Yeni aile üyesi oluşturur.

**İstek gövdesi:**
```json
{
  "name": "string (1–80 karakter)",
  "relationship": "string (0–40 karakter, opsiyonel)",
  "age": "integer (0–130, opsiyonel)",
  "emoji": "string (maks. 10 karakter, varsayılan: 👤)"
}
```

**Yanıt — 201 Created:** `FamilyMemberResponse`

---

### `PUT /api/profile/family/{member_id}`

Aile üyesini günceller (yalnızca gönderilen alanlar değişir).

**Yol parametresi:** `member_id` — UUID

**İstek gövdesi:** (tüm alanlar opsiyonel)
```json
{
  "name": "string",
  "relationship": "string",
  "age": 60,
  "emoji": "👴"
}
```

**Yanıt — 200 OK:** `FamilyMemberResponse`

**Hata:**
- `404` — Üye bulunamadı veya başka kullanıcıya ait

---

### `DELETE /api/profile/family/{member_id}`

Aile üyesini ve ilişkili ilaç kayıtlarını siler.

**Yol parametresi:** `member_id` — UUID

**Yanıt — 200 OK:**
```json
{ "message": "Aile üyesi silindi." }
```

---

### `GET /api/profile/family/{member_id}/drugs/`

Bir aile üyesinin ilaç listesini döndürür.

**Yanıt — 200 OK:** `FamilyMemberDrugResponse[]`

---

### `POST /api/profile/family/{member_id}/drugs/`

Aile üyesine ilaç ekler.

**İstek gövdesi:**
```json
{
  "drug_name": "string (1–120 karakter)",
  "dosage": "string (0–80 karakter, opsiyonel)",
  "frequency": "string (0–80 karakter, opsiyonel)",
  "notes": "string (0–300 karakter, opsiyonel)"
}
```

**Yanıt — 201 Created:** `FamilyMemberDrugResponse`

---

### `DELETE /api/profile/family/{member_id}/drugs/{drug_id}`

Aile üyesinden ilaç kaydını siler.

**Yol parametreleri:** `member_id`, `drug_id` — UUID

**Yanıt — 200 OK:**
```json
{ "message": "İlaç kaydı silindi." }
```

---

## 7. Eczane (Pharmacy) Endpoint'leri

**Prefix:** `/api/pharmacy`

### `GET /api/pharmacy/nearby`

Nöbetçi eczaneleri listeler.

**Yetkilendirme:** Gerekmez

**Sorgu parametreleri:**

| Parametre | Tür | Zorunlu | Açıklama |
|---|---|---|---|
| `il` | string | Hayır | İl adı (örn: `istanbul`) |
| `ilce` | string | Hayır | İlçe adı (örn: `kadıköy`) |
| `lat` | float | Hayır | Kullanıcı enlemi (GPS ile kullanım) |
| `lon` | float | Hayır | Kullanıcı boylamı (GPS ile kullanım) |

> `lat` ve `lon` sağlandığında Nominatim ile il/ilçe otomatik tespit edilir.

**Yanıt — 200 OK:**
```json
{
  "pharmacies": [
    {
      "name": "Eczane Merkez",
      "address": "Atatürk Cad. No:1, Kadıköy",
      "phone": "0216 123 45 67",
      "district": "Kadıköy",
      "lat": 40.9833,
      "lon": 29.0833,
      "distance_km": 0.8
    }
  ],
  "count": 1,
  "api_available": true,
  "detected_il": "istanbul",
  "detected_ilce": "kadıköy",
  "fallback_to_il": false
}
```

> `fallback_to_il: true` ise ilçede nöbetçi eczane bulunamadı ve il geneline düşüldü.

---

### `GET /api/pharmacy/districts`

Bir ilin nöbet ilçelerini listeler.

**Yetkilendirme:** Gerekmez

**Sorgu parametresi:**

| Parametre | Tür | Zorunlu | Açıklama |
|---|---|---|---|
| `il` | string | Evet | İl adı (örn: `Malatya`) |

**Yanıt — 200 OK:**
```json
{
  "districts": ["Battalgazi", "Yeşilyurt", "Doğanşehir"]
}
```

---

## 8. Hata Kodları

| HTTP Kodu | Durum | Açıklama |
|---|---|---|
| `400` | Bad Request | Geçersiz istek gövdesi veya parametre |
| `401` | Unauthorized | Token eksik, geçersiz veya süresi dolmuş |
| `404` | Not Found | Kayıt bulunamadı |
| `413` | Payload Too Large | Görsel 10 MB sınırını aşıyor |
| `422` | Unprocessable Entity | Pydantic doğrulama hatası (alan eksik/yanlış tip) |
| `429` | Too Many Requests | Rate limit aşıldı |
| `500` | Internal Server Error | Beklenmeyen sunucu hatası |
| `503` | Service Unavailable | Bağımlılık servisi yanıt vermiyor |

**Hata yanıtı örneği:**
```json
{
  "detail": "Çok fazla istek gönderildi. Lütfen bir süre bekleyin."
}
```

> `422` Pydantic hatalarında `detail` bir nesne listesi içerir:
> ```json
> {
>   "detail": [
>     {
>       "loc": ["body", "query"],
>       "msg": "field required",
>       "type": "value_error.missing"
>     }
>   ]
> }
> ```
