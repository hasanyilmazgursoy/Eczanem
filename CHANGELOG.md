# Changelog

Bu dosya, projedeki dikkat çeken değişiklikleri kronolojik olarak tutar.

Biçim olarak Keep a Changelog yaklaşımı ve SemVer mantığı referans alınır.

## [Unreleased]

### Eklendi
- **Proje dokümantasyonu — `docs/` klasörü**: 20 teknik referans ve tez bölümü
  belgesi oluşturuldu; `PLAN.md`, `RELEASE_CHECKLIST.md`, `VIZE_ARA_RAPOR.md`
  ve .docx dosyaları proje kökünden `docs/` altına taşındı
  (`backend-architecture.md`, `mobile-mimarisi.md`, `api-referansi.md`,
  `kurulum-rehberi.md`, `test-raporu.md`, `veri-modelleri.md`,
  `uygulama-modulleri.md`, `sistem-gereksinimleri.md`, `karsilastirmali-analiz.md`,
  `akademik-arge-raporu.md` + 10 tez bölümü)

### Düzeltildi
- **Dokümantasyon tutarsızlıkları**: `README.md` içindeki eksik `symptom-check`
  ve `change-password` endpoint'leri, `PLAN.md` içindeki `OpenRouter` referansları
  (→ Gemini API), var olmayan `/api/drug/barcode` endpoint'i, `SQLite` kullanımı
  (→ Hive only), `/api/auth/` prefix hataları (→ `/auth/`), `google_maps_flutter`
  (→ `flutter_map`) ve `CHANGELOG.md` içindeki `flutter_markdown` paket adı
  (→ `flutter_markdown_plus`) düzeltildi

### Eklendi
- **Login / Signup — marka kimliği**: Üst boşluğa eczane ikonu + "Eczanem" başlığı
  ve scale+fade giriş animasyonu eklendi; butonlar tam genişliğe (`isFullWidth: true`)
  getirildi; "Şifremi Unuttum" linki primary renge alındı
- **Semptom Analizi — hızlı başlangıç önerileri**: Boş durumda 5 dokunulabilir
  semptom önerisi (ActionChip) eklendi; kullanıcı seçince analiz alanı otomatik
  doluyor
- **Etkileşim — "Hazırsınız!" motivasyon mesajı**: İki ilaç seçildiğinde hero kart
  `hero_subtitle_ready` mesajını gösteriyor; analiz sonrası `ScrollController` ile
  sonuç alanına otomatik kaydırma eklendi
- **Nöbetçi Eczane — "Konumumu Kullan" başlangıç butonu**: Başlangıç ekranında
  il/ilçe seçmeden önce tek dokunuşla konuma göre arama yapılabiliyor
- **Hatırlatıcı — alarm switch çeviri anahtarları**: `alarm_switch` ve
  `alarm_switch_subtitle` anahtarları `tr.json` + `en.json`'a eklendi; önceki
  hardcoded Türkçe metin `.tr()` çağrısına geçirildi
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
- **Sağlık notları — semptom ve ilaç takibi**: Not editörüne semptom hızlı seçim
  chip'leri ve "İlaç alındı" switch'i eklendi; kaydedilen değerler repository'e
  iletilir (önceki sürümde bu veriler kayboluyordu)
- **Sağlık notları — `_HealthReportSheet`**: Toplam / son 7 gün istatistik
  özeti, kategori dağılımı ve `fl_chart` tabanlı tansiyon + kan şekeri trend
  grafikleri içeren alt sayfa eklendi; AppBar'dan erişilir
- **Sağlık notları — `_DoctorViewSheet`**: Vital bulgular, ağrı takibi ve semptom
  sıklığı verilerini `share_plus` ile klinik özet olarak paylaşmayı sağlayan
  alt sayfa eklendi; AppBar'dan erişilir
- **Not kartı — ölçüm ve semptom rozetleri**: Kan basıncı, kan şekeri, ağrı
  seviyesi, semptom listesi ve ilaç alındı durumu kart üzerinde badge olarak
  gösterilir
- **Hesap ayarları — `_UserInfoHeader`**: Kullanıcı adı ve e-posta adresini
  ekranın üstünde gösteren yeni bileşen eklendi
