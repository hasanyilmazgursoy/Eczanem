# Mobil Uygulama Mimarisi — Teknik Referans Dökümanı

**Proje:** Eczanem — Kişisel İlaç Asistanı
**Platform:** Flutter (iOS + Android)
**Versiyon:** 1.2.0+3
**Dart SDK:** >=3.5.0 <4.0.0
**Güncelleme Tarihi:** Haziran 2026

---

## İçindekiler

1. [Genel Bakış](#1-genel-bakış)
2. [Teknoloji Yığını ve Seçim Gerekçeleri](#2-teknoloji-yığını-ve-seçim-gerekçeleri)
3. [Mimari Yaklaşım](#3-mimari-yaklaşım)
4. [Klasör Yapısı](#4-klasör-yapısı)
5. [Uygulama Başlatma Sırası](#5-uygulama-başlatma-sırası)
6. [Navigasyon Sistemi](#6-navigasyon-sistemi)
7. [Özellik Modülleri (Feature Modules)](#7-özellik-modülleri-feature-modules)
8. [Durum Yönetimi (State Management)](#8-durum-yönetimi-state-management)
9. [Veri Katmanı ve Yerel Depolama](#9-veri-katmanı-ve-yerel-depolama)
10. [Ağ Katmanı](#10-ağ-katmanı)
11. [Bildirim ve Hatırlatıcı Sistemi](#11-bildirim-ve-hatırlatıcı-sistemi)
12. [Tema ve Tasarım Sistemi](#12-tema-ve-tasarım-sistemi)
13. [Lokalizasyon](#13-lokalizasyon)
14. [Servisler](#14-servisler)
15. [Test Altyapısı](#15-test-altyapısı)
16. [Güvenlik Tasarımı](#16-güvenlik-tasarımı)
17. [Bilinen Sınırlamalar ve Sonraki Adımlar](#17-bilinen-sınırlamalar-ve-sonraki-adımlar)

---

## 1. Genel Bakış

Eczanem mobil uygulaması, kullanıcıların ilaç bilgisi aramasını, ilaç fotoğrafı çekerek tanımlama yapmasını, ilaç etkileşimlerini kontrol etmesini, aile üyeleri için ilaç listesi tutmasını, ilaç hatırlatıcısı kurmasını ve yakınındaki nöbetçi eczaneleri bulmasını sağlayan kapsamlı bir sağlık asistanıdır.

```
┌────────────────────────────────────────────────┐
│               Flutter Mobil Uygulama            │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐ │
│  │  Drug    │  │  Profile │  │  Pharmacy    │ │
│  │ Feature  │  │ Feature  │  │  Feature     │ │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘ │
│       │              │               │          │
│  ┌────▼──────────────▼───────────────▼────────┐ │
│  │          Shared Services Katmanı            │ │
│  │  StorageService │ NotificationService       │ │
│  │  AppConfig (Dio) │ SecureStorageService     │ │
│  └──────────────────────────────────────────── ┘ │
│                                                │
│  ┌────────────────────────────────────────────┐ │
│  │          Riverpod State Management          │ │
│  └────────────────────────────────────────────┘ │
└──────────────┬─────────────────────────────────┘
               │ Dio (HTTP/JSON)
               ▼
      FastAPI Backend + Gemini AI
```

---

## 2. Teknoloji Yığını ve Seçim Gerekçeleri

### Temel Framework

| Paket | Versiyon | Kullanım Amacı | Seçilme Gerekçesi |
|---|---|---|---|
| **Flutter** | 3.x | UI framework | Tek kod tabanı, iOS ve Android için native performans |
| **Dart** | >=3.5.0 | Programlama dili | Null safety, records, patterns (Dart 3 özellikleri) |

### Navigasyon

| Paket | Versiyon | Seçilme Gerekçesi |
|---|---|---|
| **go_router** | ^17.1.0 | Deklaratif navigasyon; URL tabanlı yönlendirme sayesinde deep link desteği; auth redirect guard mantığı temiz ve test edilebilir |

### Durum Yönetimi ve Fonksiyonel Programlama

| Paket | Versiyon | Seçilme Gerekçesi |
|---|---|---|
| **flutter_riverpod** | ^2.6.1 | Compile-time güvenli provider'lar; kod üreteci gerektirmez; kapsülleme ve test kolaylığı |
| **fpdart** | ^1.2.0 | `Either<Failure, T>` tipiyle hata yayılımı; exception yerine tip güvenli hata yönetimi |
| **equatable** | ^2.0.7 | Value equality; `==` ve `hashCode` override olmadan nesne karşılaştırma |

### Ağ ve Depolama

| Paket | Versiyon | Seçilme Gerekçesi |
|---|---|---|
| **dio** | ^5.9.2 | İnterceptor desteği; FormData/multipart; 401 otomatik logout interceptor'ı |
| **hive_flutter** | ^1.1.0 | Flutter'a özel optimize edilmiş yerel key-value deposu; SharedPreferences'tan hızlı |
| **flutter_secure_storage** | ^10.0.0 | JWT token'ı OS Keychain/Keystore'da şifreli saklar |
| **shared_preferences** | ^2.5.4 | İlk sürümlerde kullanıldı; Hive migrasyonu için varlığı sürdürülüyor |
| **flutter_dotenv** | ^6.0.0 | `.env` dosyasından `API_BASE_URL` gibi yapılandırma okuma |

### Medya ve Görsel

| Paket | Versiyon | Kullanım |
|---|---|---|
| **camera** | ^0.11.2 | Kamera önizleme ve fotoğraf çekme (ilaç tarama) |
| **image_picker** | ^1.2.1 | Galeriden fotoğraf seçme |
| **file_picker** | ^10.3.10 | Dosya seçici (prospektüs yükleme) |
| **image** | ^4.5.4 | Görsel işleme; JPEG dönüştürme, boyutlandırma |
| **cached_network_image** | ^3.4.1 | Ağdan gelen görsellerin bellekte ve diskte önbelleğe alınması |

### Harita ve Konum

| Paket | Versiyon | Kullanım |
|---|---|---|
| **flutter_map** | ^7.0.2 | OpenStreetMap (Leaflet benzeri) katmanı; Google Maps API anahtarı gerektirmez |
| **latlong2** | ^0.9.1 | Coğrafi koordinat tipi (`LatLng`) |
| **geolocator** | ^13.0.2 | GPS konumu; tek seferlik konum alma |

### Bildirimler

| Paket | Versiyon | Kullanım |
|---|---|---|
| **flutter_local_notifications** | ^19.4.2 | Zamanlanmış ilaç hatırlatıcı bildirimleri |
| **timezone** | ^0.10.1 | Saat dilimine duyarlı bildirim planlaması |
| **flutter_timezone** | ^4.1.1 | Cihazın yerel saat dilimini okur |

### UI / UX

| Paket | Versiyon | Kullanım |
|---|---|---|
| **flutter_screenutil** | ^5.9.3 | Ekran boyutuna uyarlanabilir dp/sp değerleri |
| **flutter_animate** | ^4.5.2 | Chained animasyon API'si |
| **skeletonizer** | ^2.1.3 | Yükleme durumunda iskelet (skeleton) UI |
| **smooth_page_indicator** | ^2.0.1 | Onboarding sayfa indikatörü |
| **fl_chart** | ^0.70.2 | Sağlık notu trendi grafikleri |
| **table_calendar** | ^3.1.3 | Hatırlatıcı takvim görünümü |
| **flutter_markdown_plus** | ^1.0.7 | Gemini AI yanıtlarını Markdown olarak render etme |
| **qr_flutter** | ^4.1.0 | Acil durum kartı QR kodu üretimi |
| **flutter_svg** | ^2.2.4 | SVG ikon ve illüstrasyon desteği |

### Diğer

| Paket | Versiyon | Kullanım |
|---|---|---|
| **easy_localization** | ^3.0.8 | TR/EN çoklu dil desteği |
| **speech_to_text** | ^7.0.0 | Sesli ilaç arama |
| **logger** | ^2.6.2 | Renkli, yapılandırılmış konsol logları |
| **flutter_native_splash** | ^2.4.3 | Native splash screen (beyaz flash önleme) |
| **share_plus** | ^10.1.3 | Sistem paylaşım diyaloğu |
| **url_launcher** | ^6.3.1 | Harici link açma (telefon, web) |
| **permission_handler** | ^12.0.1 | Kamera, konum, bildirim izinleri |

---

## 3. Mimari Yaklaşım

### Feature-First Clean Architecture

Uygulama, her özelliğin kendi `data/`, `domain/` ve `presentation/` katmanlarını içerdiği **feature-first** bir yapıya sahiptir.

```
features/
└── drug/
    ├── data/               ← Repository'ler, API çağrıları, yerel cache
    │   ├── drug_repository.dart
    │   └── drug_history_repository.dart
    ├── domain/             ← Saf iş mantığı modelleri (varsa use-case'ler)
    └── presentation/       ← Widget'lar, ekranlar, provider'lar
        ├── providers/
        └── screens/
```

**Neden feature-first?**
`lib/screens/`, `lib/repositories/` gibi yatay katman yapısı büyüdükçe bakımı zorlaşır; bir özelliğe dokunan dosyalar farklı klasörlere dağılır. Feature-first yapıda bir özelliğe ait her şey tek klasörde toplanır; özellik silinirken veya taşınırken diğer özellikler etkilenmez.

### Hata Yönetimi: `FutureEither<L, R>`

Tüm I/O işlemleri (repository, servis) exception fırlatmak yerine `fpdart`'ın `Either` tipiyle hata döner:

```dart
// Başarı durumu
Right(DrugInfo(...))

// Hata durumu
Left(Failure(message: 'Bağlantı hatası', code: 500))
```

Bu yaklaşım sayesinde:
- Hata akışı tip sistemi tarafından zorunlu kılınır
- Unhandled exception riski azalır
- `fold()` ile başarı ve hata dalları simetrik işlenir

```dart
final result = await drugRepository.searchDrug(query);
result.fold(
  (failure) => state = AsyncError(failure.message, StackTrace.current),
  (drug) => state = AsyncData(drug),
);
```

---

## 4. Klasör Yapısı

```
mobile/lib/
├── main.dart                          # Uygulama giriş noktası
└── src/
    ├── app.dart                       # Root widget (MaterialApp.router)
    ├── flavors.dart                   # Build flavor yapılandırması
    ├── config/
    │   └── app_config.dart            # Dio singleton, baseUrl, 401 interceptor
    ├── routing/
    │   ├── app_router.dart            # GoRouter örneği, redirect guard
    │   ├── app_routes.dart            # Route sabitleri (path string'leri)
    │   └── global_navigator.dart      # rootNavigatorKey, rootContext erişimi
    ├── features/                      # Özellik modülleri (bkz. Bölüm 7)
    │   ├── auth/
    │   ├── drug/
    │   ├── emergency/
    │   ├── health_notes/
    │   ├── home/
    │   ├── onboarding/
    │   ├── pharmacy/
    │   ├── profile/
    │   └── reminder/
    ├── services/                      # Uygulama geneli paylaşılan servisler
    │   ├── auth_service.dart          # Login/signup HTTP çağrıları
    │   ├── copy_service.dart          # Panoya kopyalama
    │   ├── dio_service.dart           # Dio wrapper yardımcıları
    │   ├── internet_connection_service.dart
    │   ├── media_service.dart         # Kamera / galeri / dosya seçici
    │   ├── notification_service.dart  # Bildirim planlaması
    │   ├── path_service.dart          # Cihaz dizin yolları
    │   ├── permission_service.dart    # İzin istekleri
    │   ├── secure_storage_service.dart # FlutterSecureStorage wrapper
    │   ├── storage_service.dart       # Hive wrapper (genel K-V)
    │   └── url_launcher_service.dart
    ├── shared/                        # Özellikler arası paylaşılan widget'lar
    ├── theme/                         # Tasarım sistemi (bkz. Bölüm 12)
    │   ├── app_spacing.dart
    │   ├── app_borders.dart
    │   ├── app_shadows.dart
    │   ├── app_durations.dart
    │   ├── app_curves.dart
    │   ├── color_schemes.dart
    │   ├── text_theme.dart
    │   ├── theme.dart
    │   └── theme_constants.dart       # Barrel export
    ├── extensions/                    # Dart extension method'ları
    ├── imports/                       # Barrel import dosyaları
    └── utils/                         # Logger, yardımcı fonksiyonlar
```

---

## 5. Uygulama Başlatma Sırası

`main.dart` içindeki başlatma sırası kasıtlı olarak belirlenmiştir; her adım bir sonrakine bağımlıdır:

```
main() çağrılır
       │
       ▼
WidgetsFlutterBinding.ensureInitialized()
— Widget sistemi hazır, Flutter engine bağlandı
       │
       ▼
FlutterNativeSplash.preserve()
— Native splash ekranı bu noktadan itibaren gösteriliyor,
  removeAfter() çağrılana kadar kaldırılmaz
       │
       ▼
EasyLocalization.ensureInitialized()
— Çeviri JSON dosyaları yüklenir (assets/translations/)
       │
       ▼
dotenv.load(fileName: '.env')
— API_BASE_URL gibi ortam değişkenleri hafızaya alınır
       │
       ▼
AppConfig.init()
— Dio oluşturulur, baseUrl atanır, 401 interceptor eklenir
       │
       ▼
StorageService.instance.init()
— Hive başlatılır; SharedPreferences migrasyonu kontrol edilir
       │
       ▼
NotificationService.instance.init()
— Timezone verileri yüklenir, Android/iOS kanalları oluşturulur
       │
       ▼
syncMedicationReminders()
— Hive'daki aktif hatırlatıcılar yeniden zamanlanır
  (uygulama güncelleme sonrası bildirimlerin kaybolmaması için)
       │
       ▼
runApp(LocalizationWrapper(StateWrapper(App())))
— FlutterNativeSplash.remove() App build sırasında çağrılır
```

**Neden `syncMedicationReminders()` başlangıçta çağrılır?**
`flutter_local_notifications` ile planlanan bildirimler uygulama güncellemesi veya cihaz yeniden başlatması sonrasında silinebilir. Her açılışta sync çalıştırılarak bu durum telafi edilir.

---

## 6. Navigasyon Sistemi

### GoRouter Yapılandırması

Uygulamada 31 route tanımlıdır. Tüm path string'leri `AppRoutes` sınıfında sabitler olarak tanımlanmıştır:

```dart
abstract final class AppRoutes {
  static const String home              = '/';
  static const String onboarding        = '/onboarding';
  static const String login             = '/login';
  static const String signup            = '/signup';
  static const String drugSearch        = '/drug-search';
  static const String drugPhotoScan     = '/drug-photo-scan';
  static const String drugCameraCapture = '/drug-camera-capture';
  // ... (toplam 31 route)
}
```

### Kimlik Doğrulama Yönlendirme Mantığı

GoRouter'ın `redirect` callback'i her navigasyonda çalışır:

```
Kullanıcı bir route'a gitmek istiyor
              │
    FlutterSecureStorage'dan token oku
              │
    ┌─────────┴─────────┐
    │ isLoggedIn = true  │  isLoggedIn = false
    │                    │
    │  Auth route'una    │  Onboarding daha önce
    │  gitmeye çalışıyor │  görüldü mü?
    │  mu? (login vs.)   │  (onboarding_seen flag)
    │                    │
    │  Evet → /home'a    │  Evet → /login'e yönlendir
    │  yönlendir         │  (logout sonrası direkt login)
    │                    │
    └─────────┬──────────┘
              │
           Devam et
```

### `globalNavigatorKey` ve `rootContext`

Bazı durumlarda widget ağacı dışından navigasyon gerekir (örneğin Dio 401 interceptor'ı). `global_navigator.dart` dosyası bu erişimi merkezi olarak sağlar:

```dart
// Dio interceptor içinde (widget ağacına erişim yok)
final ctx = rootContext;
if (ctx != null && ctx.mounted) {
  ctx.go(AppRoutes.login);
}
```

---

## 7. Özellik Modülleri (Feature Modules)

### 7.1 `auth` — Kimlik Doğrulama

| Katman | Dosya | Sorumluluk |
|---|---|---|
| Data | `auth_repository.dart` | `/auth/login`, `/auth/signup` HTTP çağrıları |
| Domain | `user_model.dart` | Kullanıcı veri modeli |
| Presentation | `session_provider.dart` | `SessionNotifier` (StateNotifier) — uygulama geneli auth durumu |
| Presentation | `login_screen.dart` | E-posta + şifre formu |
| Presentation | `signup_screen.dart` | Kayıt formu |

**`SessionNotifier` akışı:**
```
Uygulama açılır
      │
  _init() çağrılır
      │
  FlutterSecureStorage'da token var mı?
  ├─ Evet → /auth/me isteği → SessionState.authenticated(user)
  └─ Hayır → SessionState.unauthenticated()
      │
  GoRouter redirect guard buna göre yönlendirir
```

---

### 7.2 `drug` — İlaç Özellikleri

En kapsamlı feature modülüdür. 7 farklı Gemini endpoint'ini kullanır.

| Ekran | Route | İşlev |
|---|---|---|
| `DrugSearchScreen` | `/drug-search` | Metin tabanlı ilaç arama + sesli arama |
| `DrugDetailScreen` | `/drug-detail` | Arama sonucu detay (etken madde, yan etkiler, vb.) |
| `DrugPhotoCaptureScreen` | `/drug-camera-capture` | Kamera preview ile fotoğraf çekme |
| `DrugPhotoScanScreen` | `/drug-photo-scan` | Çekilen/seçilen görseli backend'e gönderme |
| `DrugImageCandidatesScreen` | `/drug-image-candidates` | Birden fazla ilaç adayı listesi |
| `DrugProspectusSummaryScreen` | `/drug-prospectus-summary` | Prospektüs özeti (görsel girdi) |
| `DrugInteractionScreen` | `/drug-interaction` | Çoklu ilaç etkileşim kontrolü |
| `DrugNaturalAlternativesScreen` | `/drug-natural-alternatives` | Doğal alternatif önerileri |
| `AiChatScreen` | `/ai-chat` | Yapay zekâ eczacı sohbeti |
| `SymptomAnalysisScreen` | `/symptom-analysis` | Semptom analizi ve olası nedenler |
| `DrugSearchHistoryScreen` | `/drug-search-history` | Arama geçmişi (Hive) |
| `DrugScanHistoryScreen` | `/drug-scan-history` | Görsel tarama geçmişi (Hive) |

**İlaç Arama Akışı:**
```
Kullanıcı metin girer (veya sesle söyler)
       │
drug_repository.searchDrug(query)
       │
Dio POST /api/drug/search
       │
FutureEither<DrugInfo>
       │
   ├─ Right(data) → DrugDetailScreen'e push
   └─ Left(failure) → Hata snackbar
```

---

### 7.3 `reminder` — İlaç Hatırlatıcısı

Tamamen çevrimdışı çalışır; backend bağlantısı gerektirmez.

**Veri Modeli:**
```
MedicationReminder
├── id: String
├── drugName: String
├── dosage: String
├── times: List<TimeOfDay>          ← Günlük bildirim zamanları
├── isActive: bool
├── hasStockTracking: bool
├── stockCount: int                 ← Mevcut stok (adet)
├── unitsPerDose: int               ← Doz başına tüketilen adet
├── lowStockThreshold: int          ← Bu seviyenin altında uyarı ver
└── createdAt / updatedAt: DateTime
```

**Stok Takibi Akışı:**
```
Kullanıcı "Doz aldım" tuşuna basar
       │
takeDose(id) çağrılır
       │
stockCount = max(stockCount - unitsPerDose, 0)
       │
stockCount < lowStockThreshold mı?
├─ Evet → microtask olarak düşük stok bildirimi planla
│          (senkron işlemi bloke etmemek için)
└─ Hayır → Sadece stok güncelle
       │
Hive'a kaydet
```

**Sıralama Önceliği (`_sortByPriority`):**
1. Aktif + düşük stok → en üstte (acil dikkat gerektirir)
2. Aktif + normal stok → zaman sırasına göre
3. Pasif hatırlatıcılar → en altta

---

### 7.4 `profile` — Aile Profili

Birden fazla aile üyesi oluşturmayı ve her üye için ilaç listesi tutmayı sağlar.

**Local-First Mimari:**
```
addMember() çağrılır
       │
  Hive'a hemen yaz (optimistik güncelleme)
       │
  UI anında güncellenir
       │
  microtask ile _syncAddMember() çalışır
       │
  POST /api/profile/family/ (arka planda)
       │
  ├─ Başarılı → Cloud ile senkron
  └─ Hata → Yerel veri korunur (tekrar deneme planlanmamış)
```

`syncFromBackend()`: Kullanıcı giriş yaptığında backend'deki veriler yerel depoya çekilerek tüm cihazlar arası tutarlılık sağlanır.

---

### 7.5 `pharmacy` — Nöbetçi Eczane

Harita üzerinde yakın nöbetçi eczaneleri gösterir.

- `flutter_map` ile OSM (OpenStreetMap) haritası
- `geolocator` ile cihaz konumu alınır
- Konum izni yoksa il/ilçe manuel seçimi sunulur
- Backend `GET /api/pharmacy/nearby` çağrısı ile eczane listesi
- Her eczane haritada pin olarak gösterilir; tıklandığında detay paneli açılır

---

### 7.6 `emergency` — Acil Durum Kartı

Kullanıcının kan grubu, alerjiler, kronik hastalıklar ve acil iletişim bilgilerini barındıran dijital kart.

- Veriler yalnızca yerel Hive'da saklanır (hassas sağlık verisi)
- QR kod olarak paylaşılabilir (`qr_flutter`)
- Sistem paylaşım diyaloğuyla PDF/metin olarak gönderilebilir (`share_plus`)

---

### 7.7 `health_notes` — Sağlık Notları

Kan basıncı, ağırlık, nabız gibi sağlık ölçümlerinin kayıt ve takip ekranı.

- Kayıtlar Hive'da tarih-değer çifti olarak tutulur
- `fl_chart` ile trend grafiği çizilir
- `table_calendar` ile takvim görünümünden geçmişe erişilebilir

---

### 7.8 `onboarding` — Karşılama Ekranı

İlk kurulum sırasında uygulamanın özelliklerini tanıtan 3 sayfalık carousel.

- `smooth_page_indicator` ile sayfa göstergesi
- Tamamlandığında `onboarding_seen = true` Hive'a yazılır
- Sonraki açılışlarda doğrudan giriş ekranına yönlendirilir

---

### 7.9 `home` — Ana Ekran

Tüm özelliklere erişim noktası. Kullanıcıya hızlı eylem kartları ve son aktivite özeti sunar.

---

## 8. Durum Yönetimi (State Management)

### Riverpod Provider Hiyerarşisi

```
┌──────────────────────────────────────────────────────┐
│                  SessionProvider                     │
│  (StateNotifier<SessionState> — auth durumu)         │
│  Uygulama geneli; root widget'ta dinlenir            │
└──────────────────────┬───────────────────────────────┘
                       │ inject
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
  DrugSearchProvider  ReminderProvider  FamilyProvider
  (AsyncNotifier)     (Notifier)        (StateNotifier)
         │
   AsyncValue<DrugInfo>
   ├─ AsyncLoading() → Skeleton UI
   ├─ AsyncData(drug) → Detay göster
   └─ AsyncError(msg) → Hata mesajı
```

### `SessionState` Durum Makinesi

```
        ┌──────────────┐
        │   initial    │  (splash, token kontrol ediliyor)
        └──────┬───────┘
               │ _init()
    ┌──────────┴────────────┐
    ▼                       ▼
authenticated(user)    unauthenticated()
    │                       │
logout() çağrılır      login() başarılı
    │                       │
    └──────────┬────────────┘
               ▼
         unauthenticated()
```

---

## 9. Veri Katmanı ve Yerel Depolama

### Hive (Birincil Depo)

`StorageService` Hive'ı tek bir anahtar-değer kutusunda (`box`) saran singleton bir wrapper'dır.

```dart
// Okuma
StorageService.instance.getString('emergency_card_v1');
StorageService.instance.getBool('onboarding_seen');

// Yazma
await StorageService.instance.setString('key', jsonString);
await StorageService.instance.setBool('onboarding_seen', true);
```

**Depolanan Veriler ve Anahtarları:**

| Anahtar | Tip | İçerik |
|---|---|---|
| `medication_reminders_v1` | `List<String>` | JSON serileştirilmiş hatırlatıcı listesi |
| `emergency_card_v1` | `String` | JSON serileştirilmiş acil kart |
| `family_members_v1` | `String` | JSON serileştirilmiş aile listesi |
| `drug_search_history_v1` | `List<String>` | Arama geçmişi (metin) |
| `drug_scan_history_v1` | `List<String>` | Tarama geçmişi (JSON) |
| `onboarding_seen` | `bool` | Onboarding tamamlandı mı? |
| `medication_reminder_notification_ids_v1` | `List<String>` | Planlanan bildirim ID'leri |

### SharedPreferences → Hive Migrasyonu

İlk sürümlerde SharedPreferences kullanılıyordu. Hive geçişi sırasında mevcut kullanıcı verisinin kaybolmaması için tek seferlik migrasyon uygulanmıştır:

```
StorageService.init() çağrılır
       │
  '__shared_preferences_migrated__' anahtarı Hive'da var mı?
  ├─ Evet → Migrasyon zaten yapıldı, geç
  └─ Hayır → SharedPreferences'tan tüm anahtarları oku
              │
              Hive'a kopyala
              │
              '__shared_preferences_migrated__' = true yaz
```

### FlutterSecureStorage (JWT Token)

JWT token OS güvenlik altyapısında saklanır:
- **Android:** EncryptedSharedPreferences (AES-256)
- **iOS:** Keychain (hardware-backed, biyometrik erişim opsiyonel)

```dart
// Token yazma (login sonrası)
await SecureStorageService.instance.write('auth_access_token', token);

// Token okuma (her istek öncesi Dio interceptor'ı)
final token = await SecureStorageService.instance.read('auth_access_token');
```

---

## 10. Ağ Katmanı

### Dio Yapılandırması (`AppConfig`)

```dart
Dio(BaseOptions(
  baseUrl: dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8000'),
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),
  headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
))
```

**`10.0.2.2` neden?**
Android emülatöründe `localhost` host makinesine değil, emülatörün kendisine işaret eder. `10.0.2.2` emülatör içinden host makinenin localhost'una erişim adresidir.

### Interceptor'lar

**İstek (Request) Interceptor:**
```
Her istek öncesi
      │
FlutterSecureStorage'dan token oku
      │
Token varsa → Authorization: Bearer {token} başlığı ekle
```

**Yanıt (Response) Interceptor:**
```
HTTP 401 geldi
      │
FlutterSecureStorage'dan token sil
      │
rootContext.go(AppRoutes.login)
— Kullanıcı nerede olursa olsun login ekranına gönderilir
```

### İnternet Bağlantı Kontrolü

`internet_connection_checker_plus` paketi ile gerçek bağlantı kontrolü yapılır (sadece network interface değil, DNS/HTTPS probe ile). Bağlantı yokken yapılan istekler kullanıcı dostu hata mesajıyla engellenir.

---

## 11. Bildirim ve Hatırlatıcı Sistemi

### Android Bildirim Kanalları

İki ayrı kanal tanımlanmıştır:

| Kanal | ID | Özellik | Kullanım |
|---|---|---|---|
| İlaç Hatırlatıcıları | `medication_reminders` | Standart | Normal hatırlatıcılar |
| Alarm | `medication_alarms` | `AudioAttributesUsage.alarm` | DND (Rahatsız Etme) modunu bypass eder |

DND bypass kanalı, kullanıcı "kritik ilaç" olarak işaretlediğinde devreye girer.

### Bildirim Planlama Akışı

```
Kullanıcı hatırlatıcı kaydeder (09:00 ve 21:00)
       │
scheduleReminder(reminder) çağrılır
       │
Her saat için ayrı zamanlanmış bildirim oluşturulur
       │
TZDateTime.from(DateTime, localTimezone) → timezone-aware zaman
       │
zonedSchedule(
  id: hashCode,
  scheduledDate: nextOccurrence,
  matchDateTimeComponents: DateTimeComponents.time  ← Günlük tekrar
)
       │
Bildirim ID'leri Hive'a kaydedilir (sync için)
```

### Bildirim Sync (Uygulama Yeniden Açıldığında)

```
syncMedicationReminders()
       │
Hive'daki tüm aktif hatırlatıcıları al
       │
Her biri için mevcut bildirimleri iptal et
       │
Yeniden planla
```

Bu sayede uygulama güncellemesi veya cihaz yeniden başlatması sonrası hatırlatıcılar kaybolmaz.

---

## 12. Tema ve Tasarım Sistemi

### Renk Paleti

| Renk | Değer | Kullanım |
|---|---|---|
| Primary | `#00897B` (teal-green) | Ana renk, butonlar, vurgu |
| Surface | Material 3 uyarlamalı | Kart yüzeyleri |
| Error | Material 3 varsayılanı | Hata durumları |

Açık (light) ve koyu (dark) tema desteklenir. `ThemeMode.system` ile işletim sistemi tercihini otomatik takip eder.

### Tasarım Token'ları

Tüm sabit değerler `theme/` klasöründe merkezi olarak tanımlanmıştır:

```dart
// Boşluklar (app_spacing.dart)
AppSpacing.xs   = 4.0
AppSpacing.sm   = 8.0
AppSpacing.md   = 16.0
AppSpacing.lg   = 24.0
AppSpacing.xl   = 32.0

// Kenarlık yarıçapları (app_borders.dart)
AppBorders.sm   = BorderRadius.circular(8)
AppBorders.card = BorderRadius.circular(12)
AppBorders.lg   = BorderRadius.circular(16)

// Animasyon süreleri (app_durations.dart)
AppDurations.fast   = Duration(milliseconds: 150)
AppDurations.normal = Duration(milliseconds: 300)
AppDurations.slow   = Duration(milliseconds: 500)

// Animasyon eğrileri (app_curves.dart)
AppCurves.standard = Curves.easeInOut
AppCurves.enter    = Curves.easeOut
AppCurves.exit     = Curves.easeIn
```

`theme_constants.dart` barrel export ile tek import'ta tüm token'lar kullanılabilir.

### `flutter_screenutil` Kullanımı

Ekran boyutuna uyarlamalı UI için `.w`, `.h`, `.sp` extension'ları kullanılır:

```dart
SizedBox(height: 16.h)      // Ekran yüksekliğine orantılı
Text('', style: TextStyle(fontSize: 14.sp))  // Ölçeklenebilir font
```

---

## 13. Lokalizasyon

### Yapılandırma

`easy_localization` ile iki dil desteklenir:

```
assets/translations/
├── tr.json    # Türkçe (varsayılan)
└── en.json    # İngilizce
```

```dart
// Kullanım
Text('drug_search.title'.tr())
Text('reminder.stock_low'.tr(namedArgs: {'count': '3'}))
```

Desteklenen dil: `tr` (Türkiye) ve `en` (İngilizce). Varsayılan dil `tr`'dir; cihaz dili `tr` değilse `en` uygulanır.

---

## 14. Servisler

`services/` klasöründeki singleton servisler, birden fazla feature tarafından paylaşılan platform işlevlerini kapsar:

| Servis | Singleton Erişim | İşlev |
|---|---|---|
| `StorageService` | `.instance` | Hive K-V wrapper |
| `NotificationService` | `.instance` | Bildirim planlaması |
| `SecureStorageService` | `.instance` | JWT güvenli depo |
| `MediaService` | singleton | Kamera / galeri / dosya seçici |
| `PermissionService` | singleton | İzin sorgulama ve isteme |
| `InternetConnectionService` | stream | Bağlantı durum akışı |
| `PathService` | singleton | `getApplicationDocumentsDirectory()` |
| `CopyService` | singleton | Pano işlemleri |
| `UrlLauncherService` | singleton | `url_launcher` wrapper |

---

## 15. Test Altyapısı

`test/` klasöründe repository ve widget testleri bulunmaktadır:

| Test Dosyası | Kapsam |
|---|---|
| `drug_history_repository_test.dart` | İlaç arama/tarama geçmişi ekleme, silme, sıralama |
| `emergency_card_repository_test.dart` | Acil kart CRUD, JSON serileştirme |
| `health_notes_repository_test.dart` | Sağlık notu kaydetme ve listeleme |
| `medication_reminder_repository_test.dart` | Hatırlatıcı öncelik sıralaması, stok takibi |
| `pharmacy_item_test.dart` | Eczane veri modeli doğrulama |
| `widget_test.dart` | Temel widget render testleri |

**Test Koşturma:**
```bash
cd mobile
flutter test
```

CI/CD pipeline'ında GitHub Actions tarafından her push'ta otomatik çalıştırılır.

---

## 16. Güvenlik Tasarımı

| Tehdit | Uygulanan Önlem |
|---|---|
| **JWT token ifşası** | `flutter_secure_storage` ile OS Keychain/Keystore'da AES-256 şifreli saklama |
| **Oturum çalma** | 401 interceptor token'ı siler ve login'e yönlendirir |
| **API anahtarı ifşası** | Tüm API çağrıları backend üzerinden yapılır; Gemini API anahtarı mobil kodda yoktur |
| **Sahte token** | Backend JWT doğrulaması; imzasız veya süresi dolmuş token reddedilir |
| **HTTPS** | Production'da TLS zorunludur; geliştirmede Android `network_security_config` ile `10.0.2.2`'ye HTTP izni verilir |
| **Hassas yerel veri** | Acil kart ve sağlık notları yalnızca yerel Hive'da saklanır, backend'e gönderilmez |

---

## 17. Bilinen Sınırlamalar ve Sonraki Adımlar

### Mevcut Sınırlamalar

| Sınırlama | Açıklama | Planlanan Çözüm |
|---|---|---|
| **Aile profili backend sync** | `_syncAddMember` hata durumunda sessizce başarısız olur | Retry queue veya çakışma çözüm mekanizması |
| **Bildirim sync güvenilirliği** | Uygulama silinip yeniden kurulursa planlanan bildirimler kaybedilir | İlk kurulum akışında sync tetikleme |
| **Çevrimdışı ilaç arama** | Cache yoksa internet bağlantısı olmadan arama yapılamaz | Yerel SQLite cache |
| **Sağlık notları backend sync** | Yalnızca yerel Hive'da saklanır; cihaz değiştirince kaybolur | Backend sağlık notu endpoint'leri |
| **PDF dışa aktarma** | Paylaşma yalnızca metin/QR ile; PDF üretimi yok | `pdf` paketi entegrasyonu |
| **Biometrik auth** | Güvenli depo var ancak biyometrik kilit açma uygulanmamış | `local_auth` entegrasyonu |

### Planlanan Özellikler

- [ ] Barkod tarama ile ilaç tanıma (kamera + barcode decoder)
- [ ] İlaç hatırlatıcısı istatistikleri (uyum oranı grafiği)
- [ ] Aile profili çoklu cihaz senkronizasyonu
- [ ] Sağlık notları backend senkronizasyonu
- [ ] Bildirim aksiyonu: "Doz aldım" bildirimin üzerinden
- [ ] Widget (Ana ekran widget'ı) — günün ilacı

---

*Bu döküman, projenin kaynak kodu ile birlikte güncel tutulmalıdır. Her önemli özellik eklentisi veya mimari değişiklikte ilgili bölüm güncellenmelidir.*
