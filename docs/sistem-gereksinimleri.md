# Sistem Gereksinimleri

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Sürüm:** 1.2.0
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Aktörler ve Kullanım Bağlamı](#1-aktörler-ve-kullanım-bağlamı)
2. [Fonksiyonel Gereksinimler](#2-fonksiyonel-gereksinimler)
3. [Fonksiyonel Olmayan Gereksinimler](#3-fonksiyonel-olmayan-gereksinimler)
4. [Kullanım Senaryoları (Use Case)](#4-kullanım-senaryoları-use-case)
5. [Veri Gereksinimleri](#5-veri-gereksinimleri)
6. [Arayüz Gereksinimleri](#6-arayüz-gereksinimleri)
7. [Kısıtlar ve Varsayımlar](#7-kısıtlar-ve-varsayımlar)

---

## 1. Aktörler ve Kullanım Bağlamı

### 1.1 Birincil Aktörler

| Aktör | Tanım |
|---|---|
| **Kayıtlı Kullanıcı** | Hesap oluşturmuş, JWT token ile kimlik doğrulaması yapılmış kullanıcı |
| **Misafir Kullanıcı** | Hesap açmadan uygulamayı kullanan kişi; yalnızca yerel özellikler erişilebilir |
| **Bakım Veren** | Aile üyesi adına ilaç listesi yöneten kullanıcı |

### 1.2 İkincil Aktörler

| Aktör | Tanım |
|---|---|
| **Gemini API** | Google AI Studio'nun yapay zekâ servisi; ilaç bilgisi, görsel analiz ve sohbet üretimi |
| **eczaneler.gen.tr** | Nöbetçi eczane verisinin HTML scraping ile çekildiği üçüncü taraf site |
| **Nominatim (OSM)** | GPS koordinatlarını il/ilçe adına dönüştüren coğrafi kodlama servisi |
| **FCM / Yerel Bildirim** | Cihaz üzerinde çalışan ilaç hatırlatıcı ve stok uyarı sistemi |

### 1.3 Sistem Bağlamı

```
Mobil Uygulama (Flutter)
    │
    ├── Yerel Depolama (Hive, FlutterSecureStorage)
    │       · Acil kart, sağlık notları, hatırlatıcı, geçmiş
    │
    └── Backend API (FastAPI)
            │
            ├── Kimlik Doğrulama (JWT + dosya tabanlı kullanıcı deposu)
            ├── Aile Profili (PostgreSQL)
            │
            └── Gemini API (Google AI Studio)
            └── eczaneler.gen.tr (HTML scraping)
            └── Nominatim API (OpenStreetMap)
```

---

## 2. Fonksiyonel Gereksinimler

### FR-01 Kimlik Doğrulama ve Hesap Yönetimi

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-01.1 | Kullanıcı e-posta ve şifre ile kayıt olabilmelidir | Kritik |
| FR-01.2 | Kullanıcı e-posta ve şifre ile giriş yapabilmelidir | Kritik |
| FR-01.3 | Oturum JWT token ile yönetilmelidir; token süresi 7 gündür | Kritik |
| FR-01.4 | Kullanıcı şifresi güncellenebilmelidir (mevcut şifre doğrulamasıyla) | Yüksek |
| FR-01.5 | Kullanıcı çıkış yapabilmelidir (istemci taraflı token silme) | Yüksek |
| FR-01.6 | Şifremi unuttum akışı için e-posta ile doğrulama desteği | Orta |

### FR-02 İlaç Arama (Metin)

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-02.1 | Kullanıcı ilaç adı yazarak arama yapabilmelidir (min 2, maks 200 karakter) | Kritik |
| FR-02.2 | Sistem, Gemini AI ile ilaç adı, etken madde, endikasyon, dozaj, yan etkiler, uyarılar ve kontrendikasyon içeren JSON yanıt üretmelidir | Kritik |
| FR-02.3 | Sesli arama ile metin girişi desteklenmelidir | Yüksek |
| FR-02.4 | Arama sonuçları yerel geçmişe kaydedilmelidir | Yüksek |
| FR-02.5 | Aynı ilaç için tekrarlanan sorgular Redis/bellek önbellekten karşılanmalıdır (TTL: 24 saat) | Yüksek |
| FR-02.6 | IP başına dakikada en fazla 10 arama isteği kabul edilmelidir | Yüksek |

### FR-03 Görsel İlaç Tanıma

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-03.1 | Kullanıcı kamera ile ilaç fotoğrafı çekebilmeli veya galeriden seçebilmelidir | Kritik |
| FR-03.2 | Yüklenen görsel maks. 10 MB, yalnızca `image/*` MIME türleri kabul edilmelidir | Kritik |
| FR-03.3 | Görsel istemci tarafında 1400×1400 piksel ve %82 JPEG kalitesiyle optimize edilmelidir | Yüksek |
| FR-03.4 | Sistem Gemini multimodal API ile ilaç adı ve aday listesi döndürmelidir | Kritik |
| FR-03.5 | Birden fazla ilaç adayı varsa kullanıcıya seçim ekranı sunulmalıdır | Yüksek |
| FR-03.6 | Tarama sonuçları yerel geçmişe kaydedilmelidir | Orta |

### FR-04 Prospektüs Özetleme

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-04.1 | Kullanıcı prospektüs veya kutu görseli yükleyebilmelidir | Yüksek |
| FR-04.2 | Sistem görselden: ilaç adı, kullanım, nasıl kullanılır, yan etkiler, saklama koşulları, dikkat edilecekler ve doktora başvurma durumları alanlarını çıkarmalıdır | Yüksek |
| FR-04.3 | Belirsiz metinlerde model "bilgi okunamadı" döndürmeli; uydurmamalıdır | Kritik |

### FR-05 İlaç Etkileşim Analizi

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-05.1 | Kullanıcı en az 2, en fazla 20 ilaç ismi girebilmelidir | Yüksek |
| FR-05.2 | Sistem her ilaç çifti için risk seviyesi (düşük/orta/yüksek) ve açıklama döndürmelidir | Yüksek |
| FR-05.3 | Genel risk seviyesi özetiyle birlikte dikkat edilmesi gerekenler listesi sunulmalıdır | Yüksek |

### FR-06 Doğal Alternatifler

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-06.1 | Kullanıcı bir ilaç adı girerek doğal destek seçeneklerini sorgulayabilmelidir | Orta |
| FR-06.2 | Sistem bitkisel, beslenme ve yaşam tarzı kategorilerinde alternatifler listesi döndürmelidir | Orta |
| FR-06.3 | Her öneri için dikkat notu ve "ilaç tedavisinin yerini almaz" uyarısı bulunmalıdır | Kritik |

### FR-07 Yapay Zekâ Eczacı Sohbeti

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-07.1 | Kullanıcı ilaç ve sağlık konularında sohbet tabanlı sorgulama yapabilmelidir | Yüksek |
| FR-07.2 | Sohbet, önceki mesajları bağlam olarak içermelidir (maks. 50 mesaj geçmişi) | Yüksek |
| FR-07.3 | Yanıtlar Markdown biçiminde render edilmelidir | Orta |
| FR-07.4 | Model tıbbi teşhis koymamalı; acil durumlarda 112'ye yönlendirmelidir | Kritik |

### FR-08 Semptom Analizi

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-08.1 | Kullanıcı belirti açıklaması girebilmeli (min 5, maks 2000 karakter) | Yüksek |
| FR-08.2 | Sistem olası nedenleri, tavsiyeleri ve doktora başvurma zamanını döndürmelidir | Yüksek |
| FR-08.3 | Acil belirtiler (göğüs ağrısı, nefes darlığı vb.) tespit edildiğinde `acil_durum: true` ve belirgin uyarı gösterilmelidir | Kritik |

### FR-09 İlaç Hatırlatıcısı ve Stok Takibi

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-09.1 | Kullanıcı ilaç adı, dozaj ve günlük saat(ler) tanımlayarak hatırlatıcı oluşturabilmelidir | Kritik |
| FR-09.2 | Planlanan saatte yerel bildirim gönderilmelidir; internet bağlantısı gerekmemelidir | Kritik |
| FR-09.3 | Bildirimler DND (Rahatsız Etme) modunu aşan alarm kanalı üzerinden gönderilmelidir | Yüksek |
| FR-09.4 | Stok takibi etkinleştirildiğinde "doz aldım" butonu ile stok otomatik azalmalıdır | Yüksek |
| FR-09.5 | Stok düşük eşiğin altına indiğinde ek uyarı bildirimi gönderilmelidir | Yüksek |
| FR-09.6 | Aktif + düşük stoklu hatırlatıcılar listenin en üstüne otomatik sıralanmalıdır | Orta |

### FR-10 Aile Profili Yönetimi

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-10.1 | Kullanıcı birden fazla aile üyesi ekleyebilmeli (ad, ilişki türü, yaş, emoji) | Yüksek |
| FR-10.2 | Her aile üyesi için ilaç listesi (ad, dozaj, frekans, notlar) oluşturulabilmelidir | Yüksek |
| FR-10.3 | Aile üyesi ilaç listesi güncellenebilmeli ve üye silinebilmelidir | Yüksek |
| FR-10.4 | Veriler önce yerel (Hive) kaydedilmeli; arka planda bulut senkronizasyonu yapılmalıdır | Yüksek |
| FR-10.5 | Giriş yapıldığında sunucu verileri yerel depolama ile senkronize edilmelidir | Orta |

### FR-11 Nöbetçi Eczane Bulucu

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-11.1 | Kullanıcı GPS konumuyla veya il/ilçe seçerek nöbetçi eczane arayabilmelidir | Kritik |
| FR-11.2 | GPS kullanıldığında Nominatim ile il/ilçe otomatik tespit edilmelidir | Yüksek |
| FR-11.3 | Eczaneler OSM tabanlı haritada pin olarak gösterilmelidir | Yüksek |
| FR-11.4 | Her eczane için ad, adres, telefon ve mesafe bilgisi sunulmalıdır | Yüksek |
| FR-11.5 | İlçede nöbetçi eczane yoksa il geneline otomatik geri dönüş (fallback) yapılmalıdır | Yüksek |

### FR-12 Sağlık Notları

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-12.1 | Kullanıcı genel, tansiyon, kan şekeri, ağrı, psikoloji ve diğer kategorilerinde not oluşturabilmelidir | Yüksek |
| FR-12.2 | Tansiyon kategorisinde sistolik/diastolik değerler mmHg olarak kaydedilmelidir | Yüksek |
| FR-12.3 | Kan şekeri kategorisinde glukoz değeri mg/dL olarak kaydedilmelidir | Yüksek |
| FR-12.4 | Ağrı kategorisinde 0–10 ölçeğinde ağrı seviyesi kaydedilmelidir | Yüksek |
| FR-12.5 | Not; tarih, ruh hali (emoji), semptom etiketleri ve ilaç alındı mı alanlarını içermelidir | Orta |
| FR-12.6 | Ölçüm değerleri zaman çizgisi grafiği olarak görselleştirilmelidir | Orta |
| FR-12.7 | Notlar takvim görünümünde tarih bazlı gösterilmelidir | Orta |
| FR-12.8 | Tüm sağlık notu verisi yalnızca cihazda saklanmalıdır; sunucuya gönderilmemelidir | Kritik |

### FR-13 Acil Durum Kartı

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-13.1 | Kullanıcı kan grubu, alerji, kronik hastalık, güncel ilaçlar, acil kişi ve doktor bilgisi girebilmelidir | Yüksek |
| FR-13.2 | Kart içeriği QR kod olarak görüntülenebilmeli ve paylaşılabilmelidir | Yüksek |
| FR-13.3 | Kart verisi yalnızca cihazda saklanmalıdır; sunucuya gönderilmemelidir | Kritik |

### FR-14 Onboarding

| Kod | Gereksinim | Öncelik |
|---|---|---|
| FR-14.1 | İlk açılışta 3 sayfalık tanıtım akışı gösterilmelidir | Orta |
| FR-14.2 | Onboarding tamamlandıktan sonra bir daha gösterilmemelidir | Orta |

---

## 3. Fonksiyonel Olmayan Gereksinimler

### NFR-01 Performans

| Kod | Gereksinim |
|---|---|
| NFR-01.1 | Önbelleklenmiş ilaç sorgusu 100 ms altında yanıt vermelidir |
| NFR-01.2 | Gemini API çağrısı için istemci tarafı timeout 30 saniyedir |
| NFR-01.3 | Görsel analiz isteği gönderilmeden önce optimize edilmeli; ağ yükü en aza indirilmelidir |
| NFR-01.4 | Uygulama soğuk başlatması 3 saniyenin altında tamamlanmalıdır (yerel veriler için) |

### NFR-02 Güvenilirlik

| Kod | Gereksinim |
|---|---|
| NFR-02.1 | Gemini API geçici hata döndürdüğünde sistem üssel geri çekilme ile en fazla 3 kez yeniden denemelidir |
| NFR-02.2 | Redis erişilemez olduğunda sistem bellek içi cache ile çalışmaya devam etmelidir (graceful degradation) |
| NFR-02.3 | İlaç hatırlatıcıları internet bağlantısı olmadan çalışmalıdır |
| NFR-02.4 | Uygulama güncellemesi sonrasında bildirimler yeniden planlanmalıdır |

### NFR-03 Güvenlik

| Kod | Gereksinim |
|---|---|
| NFR-03.1 | Kimlik doğrulama JWT HS256 ile yapılmalıdır; production'da varsayılan secret kullanılmamalıdır |
| NFR-03.2 | Auth endpoint'leri IP başına dakikada en fazla 20 istekle sınırlandırılmalıdır |
| NFR-03.3 | İlaç arama endpoint'i IP başına dakikada en fazla 10 istekle sınırlandırılmalıdır |
| NFR-03.4 | Production'da CORS yalnızca izin verilen origin'lere açık olmalıdır |
| NFR-03.5 | JWT token FlutterSecureStorage ile şifreli saklanmalıdır |
| NFR-03.6 | Görüntü yüklemelerinde boyut (maks. 10 MB) ve MIME türü doğrulaması yapılmalıdır |

### NFR-04 Kullanılabilirlik

| Kod | Gereksinim |
|---|---|
| NFR-04.1 | Uygulama Türkçe ve İngilizce dillerini desteklemelidir |
| NFR-04.2 | Sistem ThemeMode.system desteğiyle açık/koyu tema sunmalıdır |
| NFR-04.3 | Tüm ekranlar farklı ekran boyutlarında (4"–7") düzgün görüntülenmelidir |
| NFR-04.4 | Ağ gecikmelerinde iskelet (skeleton) yükleme animasyonu gösterilmelidir |

### NFR-05 Ölçeklenebilirlik

| Kod | Gereksinim |
|---|---|
| NFR-05.1 | Backend Docker Compose ile container'a alınabilmelidir |
| NFR-05.2 | Yapılandırma değerleri hardcode edilmemeli; ortam değişkenleri (.env) ile yönetilmelidir |
| NFR-05.3 | Önbellek katmanı Redis ile dağıtılmış ortama taşınabilir olmalıdır |

### NFR-06 Sürdürülebilirlik

| Kod | Gereksinim |
|---|---|
| NFR-06.1 | Mobil taraf feature-first Clean Architecture ile geliştirilmelidir |
| NFR-06.2 | Her feature modülü bağımsız birim testine tabi olabilmelidir |
| NFR-06.3 | Yapay zekâ prompt'ları merkezi bir dosyada (gemini_service.py) tutulmalıdır |

---

## 4. Kullanım Senaryoları (Use Case)

### UC-01: İlaç Arama

```
Aktör     : Kayıtlı veya Misafir Kullanıcı
Ön koşul  : Uygulama açık, internet bağlantısı var
Ana akış  :
  1. Kullanıcı arama ekranını açar
  2. İlaç adını yazar (veya mikrofona söyler)
  3. Sistem önbelleği kontrol eder
  4a. Önbellekte bulunursa → sonuç anında gösterilir
  4b. Bulunamazsa → rate limit kontrolü → Gemini API çağrılır
  5. Sonuç gösterilir; geçmişe kaydedilir
Olası sorunlar:
  - Rate limit aşıldı → "Çok fazla istek" uyarısı
  - Gemini API yanıt vermiyor → retry (3 kez) → hata mesajı
```

### UC-02: Fotoğrafla İlaç Tanıma

```
Aktör     : Kullanıcı
Ön koşul  : Kamera izni verilmiş, internet bağlantısı var
Ana akış  :
  1. Kullanıcı kamera veya galeri ile görsel seçer
  2. Görsel optimize edilir (1400px, JPEG %82)
  3. Backend'e multipart/form-data olarak gönderilir
  4. Gemini multimodal analiz yapar
  5a. Tek ilaç → ilaç detay ekranı
  5b. Çoklu aday → seçim listesi gösterilir
  6. Kullanıcı seçer → detay ekranına geçer
  7. Tarama geçmişe kaydedilir
```

### UC-03: İlaç Hatırlatıcısı Oluşturma

```
Aktör     : Kullanıcı
Ön koşul  : Bildirim izni verilmiş
Ana akış  :
  1. Kullanıcı yeni hatırlatıcı ekler
  2. İlaç adı, dozaj, hatırlatıcı saatler girilir
  3. İsteğe bağlı stok takibi etkinleştirilir
  4. Hatırlatıcı Hive'a kaydedilir
  5. Belirlenen saatler için yerel bildirimler planlanır
  6. Stok düşük eşiğinin altına inince ek bildirim planlanır
```

### UC-04: Nöbetçi Eczane Bulma

```
Aktör     : Kullanıcı
Ön koşul  : İnternet bağlantısı var
Ana akış  :
  1. Eczane haritası açılır
  2a. GPS butonu → konum alınır → Nominatim ile il/ilçe tespit edilir
  2b. Manuel seçim → il/ilçe açılır listeden seçilir
  3. Backend eczaneler.gen.tr'den HTML çeker ve ayrıştırır
  4. Eczaneler haritada pin olarak gösterilir
  5. Pin'e tıklanır → ad, adres, telefon, mesafe paneli açılır
  6. Telefon numarasına tıklanır → arama başlatılır
```

### UC-05: Sağlık Notu Ekleme

```
Aktör     : Kullanıcı
Ön koşul  : Uygulama açık (internet gerekmez)
Ana akış  :
  1. Sağlık notları ekranı açılır
  2. Kategori seçilir (tansiyon, kan şekeri vb.)
  3. Ölçüm değerleri ve not metni girilir
  4. Ruh hali ve semptom etiketleri seçilir
  5. Not cihazda Hive'a kaydedilir
  6. Grafik ve takvim görünümü güncellenir
```

---

## 5. Veri Gereksinimleri

### 5.1 Yerel Veri (Cihaz — Hive)

| Veri | Hive Anahtarı | Hassasiyet |
|---|---|---|
| İlaç arama geçmişi | `drug_search_history` | Düşük |
| İlaç tarama geçmişi | `drug_scan_history` | Düşük |
| Hatırlatıcılar | `medication_reminders_v1` | Orta |
| Sağlık notları | `health_notes` | Yüksek |
| Acil kart | `emergency_card` | Çok Yüksek |
| Aile üyeleri (yerel kopya) | `family_members` | Orta |

### 5.2 Bulut Veri (Backend)

| Veri | Depolama | Erişim Kontrolü |
|---|---|---|
| Kullanıcı hesabı | JSON dosyası (geliştirme) / PostgreSQL | JWT |
| Aile üyeleri ve ilaç listesi | PostgreSQL | JWT, user_id bazlı izolasyon |

### 5.3 Geçici Veri (Cache)

| Veri | Depolama | TTL |
|---|---|---|
| İlaç arama sonuçları | Redis + bellek içi dict | 24 saat |

---

## 6. Arayüz Gereksinimleri

### 6.1 Mobil Uygulama

- **Platform:** Android (min SDK 21) ve iOS (min 12.0)
- **Çerçeve:** Flutter 3.x / Dart ≥ 3.5.0
- **Tasarım sistemi:** Material 3, birincil renk `#00897B` (teal-green)
- **Navigasyon:** GoRouter, 31 tanımlı rota; auth ve onboarding yönlendirme koruması
- **Yerelleştirme:** `easy_localization` ile TR/EN; `assets/translations/` altında JSON dosyaları

### 6.2 Backend API

- **Temel URL:** `http://<host>:8000`
- **Format:** JSON (UTF-8)
- **Yetkilendirme:** `Authorization: Bearer <JWT>` başlığı
- **Swagger UI:** Yalnızca `DEBUG=True` modunda `/docs` ve `/redoc`

### 6.3 Üçüncü Taraf Servis Arayüzleri

| Servis | Protokol | Not |
|---|---|---|
| Gemini API | HTTPS REST | API anahtarı `.env`'de `GEMINI_API_KEY` |
| Nominatim | HTTPS REST | `User-Agent` başlığı zorunlu (OSM politikası) |
| eczaneler.gen.tr | HTTP scraping | `User-Agent` ve `Accept-Language: tr-TR` başlıkları |

---

## 7. Kısıtlar ve Varsayımlar

### 7.1 Teknik Kısıtlar

- **TİTCK API yokluğu:** Türkiye'de resmi ilaç veri tabanına programatik erişim mevcut olmadığından Gemini AI eğitim verisi birincil ilaç bilgisi kaynağı olarak kullanılmaktadır.
- **Gerçek zamanlı nöbet verisi:** Nöbet verileri anlık HTML scraping ile elde edilmektedir; eczaneler.gen.tr HTML yapısı değişirse servis kırılabilir.
- **Gemini API bağımlılığı:** Tüm yapay zekâ özellikleri Google AI Studio API'sine bağımlıdır; servis kesintisi bu özellikleri devre dışı bırakır.

### 7.2 Güvenlik Kısıtları

- Production ortamında `JWT_SECRET_KEY` `.env` dosyasında güçlü bir değerle tanımlanmalıdır; varsayılan değer kullanılması engellenir.
- CORS `allowed_origins`, production'da `*` yerine belirli origin'lere daraltılmalıdır.

### 7.3 Varsayımlar

- Kullanıcıların internet bağlantısına sahip bir Android veya iOS cihaz kullandığı varsayılmaktadır.
- Hatırlatıcı ve sağlık notu gibi yerel özellikler için internet bağlantısı gerekmez.
- Yapay zekâ çıktılarının %100 klinik doğruluğu garanti edilmez; nihai karar insan kontrolüne bırakılır.
- Uygulama kişisel kullanım ölçeği için tasarlanmıştır; yüksek eş zamanlılık gerektiren kurumsal senaryo kapsam dışındadır.
