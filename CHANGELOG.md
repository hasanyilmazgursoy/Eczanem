# Changelog

Bu dosya, projedeki dikkat çeken değişiklikleri kronolojik olarak tutar.

Biçim olarak Keep a Changelog yaklaşımı ve SemVer mantığı referans alınır.

## [Unreleased]

### Eklendi
- **Uygulama görselleri**: Onboarding ekranları, boş durum sayfaları ve ana
  uygulama logosu için özel illüstrasyonlar eklendi (`assets/images/`)
- **Onboarding illüstrasyonları**: Material icon'larının yerine özel flat-design
  görseller kullanılmaya başlandı (`onboarding_scan.png`, `onboarding_family.png`,
  `onboarding_emergency.png`)
- **Boş durum görselleri**: Hatırlatıcı, ilaç arama geçmişi, tarama geçmişi ve
  sağlık notu ekranlarına özel boş durum illüstrasyonları entegre edildi
- **`AppEmptyState` bileşeni**: İsteğe bağlı `imagePath` parametresi eklendi;
  tanımlanırsa ikon yerine asset görseli gösterilir
- **Sağlık notları — klinik ölçüm alanları**: Tansiyon (sistolik/diastolik mmHg),
  kan şekeri (mg/dL) ve ağrı seviyesi (0–10 slider) not editörüne eklendi;
  kategori seçimine göre koşullu olarak görünür
- **Nöbetçi eczane — il/ilçe dropdown seçimi**: Serbest metin girişi kaldırıldı;
  81 il statik listesi (`turkey_data.dart`) ve eczaneler.gen.tr'den dinamik ilçe
  listesi ile dropdown tabanlı arayüz getirildi; slug uyuşmazlıklarına (ör.
  Battalgazi → Malatya Merkez) gerek kalmadı
- **Backend — `GET /api/pharmacy/districts`**: Seçili ilin gerçek nöbet ilçelerini
  eczaneler.gen.tr'den çekerek döndüren yeni endpoint eklendi; dropdown doldurmak
  için kullanılır
- **Nöbetçi eczane — il geneline otomatik fallback**: Seçili ilçede nöbetçi
  eczane bulunamazsa backend il genelini sorgular; Flutter tarafı `fallback_to_il`
  alanını okuyarak kullanıcıya bildirim banner'ı gösterir
- **AI sohbet — Gemini sistem promptu**: Eczacı chat promptuna markdown
  biçimlendirme ve emoji kullanım kuralları eklendi; yanıtlar daha yapılandırılmış
  ve okunabilir hale getirildi

### Değiştirildi
- **Sağlık notları ekranı sadeleştirildi**: Takvim görünümü, rapor sayfası ve
  "Doktora Göster" modu kaldırıldı; AppBar aksiyonsuz, body her zaman liste
  görünümü
- **Not kartı basitleştirildi**: Ölçüm rozetleri, semptom etiketleri, mood emoji
  ve ilaç uyarısı kaldırıldı; kart yalnızca kategori ikonu + tarih + not metni
  gösterir
- **Not editörü**: Mood seçimi, semptom chip'leri ve ilaç alındı switch'i
  kaldırıldı; editör tarih + kategori + koşullu ölçüm + metin alanlarından oluşur
- **Tarama ekranı mod seçici**: Tek toggle yerine bağımsız iki buton (kamera /
  galeri) kullanılmaya başlandı; seçili mod görsel olarak vurgulanır
