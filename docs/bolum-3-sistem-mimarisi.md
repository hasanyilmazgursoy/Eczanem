3. SİSTEM MİMARİSİ VE TASARIM

Bu bölümde Eczanem'in genel sistem mimarisi, mobil istemci tasarımı, sunucu tarafı yapısı, yapay zekâ servis katmanı, önbellek ve güvenlik mekanizmaları ele alınmaktadır.


3.1 Genel Mimari Bakış

Eczanem iki katmanlı bir istemci-sunucu (client-server) mimarisine sahiptir. Mobil katman tüm yerel işlevleri doğrudan cihazda çalıştırırken bulut katmanı yapay zekâ analizini ve kimlik yönetimini üstlenmektedir. Bu hibrit yaklaşım, ağ bağlantısı olmaksızın kritik sağlık bilgilerinin (ilaç hatırlatıcısı, acil durum kartı) erişilebilir kalmasını güvence altına almaktadır.

```
┌─────────────────────────────────────────────────────────┐
│                    KULLANICI CİHAZI                      │
│  Flutter Uygulaması (iOS / Android)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Hive (lokal │  │ Secure       │  │ Local Notif.  │  │
│  │  NoSQL)      │  │ Storage(JWT) │  │ (Hatırlatıcı) │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
└──────────────────────────────┬──────────────────────────┘
                               │ HTTPS / REST
┌──────────────────────────────▼──────────────────────────┐
│                   FASTAPI BACKEND (Docker)               │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐  │
│  │  Auth        │  │  Drug Router │  │ Pharmacy      │  │
│  │  Router      │  │  (7 endpoint)│  │ Router        │  │
│  └──────────────┘  └──────┬───────┘  └───────┬───────┘  │
│                           │                   │          │
│  ┌──────────────┐  ┌──────▼───────┐  ┌───────▼───────┐  │
│  │  Redis Cache │  │ Gemini Servis│  │ BeautifulSoup │  │
│  │  (TTL=86400s)│  │ (LLM + MM)   │  │ Scraper       │  │
│  └──────────────┘  └──────────────┘  └───────────────┘  │
└─────────────────────────────────────────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              │         DIŞ SERVİSLER           │
              │  Google Gemini API              │
              │  Nominatim (OSM)                │
              │  eczaneler.gen.tr               │
              └─────────────────────────────────┘
```

Şekil 3.1. Eczanem Genel Sistem Mimarisi


3.2 Mobil İstemci Mimarisi (Flutter Clean Architecture)

Mobil uygulama, Robert C. Martin'in önerdiği Clean Architecture prensiplerine göre üç temel katmana ayrılmıştır:

**3.2.1 Katman Yapısı**

- **Presentation (Sunum) Katmanı:** Riverpod AsyncNotifier'ları ile yönetilen UI widget'ları. Hata ve yükleme durumları AsyncValue API'siyle kapsüllenir.
- **Domain (Alan) Katmanı:** Saf Dart sınıflarından oluşan repository sözleşmeleri ve varlık modelleri. Herhangi bir çerçeve bağımlılığı yoktur.
- **Data (Veri) Katmanı:** Repository uygulamaları, Hive yerel depolama adaptörleri, Dio HTTP istemcisi ve uzak veri kaynakları.

**3.2.2 Modüler Organizasyon**

Uygulama, feature-first (özellik öncelikli) modüler yapıya göre dokuz özellik modülüne ayrılmıştır:

| Modül | İşlev |
|---|---|
| `drug_search` | Metin tabanlı ilaç arama ve geçmiş |
| `drug_scan` | Görüntüden ilaç tanıma |
| `pharmacy_map` | OSM tabanlı nöbetçi eczane haritası |
| `medication_reminder` | Çevrimdışı zamanlı ilaç bildirimleri |
| `health_notes` | Kişisel sağlık günlüğü |
| `emergency_card` | Çevrimdışı acil durum bilgileri |
| `profile` | Aile profili ve ilaç kaydı |
| `auth` | JWT tabanlı kimlik doğrulama |
| `onboarding` | İlk başlatma akışı |

**3.2.3 Durum Yönetimi**

Riverpod 2.6.1 kütüphanesi, asenkron durum yönetimi için kullanılmaktadır. Hata yayılımı `fpdart 1.2.0` kütüphanesinden `FutureEither<Failure, T>` tipiyle gerçekleştirilmektedir. Bu yaklaşım, Railway Oriented Programming (ROP) prensiplerini Flutter ekosistemine taşıyarak exception fırlatma yerine tip güvenli hata yayılımı sağlamaktadır.

```dart
// FutureEither tipinin kullanım örneği
FutureEither<Failure, DrugSearchResult> searchDrug(String query);
//           ↑ Hata          ↑ Başarı sonucu
```


3.3 Sunucu Tarafı Mimarisi (FastAPI)

Backend, FastAPI çerçevesi üzerine inşa edilmiş modüler bir Python uygulamasıdır. Docker ile konteynerize edilmiş olup bağımlılıkları `docker-compose.yml` ile tanımlanmıştır.

**3.3.1 Router Yapısı**

