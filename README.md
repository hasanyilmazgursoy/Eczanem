# Eczanem

Kişisel ilaç asistanı odaklı, Flutter istemci + FastAPI backend mimarisiyle geliştirilen mobil sağlık uygulaması.

`Eczanem`; ilaç arama, fotoğraftan ilaç tanıma, prospektüs özetleme, arama/tarama geçmişi, ilaç etkileşim kontrolü, doğal alternatif önerileri, offline çalışan ilaç hatırlatıcıları, aile profili, nöbetçi eczane, acil durum kartı ve sağlık notlarını aynı uygulamada birleştirir. Proje şu anda çalışan bir MVP+ seviyesini geçmiş durumda; mevcut odak FAZ 8 polish, test ve yayın hazırlığıdır.

## Öne çıkanlar

- Yazıyla ilaç arama ve detay görüntüleme
- Kamera / galeri ile ilaç kutusu analizi
- Prospektüs görselinden özet üretme
- Arama geçmişi ve tarama geçmişi
- İlaç etkileşim kontrolü
- İlaç bazlı doğal alternatif önerileri
- AI eczacı sohbet asistanı (Gemini tabanlı, markdown yanıtlar)
- Offline ilaç hatırlatıcıları ve stok takibi
- Nöbetçi eczane — il/ilçe dropdown seçimi, OSM harita, konum desteği
- Acil durum kartı + QR kod ile hızlı paylaşım
- Sağlık notları ve klinik ölçüm takibi (tansiyon / şeker / ağrı seviyesi)
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
- **FAZ 6** — Nöbetçi eczane (liste + OSM harita) + sesli sorgu
- **FAZ 7** — Acil durum kartı + QR paylaşım + sağlık notları

### Devam eden / eksik alanlar

- **FAZ 3** — Aile profili ekranları ve yerel veri akışı hazır; backend senkronizasyonu ve son polish eksik
- **FAZ 6** — Tamamlandı: nöbetçi eczane listesi, OSM tabanlı harita görünümü ve sesli sorgu özelliği hazır
- **FAZ 7** — Tamamlandı: acil durum kartı, QR kod paylaşımı ve sağlık notları modülü hazır; PDF dışa aktarma gelecek iterasyona ertelendi
- **FAZ 8** — Test, yayın ve son polish aktif odak alanı

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
- Aile profili, aile bireyi detayları ve birey bazlı ilaç listeleri
- Nöbetçi eczane ekranı — il/ilçe dropdown seçimi (81 il statik + dinamik ilçe listesi)
- Nöbetçi eczane OSM tabanlı harita görünümü (flutter_map, kullanıcı konumu, pin'ler)
- Nöbetçi eczane ilçe fallback: ilçede nöbet yoksa il geneline düşme + bildirim banner'ı
- AI eczacı sohbet ekranı (Gemini tabanlı, markdown+emoji formatıyla yapılandırılmış yanıtlar)
- Acil durum kartı oluşturma / düzenleme
- Acil durum kartı QR kod ile paylaşma
- Sağlık notları ekleme, filtreleme ve düzenleme
- Sağlık notu klinik ölçümleri: tansiyon, kan şekeri, ağrı seviyesi (kategoriye göre koşullu)
- Onboarding: ilk açılış sonrası tekrar gösterilmez, doğrudan login

### Yol haritasındaki sıradaki odaklar

- FAZ 8 polish: empty state, error state ve dark mode tutarlılığı
- Mobil ve backend test kapsamını genişletme
- Release checklist, mağaza hazırlığı ve deploy planı
- Sonraki faz için büyük işler: veritabanı migration, backend senkronizasyonu, PDF dışa aktarma, CORS sertleştirme

## Mimarinin kısa özeti

```text
Flutter Mobile App
 ├─ Auth
 ├─ Home / Navigation
 ├─ Drug Search
 ├─ Photo Scan + Prospectus Summary
 ├─ Search/Scan History
 ├─ Drug Interaction Check
 ├─ Natural Alternatives
 ├─ AI Pharmacist Chat
 ├─ Reminders & Stock
 ├─ Family Profile
 ├─ Pharmacy (il/ilçe dropdown + OSM map)
 ├─ Emergency Card + QR
 └─ Health Notes

FastAPI Backend
 ├─ /health
 ├─ /api/auth/*
 ├─ /api/drug/search
 ├─ /api/drug/analyze-image
 ├─ /api/drug/prospectus
 ├─ /api/drug/interaction
 ├─ /api/drug/natural-alternatives
 ├─ /api/drug/chat
 ├─ /api/pharmacy/nearby
 ├─ /api/pharmacy/districts
 └─ /api/profile/*
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
- qr_flutter

### Backend

- FastAPI
- Pydantic Settings
- HTTPX
- BeautifulSoup4 (eczaneler.gen.tr scraping)
- Python-Jose
- Passlib / bcrypt
- Redis
- Gemini API (`gemini-2.5-flash`)
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

### Profile

- `GET /api/profile/family/`
- `POST /api/profile/family/`
- `PUT /api/profile/family/{id}`
- `DELETE /api/profile/family/{id}`
- `GET /api/profile/family/{id}/drugs/`
- `POST /api/profile/family/{id}/drugs/`
- `DELETE /api/profile/family/{id}/drugs/{drug_id}`

### Pharmacy

- `GET /api/pharmacy/nearby`

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

- Aile profili, nöbetçi eczane, acil kart ve sağlık notları modülleri şu an ağırlıklı olarak local-first / kısmi backend entegrasyon yaklaşımıyla ilerliyor
- Release APK üretilebilir; ancak mağaza yayını için Android imzalama anahtarı (keystore), privacy policy ve store materyalleri henüz tamamlanmadı
- Backend auth ve profil katmanı şu an dosya tabanlı store kullanıyor (`backend/data/users.json`, `backend/data/family_profiles.json`)
- PostgreSQL hedef mimaride planlı olsa da aktif kalıcı veri katmanı olarak henüz devrede değil
- Backend production güvenliğinde CORS sertleştirme ve HTTPS henüz tamamlanmadı; input validation, debug=False ve JWT key rotation bu oturumda uygulandı

## Yol haritası

Detaylı ürün planı için:

- `PLAN.md`

## Katkı

Katkı süreci, commit standartları ve PR beklentileri için:

- `CONTRIBUTING.md`

## Lisans

Bu repo için henüz açık bir lisans dosyası eklenmemiştir. Yayın öncesinde uygun lisansın ayrıca belirlenmesi önerilir.
