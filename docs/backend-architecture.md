# Backend Mimarisi — Teknik Referans Dökümanı

**Proje:** Eczanem — Kişisel İlaç Asistanı
**Backend Stack:** FastAPI (Python 3.12)
**Versiyon:** 0.1.0
**Güncelleme Tarihi:** Haziran 2026

---

## İçindekiler

1. [Genel Bakış](#1-genel-bakış)
2. [Teknoloji Yığını ve Seçim Gerekçeleri](#2-teknoloji-yığını-ve-seçim-gerekçeleri)
3. [Klasör Yapısı](#3-klasör-yapısı)
4. [Uygulama Başlatma Akışı](#4-uygulama-başlatma-akışı)
5. [Yapılandırma Yönetimi](#5-yapılandırma-yönetimi)
6. [API Endpoint Kataloğu](#6-api-endpoint-kataloğu)
7. [Servis Katmanı Detayları](#7-servis-katmanı-detayları)
8. [Yapay Zekâ Entegrasyonu (Gemini)](#8-yapay-zekâ-entegrasyonu-gemini)
9. [Cache ve Rate Limiting Mimarisi](#9-cache-ve-rate-limiting-mimarisi)
10. [Kimlik Doğrulama ve Yetkilendirme](#10-kimlik-doğrulama-ve-yetkilendirme)
11. [Nöbetçi Eczane Servisi](#11-nöbetçi-eczane-servisi)
12. [Güvenlik Tasarımı](#12-güvenlik-tasarımı)
13. [Veri Katmanı](#13-veri-katmanı)
14. [Containerizasyon ve Dağıtım](#14-containerizasyon-ve-dağıtım)
15. [Geliştirme Ortamı Kurulumu](#15-geliştirme-ortamı-kurulumu)
16. [Bilinen Sınırlamalar ve Sonraki Adımlar](#16-bilinen-sınırlamalar-ve-sonraki-adımlar)

---

## 1. Genel Bakış

Eczanem backend'i, Flutter mobil istemcisine ilaç bilgisi, yapay zekâ analizi, kimlik doğrulama, aile profili yönetimi ve nöbetçi eczane sorgulama hizmetleri sunan bir **RESTful API sunucusudur**.

Tasarım öncelikleri şunlardır:

- **Hız:** Sık sorgulanan ilaç bilgileri Redis cache ile anlık olarak sunulur; Gemini API yalnızca cache'te bulunmayan sorgular için çağrılır.
- **Güvenlik:** Her katmanda savunmacı programlama uygulanır; production ortamında varsayılan değerlerin kullanımı kod düzeyinde engellenir.
- **Sadelik:** Geliştirme aşamasında veritabanı bağımlılığını ortadan kaldırmak için dosya tabanlı kullanıcı deposu tercih edilmiştir; PostgreSQL altyapısı ise production geçişine hazır hâlde beklemektedir.
- **Dayanıklılık:** Gemini API geçici hatalarında otomatik yeniden deneme (retry) mekanizması, Redis erişilemediğinde bellek içi fallback cache devreye girer.

```
Flutter Mobile App
       │  HTTPS / JSON
       ▼
┌──────────────────────────────────────────┐
│         FastAPI Backend (Python 3.12)     │
│                                          │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  │
│  │  Auth   │  │  Drug    │  │Profile │  │
│  │ Router  │  │  Router  │  │ Router │  │
│  └────┬────┘  └────┬─────┘  └───┬────┘  │
│       │            │            │        │
│  ┌────▼────────────▼────────────▼─────┐  │
│  │            Service Katmanı         │  │
│  │  auth_service │ gemini_service     │  │
│  │  drug_search_guard │ pharmacy_svc  │  │
│  │  profile_service                   │  │
│  └──────┬─────────────────────────────┘  │
│         │                                │
│  ┌──────▼──────────────────────────┐    │
│  │  Veri Katmanı                   │    │
│  │  Redis Cache  │  users.json     │    │
│  │  family_profiles.json           │    │
│  └─────────────────────────────────┘    │
└──────────────────────────────────────────┘
         │
         ▼
 Google Gemini 2.5 Flash API
```

---

## 2. Teknoloji Yığını ve Seçim Gerekçeleri

| Teknoloji | Versiyon | Kullanım Amacı | Seçilme Gerekçesi |
|---|---|---|---|
| **FastAPI** | 0.115.0 | HTTP API çerçevesi | Asenkron destek, otomatik OpenAPI/Swagger, Pydantic doğrulama, Python ekosistemiyle uyum |
| **Uvicorn** | 0.30.0 | ASGI sunucusu | FastAPI için referans implementasyon; production modunda birden fazla worker ile ölçeklenir |
| **Pydantic v2** | 2.9.0 | Veri doğrulama ve serileştirme | FastAPI ile sıkı entegrasyon; model validator'lar ile iş kuralı zorunluluğu (örn. JWT secret kontrolü) |
| **Pydantic Settings** | 2.5.0 | Yapılandırma yönetimi | `.env` dosyasından otomatik okuma, tip güvenli ayarlar, production güvenlik validasyonu |
| **HTTPX** | 0.27.0 | Asenkron HTTP istemci | `asyncio` ile tam uyumlu; Gemini API çağrıları için `async/await` desteği |
| **Google Gemini 2.5 Flash** | — | Yapay zekâ servisi | Multimodal (metin + görsel) destek, Türkçe çıktı kalitesi, hız/maliyet dengesi |
| **Redis** | 5.0.0 | Cache ve rate limiting | Sub-milisaniye yanıt süresi, TTL desteği, geliştirme aşamasında zorunlu değil (fallback mevcuttur) |
| **python-jose** | 3.3.0 | JWT işlemleri | HS256 ile token üretimi ve doğrulama |
| **passlib + bcrypt** | 1.7.4 / 4.0.1 | Parola hash'leme | Bcrypt adaptif maliyet faktörü ile brute-force direnci |
| **Pillow (PIL)** | 11.3.0 | Görsel ön işleme | Yeniden boyutlandırma, EXIF döndürme düzeltmesi, JPEG sıkıştırma |
| **BeautifulSoup4** | 4.12.3 | HTML ayrıştırma | eczaneler.gen.tr nöbetçi eczane verisi için scraping |
| **python-multipart** | 0.0.9 | Dosya yükleme | FastAPI görsel endpoint'leri için `UploadFile` desteği |
| **PostgreSQL + SQLAlchemy + Alembic** | — | Kalıcı veri katmanı | Hedef mimari; bağımlılıklar kurulu, aktif olarak kullanılmıyor |
| **Docker Compose** | — | Konteyner orkestrasyonu | api + db + redis servislerini tek komutla ayağa kaldırma |

---

## 3. Klasör Yapısı

```
backend/
├── Dockerfile                     # Production imajı (python:3.12-slim, non-root user)
├── requirements.txt               # Production bağımlılıkları
├── requirements-dev.txt           # Geliştirme araçları (pytest, ruff, pip-audit)
├── data/                          # Geliştirme ortamı veri deposu (prod'da PostgreSQL)
│   ├── users.json                 # Kullanıcı hesapları
│   └── family_profiles.json       # Aile profili verileri
└── app/
    ├── __init__.py
    ├── main.py                    # Uygulama fabrikası (app factory)
    ├── core/
    │   ├── __init__.py
    │   └── config.py              # Pydantic Settings — tüm yapılandırma buradan
    ├── models/                    # SQLAlchemy ORM modelleri (gelecek migrasyon için hazır)
    │   └── __init__.py
    ├── schemas/                   # Pydantic request/response şemaları (paylaşılan)
    │   └── __init__.py
    ├── routers/                   # HTTP katmanı — her router bir kaynak
    │   ├── __init__.py
    │   ├── health.py              # GET /health
    │   ├── auth.py                # /auth/* — kimlik doğrulama
    │   ├── drug.py                # /api/drug/* — ilaç sorguları
    │   ├── profile.py             # /api/profile/* — aile profili
    │   └── pharmacy.py            # /api/pharmacy/* — nöbetçi eczane
    └── services/                  # İş mantığı katmanı — router'lardan bağımsız
        ├── __init__.py
        ├── auth_service.py        # Kullanıcı yönetimi, JWT, bcrypt
        ├── gemini_service.py      # Tüm Gemini prompt'ları ve HTTP iletişimi
        ├── drug_search_guard.py   # Cache + rate limiting wrapper
        ├── pharmacy_service.py    # Web scraping + reverse geocoding
        └── profile_service.py     # Aile profili CRUD
```

**Tasarım İlkesi:** Router'lar yalnızca HTTP katmanını (istek doğrulama, yanıt şekillendirme, hata kodları) yönetir. İş mantığı servis katmanına taşınmıştır. Bu ayrım, aynı servislerin farklı router'lardan veya CLI komutlarından çağrılmasını mümkün kılar.

---

## 4. Uygulama Başlatma Akışı

`app/main.py` dosyası bir **app factory** fonksiyonu içerir:

```python
def create_app() -> FastAPI:
    settings = get_settings()          # 1. Ayarlar yüklenir (.env)
    app = FastAPI(...)                  # 2. FastAPI örneği oluşturulur
    app.add_middleware(CORSMiddleware)  # 3. CORS middleware eklenir
    app.exception_handler(Exception)   # 4. Global 500 handler tanımlanır
    app.include_router(health.router)  # 5. Router'lar bağlanır
    app.include_router(auth.router)
    ...
    return app

app = create_app()                     # Modül yüklendiğinde çalışır
```

**`get_settings()` neden `@lru_cache` kullanır?**
Pydantic Settings nesnesi `.env` dosyasını her çağrıda yeniden okur. `@lru_cache` ile bu işlem yalnızca bir kez yapılır ve aynı nesne tüm uygulama yaşam döngüsü boyunca yeniden kullanılır. Bu hem performans hem de tutarlılık sağlar.

**Global exception handler neden var?**
FastAPI işlenmeyen bir istisna ile karşılaştığında varsayılan olarak `{"detail": "Internal Server Error"}` döner. Ancak bu davranış geliştirme/production moduna göre değişebilir. Global handler, ham Python traceback'inin kullanıcıya sızmasını engeller ve her durumda tutarlı bir hata yanıtı döner.

---

## 5. Yapılandırma Yönetimi

Tüm yapılandırma `app/core/config.py` içindeki `Settings` sınıfından okunur:

```
backend/.env          →  Pydantic Settings  →  get_settings()  →  tüm servisler
```

### Kritik Ayarlar

| Ayar | Varsayılan | Açıklama |
|---|---|---|
| `GEMINI_API_KEY` | `""` | Google AI Studio API anahtarı; boşsa endpoint 500 döner |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Kullanılan model adı |
| `JWT_SECRET_KEY` | `eczanem-dev-secret-key-...` | Production'da **mutlaka** değiştirilmeli |
| `JWT_EXPIRE_MINUTES` | `10080` (7 gün) | Token geçerlilik süresi |
| `DEBUG` | `false` | `true` → Swagger UI aktif; `false` → `/docs` ve `/redoc` kapalı |
| `ALLOWED_ORIGINS` | `["*"]` | Production'da kısıtlanmalı |
| `DRUG_SEARCH_CACHE_TTL_SECONDS` | `86400` (24 saat) | İlaç arama cache süresi |
| `DRUG_SEARCH_RATE_LIMIT_MAX_REQUESTS` | `10` | Dakika başına maksimum ilaç arama isteği |
| `REDIS_HOST` / `REDIS_PORT` | `localhost` / `6379` | Redis bağlantısı |

### Production Güvenlik Doğrulaması

`Settings` sınıfı bir `model_validator` içerir:

```python
@model_validator(mode="after")
def _check_production_jwt_secret(self) -> "Settings":
    if not self.debug and self.jwt_secret_key == DEFAULT_SECRET:
        raise ValueError("Production modunda varsayılan JWT secret kullanılamaz.")
    return self
```

Bu doğrulama, production sunucusunu yanlış yapılandırılmış JWT secret ile başlatmayı **imkânsız** kılar. Uygulama başlamadan önce hata fırlatır.

---

## 6. API Endpoint Kataloğu

### Sağlık Kontrolü

| Yöntem | URL | Açıklama |
|---|---|---|
| `GET` | `/health` | Sunucu canlılık kontrolü; `{"status": "ok"}` döner |

### Kimlik Doğrulama (`/auth`)

| Yöntem | URL | Açıklama | Auth Gerekli? |
|---|---|---|---|
| `POST` | `/auth/signup` | Yeni kullanıcı kaydı | Hayır |
| `POST` | `/auth/register` | `/auth/signup` ile özdeş (plan uyumluluğu) | Hayır |
| `POST` | `/auth/login` | E-posta + şifre ile giriş; JWT döner | Hayır |
| `GET` | `/auth/me` | Oturumu açık kullanıcı bilgisi | Evet |
| `POST` | `/auth/logout` | Oturum sonlandırma (client tarafı token silme) | Evet |
| `POST` | `/auth/forgot-password` | Şifre sıfırlama başlatma (stub) | Hayır |
| `POST` | `/auth/change-password` | Şifre güncelleme | Evet |

### İlaç Sorguları (`/api/drug`)

| Yöntem | URL | Giriş | Çıkış |
|---|---|---|---|
| `POST` | `/api/drug/search` | `{"query": "aspirin"}` | Etken madde, dozaj, yan etkiler, uyarılar, doğal alternatifler |
| `POST` | `/api/drug/analyze-image` | `multipart/form-data` (görsel) | İlaç bilgisi + çoklu aday listesi |
| `POST` | `/api/drug/prospectus` | `multipart/form-data` (görsel) | Kategorize prospektüs özeti |
| `POST` | `/api/drug/interaction` | `{"drugs": ["A", "B", "C"]}` | Risk seviyesi + etkileşim detayları |
| `POST` | `/api/drug/natural-alternatives` | `{"drug_name": "parol"}` | Bitkisel/beslenme/yaşam tarzı önerileri |
| `POST` | `/api/drug/chat` | `{"message": "...", "history": [...]}` | Markdown formatında eczacı yanıtı |
| `POST` | `/api/drug/symptom-check` | `{"description": "baş ağrısı..."}` | Olası nedenler + acil durum flag'i |

### Aile Profili (`/api/profile`)

| Yöntem | URL | Açıklama |
|---|---|---|
| `GET` | `/api/profile/family/` | Tüm aile üyelerini listele |
| `POST` | `/api/profile/family/` | Yeni aile üyesi ekle |
| `PUT` | `/api/profile/family/{id}` | Aile üyesi güncelle (PATCH semantikleri) |
| `DELETE` | `/api/profile/family/{id}` | Aile üyesi ve ilaçlarını sil |
| `GET` | `/api/profile/family/{id}/drugs/` | Üyenin ilaç listesini getir |
| `POST` | `/api/profile/family/{id}/drugs/` | Üyeye ilaç ekle |
| `DELETE` | `/api/profile/family/{id}/drugs/{drug_id}` | Üyeden ilaç sil |

### Nöbetçi Eczane (`/api/pharmacy`)

| Yöntem | URL | Parametreler | Açıklama |
|---|---|---|---|
| `GET` | `/api/pharmacy/nearby` | `il`, `ilce`, `lat`, `lon` | Nöbetçi eczaneleri listele |
| `GET` | `/api/pharmacy/districts` | `il` | İlçe listesini getir |

---

## 7. Servis Katmanı Detayları

### `auth_service.py` — Kimlik Doğrulama Servisi

**Mevcut Uygulama (Geliştirme):** JSON dosya deposu (`data/users.json`)

```
Kullanıcı İsteği
      │
      ▼
create_user() veya authenticate_user()
      │
  _store_lock (RLock)  ← Thread safety; re-entrant kilit
      │
  _load_users()        ← users.json okunur
      │
  İş mantığı           ← E-posta normalize, bcrypt doğrulama
      │
  _save_users()        ← Atomik yazma
      │
      ▼
create_access_token()  ← JWT üretimi (HS256)
```

**Neden RLock (Reentrant Lock)?**
`change_password()` fonksiyonu içinde hem `_load_users()` hem de `_save_users()` çağrılır. Normal `Lock` kullanılsaydı aynı thread ikinci kez kilit almaya çalışacak ve ölümcül kilitlenme (deadlock) oluşacaktı. `RLock` aynı thread'in kilidi birden fazla kez almasına izin verir.

**TOCTOU (Time-of-Check Time-of-Use) Koruması:**
`create_user()` içinde e-posta benzersizliği kontrolü ve yeni kullanıcı ekleme işlemi aynı `_store_lock` bloğu içinde yapılır. Bu, aynı e-posta ile eş zamanlı iki kayıt isteğinin her ikisinin de başarılı olmasını engeller.

---

### `gemini_service.py` — Yapay Zekâ Servisi

Detaylar için [Bölüm 8](#8-yapay-zekâ-entegrasyonu-gemini) bakınız.

---

### `drug_search_guard.py` — Cache ve Rate Limit Kapısı

İlaç arama endpoint'inin önündeki koruma katmanıdır. Detaylar için [Bölüm 9](#9-cache-ve-rate-limiting-mimarisi) bakınız.

---

### `profile_service.py` — Aile Profili Servisi

`auth_service.py` ile aynı dosya tabanlı stratejiyi izler. Veriler `data/family_profiles.json` içinde saklanır.

```json
{
  "user_id_abc123": {
    "members": [
      {
        "id": "m_xyz",
        "name": "Anne",
        "relationship": "Anne",
        "age": 62,
        "emoji": "👩",
        "drugs": [
          {
            "id": "d_001",
            "drug_name": "Beloc",
            "dosage": "50mg",
            "frequency": "Günde 1",
            "notes": "Sabah aç karnına",
            "added_at": "2026-04-15T..."
          }
        ],
        "created_at": "...",
        "updated_at": "..."
      }
    ]
  }
}
```

---

### `pharmacy_service.py` — Nöbetçi Eczane Servisi

Detaylar için [Bölüm 11](#11-nöbetçi-eczane-servisi) bakınız.

---

## 8. Yapay Zekâ Entegrasyonu (Gemini)

### Prompt Stratejisi

Her kullanım senaryosu için ayrı bir sistem promptu tasarlanmıştır. Tüm promptlar:
- Türkçe çıktı üretecek şekilde yazılmıştır
- Yapılandırılmış JSON çıktı talep eder (sohbet promptu hariç)
- "Uydurma, bilmiyorsan belirt" kuralını içerir
- Yasal sorumluluk reddi (disclaimer) içerir

| Prompt Sabitesi | Endpoint | Giriş Tipi | `temperature` |
|---|---|---|---|
| `DRUG_SEARCH_PROMPT` | `/search` | Metin | 0.3 |
| `DRUG_IMAGE_PROMPT` | `/analyze-image` | Görsel (multimodal) | 0.2 |
| `PROSPECTUS_PROMPT` | `/prospectus` | Görsel (multimodal) | 0.2 |
| `DRUG_INTERACTION_PROMPT` | `/interaction` | Metin | 0.2 |
| `NATURAL_ALTERNATIVES_PROMPT` | `/natural-alternatives` | Metin | 0.3 |
| `PHARMACIST_CHAT_PROMPT` | `/chat` | Metin (system instruction) | 0.4 |
| `SYMPTOM_ANALYSIS_PROMPT` | `/symptom-check` | Metin | 0.3 |

**Temperature Seçim Mantığı:**
- `0.2` → Tıbbi bilgi ve görsel analiz: düşük yaratıcılık, yüksek tutarlılık zorunlu
- `0.3` → Genel bilgi ve alternatif öneriler: hafif çeşitlilik kabul edilebilir
- `0.4` → Sohbet asistanı: daha doğal, akıcı yanıtlar beklenir

### Görsel Optimizasyon Pipeline'ı

Mobil cihazlardan gelen büyük görseller hem API maliyetini artırır hem de gecikmeye yol açar. Bu nedenle görsel endpoint'lerinde backend tarafında ön işleme yapılır:

```
Ham Görsel (upload)
       │
       ▼
Pillow ile açma
       │
       ▼
ImageOps.exif_transpose()    ← EXIF döndürme bilgisini uygular
       │                         (cep telefonu fotoğrafları döndürülmüş gelebilir)
       ▼
thumbnail(1400×1400)         ← En uzun kenar 1400px'i aşmıyorsa dokunmaz,
       │                         aşıyorsa oranı koruyarak küçültür
       ▼
JPEG'e dönüştür (%82 kalite) ← PNG/WebP → JPEG; boyutu %40-70 küçültür
       │
       ▼
Base64 encode
       │
       ▼
Gemini API'ye inlineData olarak gönder
```

Optimizasyon başarısız olursa (bozuk görsel, desteklenmeyen format) orijinal görsel değiştirilmeden gönderilir; hata fırlatılmaz.

### Retry Mekanizması

Gemini API'nin geçici 5xx hatalarına karşı üssel geri çekilmeli yeniden deneme uygulanmıştır:

```
İstek gönder
    │
    ├─ HTTP 200  → Başarı, yanıtı döndür
    │
    ├─ HTTP 429  → Anında HTTPException(503) fırlat (bekleme yok)
    │               "AI servisi şu an meşgul" mesajı
    │
    ├─ HTTP 5xx, deneme 1/3  → 1 saniye bekle, tekrar dene
    │
    ├─ HTTP 5xx, deneme 2/3  → 2 saniye bekle, tekrar dene
    │
    └─ HTTP 5xx, deneme 3/3  → HTTPException(502) fırlat
                                 "AI servisi yanıt vermedi"
```

---

## 9. Cache ve Rate Limiting Mimarisi

### İki Katmanlı Cache

```
İlaç Arama İsteği
       │
       ▼
Redis'te ara (_get_cached_response_from_redis)
       │
   Bulunamazsa
       │
       ▼
Bellek içi cache'te ara (_get_cached_response)
       │
   Bulunamazsa
       │
       ▼
Rate limit kontrolü (_enforce_rate_limit)
       │
       ▼
Gemini API çağrısı (query_drug_info)
       │
       ▼
Hem Redis'e hem bellek içi cache'e yaz
       │
       ▼
Yanıtı döndür
```

**Neden iki katman?**
Redis production ortamında birden fazla sunucu instance'ı arasında ortak cache sağlar. Ancak Redis erişilemediğinde (yeniden başlatma, ağ hatası) uygulama tamamen çökmemeli ve geliştirme ortamında Redis olmadan da çalışabilmelidir. Bellek içi cache bu fallback rolünü üstlenir.

### Cache Anahtarı Üretimi

```python
"drug-search:aspirin"          # Normalize: küçük harf + boşluk tekliği
"drug-search:parol 500 mg"     # Boşluklar korunur, ön/son temizlenir
```

### Rate Limiting (Kayan Pencere Algoritması)

Her IP adresi için ayrı bir `deque` tutulur:

```
Zaman penceresi: 60 saniye
Maksimum istek: 10

IP: 192.168.1.1
deque: [t-55s, t-42s, t-31s, t-12s, t-3s]   ← 5 istek, limit geçilmedi
                                                 (pencere dışına düşenler atılır)

Yeni istek geldiğinde:
  1. Pencere dışındaki zaman damgaları deque'dan atılır
  2. Kalan sayı ≥ limite eşit mi?
     - Evet → HTTP 429 fırlat
     - Hayır → Yeni zaman damgası ekle, devam et
```

**Cache hit'ler rate limite sayılmaz.** Bu tasarım kararı kritiktir: aynı ilacı tekrar sorgulayan kullanıcı rate limit'e çarpmaz, çünkü Gemini API zaten çağrılmamaktadır.

**Bellek sızıntısı önlemi:** `_rate_limit_buckets` sözlüğü 5.000'den fazla IP girişi içerdiğinde, pencere dışına çıkmış (aktif olmayan) girişler temizlenir.

---

## 10. Kimlik Doğrulama ve Yetkilendirme

### JWT Akışı

```
POST /auth/login
  {"email": "...", "password": "..."}
          │
          ▼
   bcrypt.verify(password, hash)
          │
          ▼
   jwt.encode({"sub": user_id, "exp": now+7gün})
          │
          ▼
   {"access_token": "eyJ...", "token_type": "bearer", "user": {...}}
```

Korunan endpoint'lerde:

```
Authorization: Bearer eyJ...
          │
          ▼
   HTTPBearer → credentials.credentials
          │
          ▼
   jwt.decode(token, secret, algorithms=["HS256"])
          │
          ▼
   payload["sub"] → user_id
          │
          ▼
   Kullanıcı doğrulandı → işlem devam eder
```

### Auth Rate Limiting

Brute-force saldırılarına karşı auth endpoint'leri için ayrı rate limiting uygulanmıştır:

| Endpoint Grubu | Pencere | Limit |
|---|---|---|
| `/auth/*` | 60 saniye | 20 istek |
| `/api/drug/search` | 60 saniye | 10 istek |

---

## 11. Nöbetçi Eczane Servisi

Harici bir API kullanmak yerine `eczaneler.gen.tr` sitesinden HTML scraping yapılmaktadır.

**Neden scraping?**
Mevcut nöbetçi eczane API'leri ya ücretli ya da kısıtlı erişimlidir. `eczaneler.gen.tr`, güvenilir ve erişilebilir kaynak olduğundan scraping tercih edilmiştir.

### Konum Tespiti Akışı

```
Kullanıcı isteği
       │
   il parametresi var mı?
   ├─ Evet → Doğrudan il/ilçe slug'ı oluştur
   └─ Hayır (lat/lon var) → Nominatim reverse geocoding
                                 │
                           il ve ilçe tespiti
       │
       ▼
URL oluştur: https://www.eczaneler.gen.tr/nobetci-{il-slug}[-{ilce-slug}]
       │
       ▼
HTML çek → BeautifulSoup ile parse et
       │
   İlçe sonucu boş mu?
   ├─ Hayır → Sonuçları döndür
   └─ Evet → Il geneline düş (fallback_to_il: true)
```

**Türkçe Slug Dönüşümü:**
`ç→c`, `ğ→g`, `ı→i`, `ö→o`, `ş→s`, `ü→u` eşlemeleriyle URL slug'ı oluşturulur.
Örnek: `"Afyonkarahisar"` → `"afyonkarahisar"`, `"Çanakkale"` → `"canakkale"`

---

## 12. Güvenlik Tasarımı

### OWASP Top 10 Uyum Notları

| Tehdit | Uygulanan Önlem |
|---|---|
| **A01 Broken Access Control** | JWT doğrulaması tüm korunan route'larda; aile profili işlemlerinde `user_id` her zaman JWT'den alınır, request body'den değil |
| **A02 Cryptographic Failures** | bcrypt parola hash; JWT HS256; FlutterSecureStorage ile client token saklama |
| **A03 Injection** | Tüm girişler Pydantic ile doğrulanır; min/max length sınırları; Gemini'ye giden veriler yapılandırılmış prompt içinde interpolasyon ile gönderilir |
| **A05 Security Misconfiguration** | Production'da varsayılan JWT secret kodu engelleyen `model_validator`; `/docs` ve `/redoc` yalnızca `debug=True`'da açık |
| **A06 Vulnerable Components** | CI/CD'de `pip-audit` CVE taraması |
| **A07 Auth Failures** | Rate limiting (login brute-force); bcrypt ile zamanlama saldırısı direnci |
| **A10 SSRF** | Dış HTTP çağrıları yalnızca bilinen endpoint'lere (Gemini API, eczaneler.gen.tr, Nominatim) yapılır; kullanıcı girdisi URL olarak kullanılmaz |

### Dosya Yükleme Güvenliği

Görsel endpoint'lerinde iki aşamalı doğrulama yapılır:

```python
# 1. MIME type kontrolü (Content-Type başlığı)
if not file.content_type.startswith("image/"):
    raise HTTPException(400, "Yalnızca görsel dosyaları analiz edilebilir.")

# 2. Boyut kontrolü (okuma sonrası)
if len(data) > 10 * 1024 * 1024:  # 10 MB
    raise HTTPException(413, "Görsel boyutu 10 MB'tan büyük olamaz.")
```

MIME type başlık tabanlı olduğundan manipüle edilebilir; ancak Pillow ile yapılan görsel işleme adımı fiili format doğrulaması görevi görür — gerçek görsel değilse işlem başarısız olur.

---

## 13. Veri Katmanı

### Mevcut Durum (Geliştirme)

Geliştirme aşamasında PostgreSQL kurulumu gerektirmemek için dosya tabanlı JSON deposu kullanılmaktadır:

```
backend/data/
├── users.json           # [{id, name, email, password_hash, created_at}, ...]
└── family_profiles.json # {user_id: {members: [{id, name, drugs: [...]}]}}
```

**Neden dosya tabanlı?**
Docker olmadan geliştirirken veritabanı kurulum yükü ortadan kalkar. Prototipler hızlı denenebilir. FAZ 3 backend senkronizasyonu tamamlandığında PostgreSQL'e geçiş yapılacaktır.

### Hedef Mimari (Production)

Bağımlılıklar (`sqlalchemy`, `asyncpg`, `alembic`) zaten `requirements.txt` içindedir; yalnızca aktif edilmeyi beklemektedir.

```
Users             →  PostgreSQL users tablosu
Family Members    →  PostgreSQL family_members tablosu
Member Drugs      →  PostgreSQL family_member_drugs tablosu
Auth Tokens       →  Stateless JWT (tablo gerekmez)
Drug Cache        →  Redis (TTL ile otomatik temizlenir)
Drug Query Cache  →  Redis
```

---

## 14. Containerizasyon ve Dağıtım

### Docker Compose Servisleri

```yaml
services:
  api:      # FastAPI (python:3.12-slim, non-root appuser)
  db:       # PostgreSQL 16 Alpine
  redis:    # Redis 7 Alpine
```

**Sağlık Kontrolü Zinciri:**

```
docker compose up
       │
  redis: HEALTHCHECK ping
  db:    HEALTHCHECK pg_isready
       │
  Her iki servis "healthy" olunca
       │
  api servisi başlatılır (depends_on condition: service_healthy)
```

Bu yapı, API'nin hazır olmayan veritabanına veya Redis'e bağlanmaya çalışmasından kaynaklanan race condition'ı ortadan kaldırır.

### Dockerfile Detayları

```dockerfile
FROM python:3.12-slim
# ... bağımlılık kurulumu ...

# Güvenlik: root yerine düşük yetkili kullanıcı
RUN addgroup --system appgroup \
    && adduser --system --ingroup appgroup appuser
USER appuser

# Worker sayısı ortam değişkeniyle ayarlanabilir
ENV WORKERS=2
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers ${WORKERS}"]
```

`exec` ile uvicorn'u PID 1 olarak çalıştırmanın amacı: Docker `SIGTERM` gönderdiğinde (konteyner durdurma) sinyal doğrudan uvicorn'a ulaşır, shell wrapper'ı tarafından yutulmaz. Bu graceful shutdown sağlar.

### Geliştirme Override

`docker-compose.override.yml` dosyası geliştirme ortamında otomatik uygulanır ve `--reload` flag'ini ekler:

```bash
docker compose up          # Geliştirme (override otomatik uygulanır)
docker compose -f docker-compose.yml up   # Production (override yoksayılır)
```

---

## 15. Geliştirme Ortamı Kurulumu

### Manuel Kurulum (Docker olmadan)

```bash
# 1. Sanal ortam oluştur ve etkinleştir
python -m venv .venv
.venv\Scripts\activate          # Windows
source .venv/bin/activate       # Linux/macOS

# 2. Bağımlılıkları yükle
pip install -r backend/requirements.txt
pip install -r backend/requirements-dev.txt   # Test araçları

# 3. Ortam değişkenlerini yapılandır
# backend/.env dosyası oluştur:
GEMINI_API_KEY=your_key_here
JWT_SECRET_KEY=your_secret_here
DEBUG=True
DRUG_SEARCH_REDIS_ENABLED=False  # Redis yoksa cache'i devre dışı bırak

# 4. Sunucuyu başlat
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Docker ile Kurulum

```bash
# Geliştirme (--reload dahil)
docker compose up

# Arka planda
docker compose up -d

# Logları izle
docker compose logs -f api

# Durdur
docker compose down
```

### API Belgelerine Erişim

`DEBUG=True` ile çalışırken:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

---

## 16. Bilinen Sınırlamalar ve Sonraki Adımlar

### Mevcut Sınırlamalar

| Sınırlama | Açıklama | Planlanan Çözüm |
|---|---|---|
| **Dosya tabanlı kullanıcı deposu** | Eş zamanlı yazma kilitleme işlevsel ama yatay ölçeklenmeye uygun değil | PostgreSQL migrasyonu |
| **Stateless JWT** | Token revoke (oturum sonlandırma) mümkün değil; logout yalnızca client tarafında çalışır | Redis'te token blocklist veya refresh token mekanizması |
| **Nöbetçi eczane scraping** | Kaynak site yapısı değişirse scraper bozulabilir | CollectAPI entegrasyonu (API anahtarı ile) |
| **CORS wildcard** | `ALLOWED_ORIGINS=["*"]` production için uygun değil | `.env` ile domain kısıtlaması |
| **HTTPS** | Geliştirme ortamında HTTP; production'da TLS zorunlu | Reverse proxy (nginx) veya cloud load balancer |

### Planlanan İyileştirmeler

- [ ] PostgreSQL + SQLAlchemy async ORM ile kalıcı kullanıcı ve profil katmanı
- [ ] Alembic migration'larıyla şema versiyonlaması
- [ ] Refresh token + token blacklist mekanizması
- [ ] Yapılandırılabilir loglama (structured JSON logs)
- [ ] Sentry entegrasyonu ile hata takibi
- [ ] Production CORS sertleştirme
- [ ] Sağlık notu verilerinin backend'e senkronizasyonu
- [ ] PDF dışa aktarma endpoint'i (sağlık notu raporu)

---

*Bu döküman, projenin kaynak kodu ile birlikte güncel tutulmalıdır. Her önemli mimari değişiklikte ilgili bölüm güncellenmelidir.*