- **CI/CD**: `.github/workflows/ci.yml` eklendi — ruff lint, pip-audit CVE
  taraması, `flutter analyze` + `flutter test`, main branch'e push'ta Docker
  build doğrulaması otomatik çalışır
- **DevOps**: `backend/.dockerignore`, `docker-compose.override.yml` (dev
  ortamı `--reload` ve volume mount) ve `backend/requirements-dev.txt`
  (ruff, pytest, pytest-asyncio, httpx) eklendi
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
- **Test kapsamı**: `PharmacyItem`, `MedicationReminder` ve `DrugScanHistoryEntry`
  modelleri için birim testleri eklendi

### Değiştirildi
- **"AI / Gemini" branding kaldırıldı**: `tr.json` ve `en.json`'daki "Gemini AI"
  ifadesi "yapay zeka" olarak güncellendi; AI chat AppBar başlığından "AI" silindi;
  semptom analizi subtitle "yapay zeka" olarak değiştirildi; backend hata
  mesajlarındaki Gemini referansları temizlendi
- **AI sohbet balonu**: Sol aksent border eklendi (görsel ayrım); balon sağ/sol
  dış boşluğu `xxl → xs/sm` olarak küçültüldü (ekran genişliği daha iyi kullanımı);
  markdown paragraf font boyutu `bodyLarge` olarak güncellendi
- **Ana sayfa kart düzeni**: Kart arası boşluk `xl(32) → md(16)`, iç dikey dolgu
  `xl(32) → lg(24)` küçültüldü; başlık font boyutları dengelendi (HugeCard 24→20,
  AICard 24→22); subtitle `maxLines` 3→2 ile kart yükseklikleri normalize edildi;
  "AI Eczacı Asistanı" → "Eczacı Asistanı" olarak düzenlendi
- **Fotoğraftan tara ekranı**: Boş durum ikon boyutu 80→72, opaklık 0.3→0.5;
  açıklama metni `titleMedium → bodyLarge`; "Galeriden Seç" ve "Fotoğraf Çek"
  butonları `AppButton` ile değiştirildi; gereksiz büyük buton stilleri kaldırıldı
- **Etkileşim ekranı**: Geçmiş ilaç önerileri (ActionChip) alt kart yerine input
  kartının içine taşındı; alt "Önceki ilaçlar" kartı kaldırıldı
- **Hatırlatıcı form**: "Hatırlatma saati" ve "Her dozda kaç tablet" bölüm
  başlıkları kaldırıldı (kendi etiketleri yeterli); "Hatırlatıcı aktif olsun"
  başlığı → "Ayarlar" olarak güncellendi
- **Semptom Analizi ekranı**: AppBar arka plan hardcoded teal → `colorScheme.surface`
  (uygulama geneli tutarlılık); "Analiz Et" butonu `search_rounded →
  monitor_heart_rounded`; "Olası Nedenler" kart ikonu `search → manage_search_rounded`
- **Nöbetçi Eczane ekranı**: `FilledButton` / `OutlinedButton` bileşenleri
  `AppButton` ile değiştirildi (arama, konum izin dialog, hata yeniden dene, harita
  bottom sheet); fallback banner yalnızca ilçe seçiliyken gösterilecek şekilde
  düzeltildi
- **Aile profili**: `_MemberEditorSheet` → `FamilyMemberEditorSheet` (public) olarak
  yeniden adlandırıldı; family_screen ve detail_screen ortak kullanabiliyor
- **Aile bireyine ilaç kartı (DrugTile)**: Ham metin yerine ikonlu etiket chip'leri
  (doz: `medication_rounded`, sıklık: `schedule_rounded`); notes alanı italik
  gösteriliyor; boş durum ve kaydet butonları `AppButton`'a geçirildi
- **Acil Durum Kartı — kan grubu alanı**: Serbest `AppTextField` → 8 standart
  seçenekli `DropdownButtonFormField` (`A Rh+` … `0 Rh-`); mevcut veriler boşluk
  ve büyük/küçük harf fark gözetmeksizin eşleştiriliyor
- **Acil Durum Kartı — AppBar aksiyonları**: Görüntüleme modunda "Düzenle" butonu
  metin+ikon yerine ikon-only (`Icons.edit_rounded`) yapıldı; QR + Paylaş + Düzenle
  birlikte gelince başlık "Acil Dur..." olarak kesiliyordu
