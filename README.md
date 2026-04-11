# Eczanem

Kişisel ilaç asistanı odaklı bir mobil sağlık uygulaması.

`Eczanem`, Flutter ile geliştirilen mobil istemci ve FastAPI ile geliştirilen backend servisinden oluşur. Uygulama; ilaç arama, ilaç detaylarını görüntüleme, kullanıcı oturumu, gerçek cihazda çalışma ve FAZ 1 kapsamındaki temel UX akışlarını şu anda aktif olarak desteklemektedir.

## Mevcut durum

- **Aktif faz:** FAZ 1 — Temel İlaç Sorgulama / MVP
- **Mobil:** Flutter + Riverpod + Dio + GoRouter
- **Backend:** FastAPI + Gemini entegrasyonu + JWT tabanlı auth
- **Gerçek cihaz desteği:** Android telefonda doğrulandı
- **Arama korumaları:** 24 saat Redis cache + bellek içi fallback + IP bazlı rate limit

## Özellikler

### Tamamlananlar

- Kullanıcı kayıt / giriş akışı
- Oturumun güvenli saklanması
- Ana sayfa + alt navigasyon
- İlaç adıyla arama
- İlaç detay ekranı
- Son aramalar
- Arama debounce
- Skeleton loading
- Daha anlamlı boş / hata / tekrar dene durumları
- Gerçek cihazda backend’e LAN üzerinden bağlanma

### Planlananlar

- Görselle ilaç tanıma
- Prospektüs özetleme
- Aile profili yönetimi
- Hatırlatıcı ve stok takibi
- İlaç etkileşim kontrolü
- Nöbetçi eczane entegrasyonu

## Teknoloji yığını

### Mobil

- Flutter
- Dart
- Riverpod
- Dio
- GoRouter
- Easy Localization
- SharedPreferences
- Flutter Secure Storage
- Skeletonizer

### Backend

- FastAPI
- Pydantic Settings
- HTTPX
- Python-Jose
- Passlib / bcrypt
- PostgreSQL (planlandı)
- Redis (ilaç arama cache katmanında etkin)

## Proje yapısı

```text
Eczanem/
├─ backend/        # FastAPI servisi
├─ mobile/         # Flutter mobil uygulaması
├─ docker-compose.yml
├─ PLAN.md         # ürün ve faz yol haritası
├─ README.md
└─ CHANGELOG.md
```

## Hızlı başlangıç

### 1) Backend kurulumu

`backend/.env.example` dosyasını referans alarak `backend/.env` oluşturun.

Gerekli alanlar:

- `GEMINI_API_KEY`
- `JWT_SECRET_KEY`
- API / DB / Redis ayarları

Sanal ortam ve bağımlılık kurulumu:

```text
python -m venv .venv
.venv\Scripts\activate
pip install -r backend/requirements.txt
```

Backend’i çalıştırma:

```text
cd backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Sağlık kontrolü:

```text
GET http://127.0.0.1:8000/health
```

### 2) Mobil kurulumu

```text
cd mobile
flutter pub get
```

`mobile/.env` içinde backend adresini tanımlayın.

Emülatör için örnek:

```text
API_BASE_URL=http://10.0.2.2:8000
```

Gerçek cihaz için örnek:

```text
API_BASE_URL=http://192.168.1.139:8000
```

Ardından uygulamayı başlatın:

```text
cd mobile
flutter run
```

## Gerçek cihaz notu

Android telefonda test ederken:

- Telefon ve bilgisayar aynı Wi‑Fi ağında olmalı
- Backend `0.0.0.0:8000` üzerinden çalışmalı
- `mobile/.env` içindeki `API_BASE_URL`, bilgisayarın yerel IP adresi olmalı

## Docker Compose

Depoda `docker-compose.yml` mevcuttur:

- `api`
- `db`
- `redis`

Not: Compose altyapısı mevcut olsa da geliştirmenin ana akışı şu an yerel Python/Flutter çalıştırması üzerinden ilerlemektedir.

## Geliştirme komutları

### Mobil analiz

```text
cd mobile
flutter analyze
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

## Yol haritası

Detaylı ürün planı için:

- `PLAN.md`

## Katkı

Katkı süreci, commit standartları ve PR beklentileri için:

- `CONTRIBUTING.md`

## Lisans

Bu repo için henüz açık bir lisans dosyası eklenmemiştir. Yayın öncesinde uygun lisansın ayrıca belirlenmesi önerilir.
