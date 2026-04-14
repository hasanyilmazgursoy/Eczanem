# Eczanem

Kişisel ilaç asistanı odaklı, Flutter istemci + FastAPI backend mimarisiyle geliştirilen mobil sağlık uygulaması.

`Eczanem`; ilaç arama, fotoğraftan ilaç tanıma, prospektüs özetleme, arama/tarama geçmişi, ilaç etkileşim kontrolü, doğal alternatif önerileri ve offline çalışan ilaç hatırlatıcılarını aynı uygulamada birleştirir. Proje şu anda aktif olarak çalışan bir MVP+ seviyesindedir ve sonraki büyük adımlar aile profili, nöbetçi eczane ve acil durum modülleridir.

## Öne çıkanlar

- Yazıyla ilaç arama ve detay görüntüleme
- Kamera / galeri ile ilaç kutusu analizi
- Prospektüs görselinden özet üretme
- Arama geçmişi ve tarama geçmişi
- İlaç etkileşim kontrolü
- İlaç bazlı doğal alternatif önerileri
- JWT tabanlı kullanıcı oturumu
- Hive tabanlı yerel depolama
- Redis cache + rate limit korumaları

## Güncel durum

### Tamamlanan fazlar

- **FAZ 0** — Altyapı ve kurulum
- **FAZ 1** — Temel ilaç sorgulama / MVP
- **FAZ 2** — Kamera ile tanıma + prospektüs tarama
- **FAZ 4** — Hatırlatıcı, stok takibi ve offline bildirimler
- **Ara Faz** — Geçmiş merkezi ve profil kısayolları
- **FAZ 5** — İlaç etkileşim kontrolü + doğal alternatifler

### Devam eden / eksik alanlar

- **FAZ 3** — Aile profili (kısmen hazır, auth var ama aile yönetimi yok)
- **FAZ 6** — Nöbetçi eczane + sesli sorgu
- **FAZ 7** — Acil durum kartı + sağlık notları
- **FAZ 8** — Test, yayın ve son polish

### Teknik özet

- **Mobil:** Flutter, Riverpod, Dio, GoRouter, easy_localization, Hive
- **Backend:** FastAPI, Gemini API, JWT auth, Redis cache, dosya tabanlı kullanıcı store
- **Gerçek cihaz:** Android telefon üzerinde LAN bağlantısıyla doğrulandı
- **Doğrulama:** `flutter analyze` ve `flutter test` başarılı

## Özellik matrisi

### Çalışan modüller

- Kullanıcı kayıt / giriş / oturum akışı
- Ana sayfa ve 4 sekmeli navigasyon
- İlaç adıyla arama
- İlaç detay ekranı
- Arama geçmişi
- Kamera ve galeriden görsel seçme
- İlaç kutusu analizi ve çoklu aday akışı
- Prospektüs özeti ekranı
- Tarama geçmişi
- İlaç etkileşim analizi
- Doğal alternatif öneri ekranı
- Yerel ilaç hatırlatıcıları, stok dashboard'u ve offline bildirimler

### Yol haritasındaki sıradaki modüller

- Aile profili ve aile bireyi ilaç listeleri
- Nöbetçi eczane entegrasyonu
- Sesli ilaç sorgulama
- Acil durum kartı ve sağlık günlüğü

## Mimarinin kısa özeti

```text
Flutter Mobile App
 ├─ Auth
 ├─ Home / Navigation
 ├─ Drug Search
 ├─ Photo Scan + Prospectus Summary
 ├─ Search/Scan History
 ├─ Drug Interaction Check
 └─ Natural Alternatives

FastAPI Backend
 ├─ /health
 ├─ /api/auth/*
 ├─ /api/drug/search
 ├─ /api/drug/analyze-image
 ├─ /api/drug/prospectus
 ├─ /api/drug/interaction
 └─ /api/drug/natural-alternatives
```

## Teknoloji yığını

### Mobil

- Flutter
- Dart
- Riverpod
- Dio
- GoRouter
- easy_localization
- Hive
- SharedPreferences (yalnızca eski verileri migrate etmek için)
- Flutter Secure Storage
- Skeletonizer
- Camera
- Image Picker

### Backend

- FastAPI
- Pydantic Settings
- HTTPX
- Python-Jose
- Passlib / bcrypt
- Redis
- Gemini API
- PostgreSQL (hedef mimaride planlı, henüz aktif veri katmanı değil)

## Proje yapısı

```text
Eczanem/
├─ backend/              # FastAPI servisi
├─ mobile/               # Flutter mobil uygulaması
├─ docker-compose.yml
├─ PLAN.md               # faz bazlı yol haritası
├─ README.md
├─ CHANGELOG.md
└─ CONTRIBUTING.md
```

## Hızlı başlangıç

### 1) Backend kurulumu

`backend/.env.example` dosyasını referans alarak `backend/.env` oluşturun.

Temel değişkenler:

- `GEMINI_API_KEY`
- `JWT_SECRET_KEY`
- `API_HOST`
- `API_PORT`
- `REDIS_*`
- `POSTGRES_*`

Kurulum:

```text
python -m venv .venv
.venv\Scripts\activate
pip install -r backend/requirements.txt
```

Çalıştırma:

```text
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Sağlık kontrolü:

```text
GET http://127.0.0.1:8000/health
```

### 2) Mobil kurulumu

`mobile/.env.example` dosyasını kopyalayarak `mobile/.env` oluşturun.

Örnek:

```text
API_BASE_URL=http://10.0.2.2:8000
```

Kurulum:

```text
cd mobile
flutter pub get
```

Çalıştırma:

```text
cd mobile
flutter run
```

## Gerçek cihaz notu

Android telefonda test ederken:

- telefon ve bilgisayar aynı Wi‑Fi ağında olmalı
- backend `0.0.0.0:8000` üzerinden çalışmalı
- `mobile/.env` içindeki `API_BASE_URL`, bilgisayarın yerel IP adresi olmalı

Örnek:

```text
API_BASE_URL=http://192.168.1.139:8000
```

## Kullanılabilir API uçları

### Genel

- `GET /health`

### Auth

- `POST /api/auth/signup`
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `POST /api/auth/logout`
- `POST /api/auth/forgot-password`

### Drug

- `POST /api/drug/search`
- `POST /api/drug/analyze-image`
- `POST /api/drug/prospectus`
- `POST /api/drug/interaction`
- `POST /api/drug/natural-alternatives`

## Geliştirme komutları

### Mobil doğrulama

```text
cd mobile
flutter analyze
flutter test
```

### Backend sözdizimi kontrolü

```text
cd backend
python -m compileall app
```

## Test hesabı

Geliştirme sırasında kullanılan örnek hesap:

- **E-posta:** `hasan.test@example.com`
- **Şifre:** `123456`

## Bilinen sınırlamalar

- Aile profili modülü henüz tamamlanmadı
- Nöbetçi eczane entegrasyonu henüz yok
- Release APK üretilebilir; ancak mağaza yayını için Android imzalama anahtarı (keystore) henüz tanımlı değil
- Backend auth katmanı şu an dosya tabanlı kullanıcı store kullanıyor (`backend/data/users.json`)
- PostgreSQL hedef mimaride planlı olsa da aktif kalıcı veri katmanı olarak henüz devrede değil

## Yol haritası

Detaylı ürün planı için:

- `PLAN.md`

## Katkı

Katkı süreci, commit standartları ve PR beklentileri için:

- `CONTRIBUTING.md`

## Lisans

Bu repo için henüz açık bir lisans dosyası eklenmemiştir. Yayın öncesinde uygun lisansın ayrıca belirlenmesi önerilir.