- **Gemini modeli**: `gemini-2.0-flash` → `gemini-2.5-flash` olarak güncellendi
  (2.0-flash 1 Haziran 2026'da kapatılıyor)
- **AI sohbet scroll davranışı**: AI yanıtı gelince ekran otomatik en alta
  kaymıyor; kullanıcı mesajı gönderince typing indicator görünsün diye hâlâ
  aşağı iniyor
- **AI sohbet markdown render**: `MarkdownBody`'ye h1/h2/h3, italik, satır içi
  kod ve blok alıntı stilleri eklendi; satır yükseklikleri ve boşluklar
  okunurluğa göre ayarlandı

### Düzeltildi
- **Backend: Gemini 429 kota hatası**: API 429 döndürdüğünde ham hata yerine
  anlamlı 503 + Türkçe mesaj iletilir
- **Sağlık notu editörü**: Klavye açıkken "Kaydet" butonu artık görünür;
  `SafeArea` + `viewInsets.bottom` sarmalayıcı ile klavye-üstü düzen sağlandı
- **Boş durum ekranı taşma**: `_EmptyNotesState` overflow sorunu giderildi
- **Markdown render**: İlaç detay, ilaç etkileşim ve semptom analizi ekranlarında
  AI yanıtları `flutter_markdown` ile düzgün render edilir hale getirildi
- **Nöbetçi eczane ilçe dropdown**: `pharmacy.all_districts` çeviri anahtarı
  `DropdownMenuItem` ilk render'ında ham key olarak görünüyordu; `value: null →
  value: ''` sentinel değişikliği ve `Builder` sarmalayıcı ile düzeltildi
- **Backend ilçe scraping**: "İlçe Seç" sidebar container kısıtlaması bazı
  illerde eksik sonuç veriyordu; tam sayfa taramaya geçilerek eksiksiz liste
  sağlandı

## [1.2.0] - 2026-05-18

### Eklendi
- **FAZ 7 — QR Kod Paylaşımı**: Acil durum kartı verileri QR koda dönüştürülüp
  dialog üzerinde gösterilir; birinci yardım personeli okutarak bilgilere anında
  erişebilir (`qr_flutter ^4.1.0` bağımlılığı eklendi)
- **Harita Görünümü (FAZ 6)**: Nöbetçi eczane ekranına OSM tabanlı flutter_map
  entegrasyonu; eczane pin'leri, kullanıcı konumu, bottom sheet ile arama ve
  yol tarifi
- **Onboarding bayrak kontrolü**: Onboarding'i tamamlayan kullanıcı ileriki
  oturumda login ekranına yönlendirilir (tekrar onboarding görmez)
- **Dio 401 interceptor**: Token süresi dolan istekler `auth_access_token`'ı
  temizler ve kullanıcıyı login ekranına yönlendirir

### Değiştirildi
- **Backend: global exception handler**: Yakalanmamış hatalar artık ham
  traceback döndürmez; 500 + sade JSON mesajı döner, server-side logger ile
  kaydedilir
- **Backend: Pydantic Field validation**: Drug router'ındaki tüm request
  model'larına `min_length` / `max_length` kısıtları eklendi (saldırı
  yüzeyini küçültür, 422 ile otomatik reddedilir)
- **Backend: Dockerfile** `--reload` kaldırıldı, `--workers 2` eklendi
  (production-safe)
- **Backend: `debug` varsayılanı** `False` yapıldı; docs/redoc yalnızca
  DEBUG=True ortamında açılır
- **JWT_SECRET_KEY**: Güçlü random key ile değiştirildi (`.env` aracılığıyla
  override edilir; hardcoded değer sadece fallback olarak kaldı)
- **SignupScreen** `ConsumerStatefulWidget`'a dönüştürüldü; controller'lar
  `State`'te tutulur, şifre toggle düzeltildi
- **GoRouter auth redirect**: Giriş yapmış kullanıcı auth sayfalarından
  otomatik olarak home'a yönlendirilir

### Düzeltildi
- `auth_provider`: `forgotPassword` başarı mesajı hardcoded İngilizce'den
  lokalizasyon anahtarına (`auth.reset_link_sent`) taşındı
- `AndroidManifest.xml`: `INTERNET` izni, cleartext traffic ve uygulama adı
  release manifest'e eklendi


- Repo için profesyonel dokümantasyon dosyaları (`README.md`, `CONTRIBUTING.md`, PR şablonu)
- `.editorconfig` ve `.gitattributes` ile temel repo standartları
- İlaç aramasında Redis tabanlı 24 saat cache ve bellek içi fallback desteği
- Hive tabanlı yerel depolama ve SharedPreferences migration desteği
- `POST /api/drug/analyze-image` endpoint'i ile FAZ 2 backend başlangıcı
- Mobilde kamera / galeri seçimi, görsel önizleme ve analiz başlatma akışı
- Aile profili için backend router/service katmanı ve mobil aile ekranları
- Nöbetçi eczane için backend endpoint'i, servis katmanı ve mobil liste ekranı
- Acil durum kartı veri modeli, repository katmanı ve düzenleme/görüntüleme ekranı
- Sağlık notları veri modeli, repository katmanı ve liste/düzenleme ekranı
- Home ekranına Acil Kart ve Sağlık Notları aksiyon kartları
- Türkçe ve İngilizce çeviri dosyalarına family, pharmacy, emergency ve health notes kapsamı

### Değiştirildi
- Yol haritası ve README, mevcut gerçek ilerlemeye göre güncellendi
- Ana sayfa faz ilerleme metinleri FAZ 2 başlangıcına göre güncellendi
- PLAN ve README içindeki faz durumları mevcut kod tabanına göre senkronize edildi
- Uygulama routing yapısı yeni feature ekranlarını içerecek şekilde genişletildi
- FAZ 8 odağı dokümantasyon senkronu, test ve polish olarak netleştirildi

## [1.1.0] - 2026-04-14

### Eklendi
- Yerel ilaç hatırlatıcıları için yeni reminder ekranı ve stok dashboard'u
- Günlük tekrar eden offline bildirim planlama altyapısı
- Zaman dilimi çözümü ve cihaz yeniden başlatma sonrası bildirimlerin tekrar kurulması
- İlaç detay ekranı, ana sayfa ve profil üzerinden hatırlatıcıya hızlı girişler
- Hatırlatıcı veri modeli için yeni repository testleri

### Değiştirildi
- Mobil sürüm numarası `1.1.0+2` olarak yükseltildi
- README ve PLAN dosyaları FAZ 4 tamamlandı bilgisini yansıtacak şekilde güncellendi

### Notlar
- Release APK üretimi hazır; Play Store yayını için ayrıca imzalı keystore yapılandırması gerekecek

## [0.1.0] - 2026-04-11

### Eklendi
- Flutter tabanlı mobil iskelet ve feature-first yapı
- FastAPI backend iskeleti
- JWT tabanlı basit auth akışı
- Ana sayfa / dashboard MVP
- İlaç arama ekranı ve detay ekranı
- Son aramalar desteği
- Arama debounce
- Skeleton loading desteği
- İlaç aramasına cache ve rate limit katmanı
- Gerçek Android cihazda çalışma doğrulaması

### Değiştirildi
- Mobil arama ekranında hata / boş / loading durumları iyileştirildi
- Repo yol haritası gerçek ilerlemeye göre güncellendi
- Auth tarafında `bcrypt` sürümü sabitlenerek mobil login kararlı hale getirildi

### Notlar
- Güvenli oturum verisi için `flutter_secure_storage` kullanılmaya devam edilmektedir