```
backend/app/routers/
  ├── auth.py      → Kimlik doğrulama (8 endpoint)
  ├── drug.py      → İlaç servisleri (7 AI endpoint)
  ├── pharmacy.py  → Nöbetçi eczane (2 endpoint)
  ├── profile.py   → Aile profili CRUD
  └── health.py    → Sistem sağlığı kontrolü
```

**3.3.2 Yapılandırma Yönetimi**

Tüm ortam değişkenleri `backend/app/core/config.py` içindeki Pydantic `Settings` sınıfıyla tip güvenli biçimde yönetilmektedir. Prodüksiyon ortamında varsayılan JWT anahtarının kullanılmasını engelleyen doğrulayıcı (validator) tanımlanmıştır.


3.4 Yapay Zekâ Servis Katmanı

Yapay zekâ işlevleri `backend/app/services/gemini_service.py` içinde merkezi olarak yönetilmektedir.

**3.4.1 Gemini 2.5 Flash Entegrasyonu**

Google Gemini 2.5 Flash, `generateContent` REST API endpoint'i üzerinden erişilmektedir. İlaç bilgisi sorgularında halüsinasyon riskini azaltmak amacıyla `temperature=0.3` olarak yapılandırılmıştır. Sohbet fonksiyonu için geçmiş mesajlar (maksimum ~50 mesaj) bağlam penceresi olarak modele iletilmektedir.

**3.4.2 Hata Toleransı**

Geçici API hatalarına karşı exponential backoff ile 3 yeniden deneme stratejisi uygulanmaktadır. Gemini'nin zaman zaman JSON çıktısını markdown kod bloğu içine sarması nedeniyle `_extract_json_payload` yardımcı fonksiyonu yanıtları temizlemektedir.

**3.4.3 Görüntü İşleme Akışı**

```
Kullanıcı fotoğrafı
       │
       ▼
Pillow ön işleme
(max 1400×1400 px, EXIF normalleştirme)
       │
       ▼
Base64 kodlama → Gemini API (inlineData)
       │
       ▼
Yapılandırılmış JSON yanıt → Flutter istemcisine
```

Şekil 3.2. Görüntü Tabanlı İlaç Analizi Akışı


3.5 Önbellek ve Performans Mimarisi

İlaç araması sonuçları iki katmanlı önbellekle hızlandırılmaktadır:

1. **Redis Önbelleği:** `DRUG_SEARCH_REDIS_ENABLED=true` iken etkin. Sorgu metni hash'i anahtar olarak kullanılır; TTL 86.400 saniyedir (24 saat).
2. **Bellek İçi Dict:** Redis devre dışı ya da Redis'e erişilemez durumdaysa devreye girer (fallback). Aynı TTL uygulanır.

Hız sınırlaması (rate limiting) IP adresi bazlı kayar pencere algoritmasıyla uygulanmaktadır:
- İlaç sorgular: 10 istek / 60 saniye
- Kimlik doğrulama: 20 istek / 60 saniye


3.6 Güvenlik Tasarımı

**3.6.1 Kimlik Doğrulama**

JSON Web Token (JWT) HS256 algoritması ile üretilmektedir. Token geçerlilik süresi 7 gündür. Parola saklama bcrypt ile hash'lenerek gerçekleştirilmektedir. Flutter istemcisinde token, `flutter_secure_storage 10.0.0` kütüphanesiyle işletim sistemi şifreli deposunda (Android: EncryptedSharedPreferences, iOS: Keychain) saklanmaktadır.

**3.6.2 Ağ Güvenliği**

Tüm API iletişimi HTTPS üzerinden gerçekleştirilmektedir. CORS politikası, `ALLOWED_ORIGINS` ortam değişkeniyle kısıtlanmaktadır. Prodüksiyon doğrulayıcısı varsayılan JWT anahtarı tespit ettiğinde başlatmayı reddeder.

**3.6.3 Veri Gizliliği**

Kullanıcıya ait sağlık verileri (ilaç hatırlatıcısı, acil durum kartı, sağlık notları) yalnızca cihaz üzerindeki Hive deposunda tutulmaktadır. Yapay zekâ sorgularında kullanıcı kimliği, Gemini API'ye iletilen isteğe dahil edilmemektedir.


3.7 Yerel Bildirim Mimarisi

İlaç hatırlatıcıları `flutter_local_notifications 19.4.2` kütüphanesiyle tamamen çevrimdışı çalışmaktadır. Android için `ALARM` kanalı tanımlanmış olup "Rahatsız Etme" (DND) modunu aşacak şekilde yapılandırılmıştır (`priority: Priority.max`, `importance: Importance.max`). Kullanıcı bildirimlerine iOS'ta `requestPermission` ile izin alınmaktadır.


3.8 Harita ve Coğrafi Hizmetler

Nöbetçi eczane haritası `flutter_map 7.0.2` kütüphanesi ve OpenStreetMap döşemeleri kullanılarak ticari harita API'sinden bağımsız biçimde oluşturulmuştur. Kullanıcı konumu `geolocator 13.0.2` ile alınmakta; il/ilçe dönüşümü Nominatim reverse geocoding API'siyle gerçekleştirilmektedir. Backend, eczaneler.gen.tr'yi BeautifulSoup4 ile kazıyarak nöbetçi eczane listesini elde etmekte; eczane koordinatları Nominatim'den çözümlenmektedir.