- **Çıkış Yap butonu**: Hata rengi (`danger` variant) ile yıkıcı aksiyon vurgusu
  sağlandı; Aile Profili AppBar rengi `primary → surface` ile diğer ekranlarla
  tutarlı hale getirildi
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
- **HomePage AppBar**: Arka plan `colorScheme.primary`'den `colorScheme.surface`'e
  alındı; başlık primary rengiyle vurgulanıyor; dark mode'da açık yeşil arka plan
  kontrast sorunu giderildi
- **Aksiyon kartları chevron**: İkon boyutu 36'dan 28'e indirildi; uzun çeviriler
  artık tam okunabilir
- **Hesap ayarları**: Ham `TextFormField` / `ElevatedButton` / `OutlinedButton`
  yerine `AppTextField`, `AppButton` ve `AppSpacing` token'ları kullanılıyor
- **Backend config.py**: `DEBUG=False` ile varsayılan `JWT_SECRET_KEY` aynı anda
  kullanıldığında uygulama başlatmayı reddeden `model_validator` eklendi
- **docker-compose.yml**: `healthcheck` (pg_isready + redis-cli ping),
  `service_healthy` bağımlılık koşulu, servis portları `127.0.0.1`'e bağlandı,
  özel ağ ve `redis_data` volume eklendi
- **Dockerfile**: Non-root kullanıcı (`appuser`), `HEALTHCHECK` talimatı ve
  `WORKERS` ortam değişkeni eklendi
- **`/health` endpoint'i**: Redis ping kontrolü + buna göre `200`/`503` durum
  kodu döndürme eklendi
- **Backend rate limiter**: `_resolve_client_key` ile X-Forwarded-For desteği;
  `forgot-password` endpoint'i rate limit kapsamına alındı; dict 5000 girişi
  aşınca bayat IP kayıtları otomatik temizleniyor
- **Semptom Analizi kartı (home_page)**: İkon `health_and_safety_rounded` →
  `psychology_rounded`, renk `0xFF00897B` → `0xFF1565C0` (derin mavi); Sağlık
  Notları kartı ikon `note_alt_rounded`, renk `0xFF5D4037` (kahverengi) olarak
  güncellendi; aile kartıyla çakışma giderildi

### Düzeltildi
- **Gemini 5xx hatalarında otomatik yeniden deneme**: `_post_gemini_request`'e
  üstel geri çekilme (exponential backoff) ile 3 deneme mantığı eklendi (1 s
  ve 2 s bekleme); geçici 500/503 hatalarında semptom analizi ve etkileşim
  ekranları artık 502 yerine başarılı sonuç döndürüyor
- **Çıkış Yap → login yönlendirmesi**: Logout sonrası `GoRouter` ile manuel
  `redirect` tetiklendi; `refreshListenable` olmadığından `Navigator.of(context)`
  ile bottom sheet güvenli kapatılıyor
- **AppButton — görünmez metin**: Özel `color` parametresi verildiğinde ön plan
  rengi (`fg`) arka plan rengiyle aynı oluyordu; `color != null ? Colors.white :
  cs.onPrimary` ile düzeltildi; etkilenen tüm ekranlar (Sağlık Notları kaydet,
  Etkileşim kaydet vb.) artık metin gösteriyor
