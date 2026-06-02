# Kurulum Rehberi

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Sürüm:** 1.2.0
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Ön Gereksinimler](#1-ön-gereksinimler)
2. [Depoyu Klonlama](#2-depoyu-klonlama)
3. [Backend Kurulumu (Docker)](#3-backend-kurulumu-docker)
4. [Backend Kurulumu (Manuel — Docker'sız)](#4-backend-kurulumu-manuel--dockersız)
5. [Mobil Uygulama Kurulumu (Flutter)](#5-mobil-uygulama-kurulumu-flutter)
6. [Ortam Değişkenleri Referansı](#6-ortam-değişkenleri-referansı)
7. [Sık Karşılaşılan Sorunlar](#7-sık-karşılaşılan-sorunlar)

---

## 1. Ön Gereksinimler

### 1.1 Backend için

| Araç | Minimum Sürüm | Açıklama |
|---|---|---|
| Docker Desktop | 24.x | Backend, PostgreSQL ve Redis container'larını çalıştırır |
| Docker Compose | 2.x | `docker-compose.yml` ile servisler yönetilir |
| Git | 2.x | Depoyu klonlamak için |

**veya manuel kurulum:**

| Araç | Minimum Sürüm |
|---|---|
| Python | 3.12 |
| pip | 23.x |
| PostgreSQL | 15+ |
| Redis | 7+ |

### 1.2 Mobil uygulama için

| Araç | Minimum Sürüm | Açıklama |
|---|---|---|
| Flutter SDK | 3.x | `flutter.dev/docs/get-started/install` |
| Dart | ≥ 3.5.0 | Flutter ile birlikte gelir |
| Android Studio | 2023.x | Android emülatörü veya cihaz bağlantısı |
| Xcode | 15+ | iOS/macOS build için (yalnızca macOS) |

### 1.3 Harici Servis Gereksinimleri

| Servis | Neden | Nereden Alınır |
|---|---|---|
| **Gemini API Key** | Tüm AI özellikler için zorunlu | [aistudio.google.com](https://aistudio.google.com) |
| **CollectAPI Key** | Nöbetçi eczane (opsiyonel, scraping de çalışır) | [collectapi.com](https://collectapi.com) |

---

## 2. Depoyu Klonlama

```bash
git clone <repo-url> eczanem
cd eczanem
```

Proje iki ana klasörden oluşur:

```
eczanem/
├── backend/    # FastAPI + Python
└── mobile/     # Flutter
```

---

## 3. Backend Kurulumu (Docker)

### 3.1 `.env` Dosyasını Oluşturma

```bash
cd backend
cp .env.example .env
```

`.env` dosyasını aşağıdaki zorunlu değerlerle doldurun:

```env
# Zorunlu — Google AI Studio'dan alın
GEMINI_API_KEY=AIzaSy...

# Zorunlu production'da — openssl rand -hex 32 ile üretin
JWT_SECRET_KEY=buraya-guclu-bir-jwt-secret-gelecek

# Geliştirme için DEBUG=True bırakın (Swagger UI aktif olur)
DEBUG=True
```

> **Güvenlik notu:** Production ortamında `JWT_SECRET_KEY` varsayılan değeri kullanıldığında uygulama başlatılmayı reddeder. Güçlü bir secret üretin:
> ```bash
> openssl rand -hex 32
> ```

### 3.2 Geliştirme Ortamı Başlatma

`docker-compose.override.yml` dosyası otomatik olarak uygulanır; `--reload` ve kod bağlama (volume mount) aktif olur.

```bash
# Proje kök dizininden çalıştırın
docker-compose up --build
```

**Servisler başladıktan sonra:**
- API: [http://localhost:8000](http://localhost:8000)
- Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs) (yalnızca `DEBUG=True`)
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379`

### 3.3 Servis Durumunu Doğrulama

```bash
curl http://localhost:8000/health
# {"status":"ok","service":"eczanem-api","version":"0.1.0","checks":{"redis":"ok"}}
```

### 3.4 Production Build

Production için `override.yml` dosyasını devre dışı bırakın:

```bash
docker-compose -f docker-compose.yml up -d --build
```

Production'da `.env` dosyasında:
- `DEBUG=False` (veya `DEBUG=release`)
- `JWT_SECRET_KEY` varsayılan değerin dışında
- `ALLOWED_ORIGINS` gerçek domain adreslerinizi içermeli

### 3.5 Servisleri Durdurma

```bash
docker-compose down          # Servisler durur, veriler korunur
docker-compose down -v       # Servisler durur + PostgreSQL/Redis verileri silinir
```

---

## 4. Backend Kurulumu (Manuel — Docker'sız)

### 4.1 Python Sanal Ortamı

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS / Linux
source .venv/bin/activate
```

### 4.2 Bağımlılıkları Yükleme

```bash
pip install -r requirements.txt
```

**Geliştirme bağımlılıkları için:**

```bash
pip install -r requirements-dev.txt
```

### 4.3 PostgreSQL ve Redis

Yerel PostgreSQL ve Redis servislerinin çalıştığını doğrulayın. `.env` dosyasındaki bağlantı değerlerini yerel konfigürasyonunuza göre güncelleyin:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
REDIS_HOST=localhost
REDIS_PORT=6379
```

### 4.4 Uygulamayı Başlatma

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

---

## 5. Mobil Uygulama Kurulumu (Flutter)

### 5.1 Flutter Bağımlılıklarını Yükleme

```bash
cd mobile
flutter pub get
```

### 5.2 `.env` Dosyasını Oluşturma

```bash
cp .env.example .env  # Proje kök .env.example yoksa aşağıdaki içeriği oluşturun
```

`mobile/.env` dosyası:

```env
# Backend API adresi
# Android Emülatör:  http://10.0.2.2:8000
# iOS Simulator:     http://localhost:8000
# Gerçek Cihaz:      http://<bilgisayar-yerel-ip>:8000
# Production:        https://api.eczanem.app
API_BASE_URL=http://10.0.2.2:8000
```

### 5.3 Çevirileri Kontrol Etme

```bash
# TR ve EN çeviri dosyalarının varlığını doğrulayın
ls mobile/assets/translations/
# tr.json  en.json
```

### 5.4 Uygulamayı Çalıştırma

**Android emülatörde veya cihazda:**

```bash
flutter run
```

**Belirli bir cihazda:**

```bash
flutter devices          # Bağlı cihazları listele
flutter run -d <device-id>
```

**Profil/Release mode:**

```bash
flutter run --release
```

### 5.5 APK / IPA Build

**Android APK (debug):**

```bash
flutter build apk --debug
# Çıktı: build/app/outputs/flutter-apk/app-debug.apk
```

**Android APK (release):**

```bash
flutter build apk --release
```

**iOS (yalnızca macOS):**

```bash
flutter build ios --release
```

### 5.6 Testleri Çalıştırma

```bash
# Tüm birim testleri
flutter test

# Belirli test dosyası
flutter test test/medication_reminder_repository_test.dart

# Test kapsamı raporu
flutter test --coverage
```

---

## 6. Ortam Değişkenleri Referansı

### 6.1 Backend (`.env`)

| Değişken | Varsayılan | Açıklama |
|---|---|---|
| `GEMINI_API_KEY` | _(boş)_ | Google AI Studio API anahtarı. **Zorunlu.** |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Kullanılacak Gemini model adı |
| `JWT_SECRET_KEY` | _(dev fallback)_ | JWT imzalama anahtarı. Production'da **zorunlu** güçlü değer |
| `JWT_ALGORITHM` | `HS256` | JWT algoritması |
| `JWT_EXPIRE_MINUTES` | `10080` (7 gün) | Token geçerlilik süresi (dakika) |
| `DEBUG` | `False` | `True` iken `/docs`, `/redoc` aktif ve `--reload` devrede |
| `ALLOWED_ORIGINS` | `*` | CORS izin listesi. Production'da alan adlarınızı girin |
| `DRUG_SEARCH_CACHE_TTL_SECONDS` | `86400` | İlaç arama cache süresi (saniye) |
| `DRUG_SEARCH_RATE_LIMIT_WINDOW_SECONDS` | `60` | Rate limit pencere boyutu (saniye) |
| `DRUG_SEARCH_RATE_LIMIT_MAX_REQUESTS` | `10` | Pencere başına maks. istek |
| `DRUG_SEARCH_REDIS_ENABLED` | `True` | Redis cache katmanını etkinleştirir |
| `POSTGRES_HOST` | `localhost` | Docker'da `db` |
| `POSTGRES_PORT` | `5432` | |
| `POSTGRES_DB` | `eczanem` | |
| `POSTGRES_USER` | `eczanem_user` | |
| `POSTGRES_PASSWORD` | `eczanem_pass_123` | Production'da güçlü şifre seçin |
| `REDIS_HOST` | `localhost` | Docker'da `redis` |
| `REDIS_PORT` | `6379` | |
| `REDIS_DB` | `0` | |
| `API_HOST` | `0.0.0.0` | API dinleme adresi |
| `API_PORT` | `8000` | API port numarası |
| `COLLECT_API_KEY` | _(boş)_ | CollectAPI nöbetçi eczane anahtarı (opsiyonel) |

### 6.2 Mobil Uygulama (`.env`)

| Değişken | Açıklama |
|---|---|
| `API_BASE_URL` | Backend API base URL. Android emülatörde `http://10.0.2.2:8000` |

---

## 7. Sık Karşılaşılan Sorunlar

### 7.1 Backend — `ValueError: Production modunda JWT_SECRET_KEY...`

**Neden:** `DEBUG=False` iken varsayılan JWT secret kullanılıyor.
**Çözüm:** `.env` dosyasına güçlü bir secret ekleyin:
```bash
openssl rand -hex 32
# Çıktıyı JWT_SECRET_KEY= satırına yapıştırın
```

---

### 7.2 Backend — Redis bağlanamıyor

**Belirti:** `GET /health` isteğinde `"redis": "degraded"`
**Açıklama:** Redis yalnızca önbellek katmanıdır; servis çalışmaya devam eder.
**Çözüm:** Redis container'ının çalışıp çalışmadığını doğrulayın:
```bash
docker-compose ps
docker-compose logs redis
```

---

### 7.3 Flutter — `Could not find package 'eczanem'`

**Çözüm:**
```bash
flutter pub get
flutter clean
flutter pub get
```

---

### 7.4 Flutter — Android emülatörde API'ye bağlanamıyor

**Neden:** `localhost` Android emülatörde ana makineye ulaşmaz.
**Çözüm:** `.env` dosyasında `API_BASE_URL=http://10.0.2.2:8000` kullanın.

---

### 7.5 Flutter — Bildirim izni alınamıyor (Android 13+)

**Açıklama:** Android 13+ sürümlerde `POST_NOTIFICATIONS` izni runtime'da istenir.
**Çözüm:** Uygulama ilk bildirim oluştururken izin dialogu otomatik gösterilir. `permission_handler` paketi bu akışı yönetir.

---

### 7.6 Docker — Port çakışması

**Belirti:** `Bind for 0.0.0.0:8000 failed: port is already allocated`
**Çözüm:** `docker-compose.yml` dosyasında port eşlemesini değiştirin:
```yaml
ports:
  - "8001:8000"   # 8000 kullanımdaysa 8001 kullanın
```

---

### 7.7 Flutter — `flutter_local_notifications` iOS kurulumu

iOS için `AppDelegate.swift` dosyasına bildirim ayarlarının eklenmesi gerekir. Mevcut `ios/Runner/AppDelegate.swift` dosyası bu yapılandırmayı içermektedir.
