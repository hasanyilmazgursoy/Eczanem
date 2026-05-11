# Changelog

Bu dosya, projedeki dikkat çeken değişiklikleri kronolojik olarak tutar.

Biçim olarak Keep a Changelog yaklaşımı ve SemVer mantığı referans alınır.

## [Unreleased]

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