- **Acil Durum Kartı — QR koyu tema**: `QrImageView`'a `backgroundColor:
  Colors.white` ve `color: Colors.black` eklendi; önceki `Colors.black87` koyu
  arka planda QR okunmaz hale geliyordu
- **Sağlık Notları — kaydet butonu metni**: Hardcoded `color: Color(0xFF1565C0)`
  kaldırıldı; AppButton tema rengiyle tutarlı; metin artık görünür
- **Sağlık Notları — FilterChip / SwitchListTile**: Hardcoded `Color(0xFF1565C0)`
  `colorScheme.primary`'ye taşındı; `activeThumbColor` kaldırılarak tema varsayılanı
  kullanılıyor
- **Sağlık Notları — boş durum resmi**: `ClipRRect(borderRadius: 20)` ile
  sarıldı; koyu temada beyaz arka plan resmin kenarlarını vurguluyor sorunu giderildi
- **Tarama geçmişi — boş durum resmi**: `ColorFiltered` + `BlendMode.multiply`
  ile koyu temada beyaz arka plan görsel olarak gizlendi
- **Aile bireyine ilaç ekleme ekranı**: Detail screen AppBar'a düzenle (edit)
  butonu eklendi; üye düzenleme artık liste ekranı yerine detay ekranından
  doğrudan erişilebilir
- **Nöbetçi Eczane — fallback banner**: İlçe seçilmemişken yanlış gösteriliyordu;
  koşul ilçe seçili + fallback birlikte gerekli olacak şekilde düzeltildi
- **Kara ekran**: `SessionListenerWrapper` `ConsumerStatefulWidget`'a çevrildi;
  `initState`'te `addPostFrameCallback` ile mevcut session okunup native splash
  garantili kaldırılıyor; önceki `ref.listen` yaklaşımı ilk state'i kaçırıyordu
- **`SkeletonWrapper` global builder'dan kaldırıldı**: Skeletonizer, navigator
  child'ını `SizedBox.shrink` ile sarıp rota ağacının render olmasını
  engelliyordu; skeleton state artık her ekranın kendi yükleme mantığına bırakıldı
- **Backend TOCTOU — `auth_service`**: E-posta benzersizlik kontrolü ve insert
  işlemi artık tek `RLock` kapsamında atomik; eş zamanlı iki istek aynı hesabı
  oluşturamaz
- **Backend TOCTOU — `profile_service`**: Tüm CRUD operasyonları (create, update,
  delete, add_drug, remove_drug) `RLock` ile korundu; oku-değiştir-yaz döngüsü
  atomik
- **Backend DoS — görsel yükleme**: `analyze-image` ve `prospectus` endpoint'leri
  10 MB boyut sınırıyla korundu (`_read_upload_with_size_check` yardımcısı)
- **Backend — `DrugInteractionRequest`**: `drugs` listesindeki her öğeye ayrıca
  `max_length=200` eklendi (önceden liste boyutu sınırlanıyordu ama öğeler sınırsızdı)
- **Signup ekranı**: 'Zaten hesabınız var mı?' bağlantısı yanlış çeviri anahtarı
  (`auth.sign_up`) kullanıyordu; `auth.sign_in` olarak düzeltildi
- **Login ekranı**: İşlevsiz 'Beni Hatırla' checkbox (`value: true`, no-op
  `onChanged`) kaldırıldı; 'Şifremi Unuttum' butonu sağa hizalandı
- **Hata mesajları**: `error_handler.dart` DioException mesajları ve
  `task_runner.dart` internet bağlantısı mesajı Türkçeye çevrildi
- **Nöbetçi eczane dropdown**: `DropdownButtonFormField.value` deprecated API'den
  `initialValue + ValueKey` düzenine geçildi
- **Drug foto tarama**: Hardcoded Türkçe metin yerine `drug_search.image_empty_subtitle`
  çeviri anahtarı kullanılıyor
- **Backend: Gemini 429 kota hatası**: API 429 döndürdüğünde ham hata yerine
  anlamlı 503 + Türkçe mesaj iletilir
- **Sağlık notu editörü**: Klavye açıkken "Kaydet" butonu artık görünür;
  `SafeArea` + `viewInsets.bottom` sarmalayıcı ile klavye-üstü düzen sağlandı
- **Boş durum ekranı taşma**: `_EmptyNotesState` overflow sorunu giderildi
- **Markdown render**: İlaç detay, ilaç etkileşim ve semptom analizi ekranlarında
  AI yanıtları `flutter_markdown_plus` ile düzgün render edilir hale getirildi
- **Nöbetçi eczane ilçe dropdown**: `pharmacy.all_districts` çeviri anahtarı
  `DropdownMenuItem` ilk render'ında ham key olarak görünüyordu; `value: null →
  value: ''` sentinel değişikliği ve `Builder` sarmalayıcı ile düzeltildi
- **Backend ilçe scraping**: "İlçe Seç" sidebar container kısıtlaması bazı
  illerde eksik sonuç veriyordu; tam sayfa taramaya geçilerek eksiksiz liste
  sağlandı
- **Nöbetçi eczane — "Tüm ilçe" çevirisi**: `tr.json`'da `all_districts` değeri
  "Tüm il" yerine "Tüm ilçe" olarak düzeltildi

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

### Eklendi
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
