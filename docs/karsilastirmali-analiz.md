# Karşılaştırmalı Analiz

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Sürüm:** 1.2.0
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Giriş](#1-giriş)
2. [Karşılaştırılan Uygulamalar](#2-karşılaştırılan-uygulamalar)
3. [Özellik Matrisi](#3-özellik-matrisi)
4. [Yapay Zekâ Entegrasyonu](#4-yapay-zekâ-entegrasyonu)
5. [Çevrimdışı Yetenek](#5-çevrimdışı-yetenek)
6. [Veri Gizliliği ve Güvenlik](#6-veri-gizliliği-ve-güvenlik)
7. [Yerelleştirme ve Türkiye'ye Özgün Uyum](#7-yerelleştirme-ve-türkiyeye-özgün-uyum)
8. [Teknik Mimari Karşılaştırması](#8-teknik-mimari-karşılaştırması)
9. [Akademik Değerlendirme ve Özgün Katkılar](#9-akademik-değerlendirme-ve-özgün-katkılar)
10. [Sonuç](#10-sonuç)

---

## 1. Giriş

Bu belge, Eczanem uygulamasını benzer alandaki mevcut çözümlerle sistematik biçimde karşılaştırmaktadır. Karşılaştırma; işlevsellik, yapay zekâ entegrasyonu, çevrimdışı yetenek, veri gizliliği, yerelleştirme ve akademik özgünlük boyutlarında gerçekleştirilmiştir.

Sağlık teknolojisi uygulamaları, son yıllarda yapay zekâ ile hızlı bir dönüşüm geçirmektedir. Ancak Türkiye pazarına yönelik, tam Türkçe desteği olan, AI destekli ve çevrimdışı çalışabilen bütünleşik bir ilaç yönetim uygulaması henüz yaygınlaşmamıştır. Eczanem bu boşluğu doldurmak amacıyla tasarlanmıştır.

---

## 2. Karşılaştırılan Uygulamalar

### 2.1 Ada Health

**Tür:** Yapay Zekâ destekli semptom değerlendirme
**Platform:** iOS, Android, Web
**Geliştirici:** Ada Health GmbH (Almanya)
**Odak:** Semptom analizi, olası tanı listesi üretme, doktor yönlendirmesi

Ada Health, doğal dil semptom girişini yapılandırılmış tıbbi karar ağaçlarıyla birleştiren kural-tabanlı + makine öğrenimi hibrit mimarisi kullanmaktadır. FDA'nın SaMD (Software as Medical Device) sınıfına dahildir.

### 2.2 Eczane.net Mobil Uygulaması

**Tür:** Nöbetçi eczane arama ve ilaç rehberi
**Platform:** iOS, Android
**Geliştirici:** Eczane.net
**Odak:** Türkiye'deki nöbetçi eczaneleri konum bazlı listeleme; ilaç prospektüs bilgisi

### 2.3 TİTCK Türkiye İlaç ve Tıbbi Cihaz Kurumu Uygulaması

**Tür:** Resmi ilaç bilgi ve sorgulama
**Platform:** iOS, Android
**Geliştirici:** T.C. Sağlık Bakanlığı
**Odak:** Onaylı ilaç listesi, karekod ile ilaç doğrulama, geri çekilen ürünler

### 2.4 Medisafe

**Tür:** İlaç hatırlatma ve takip
**Platform:** iOS, Android
**Geliştirici:** Medisafe Inc. (ABD)
**Odak:** İlaç hatırlatıcıları, stok takibi, aile paylaşımı, ilaç etkileşim uyarıları

---

## 3. Özellik Matrisi

| Özellik | Eczanem | Ada Health | Eczane.net | TİTCK | Medisafe |
|---|:---:|:---:|:---:|:---:|:---:|
| **İlaç arama (metin)** | ✅ | ❌ | ✅ | ✅ | ❌ |
| **Görüntüden ilaç tanıma** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Prospektüs özetleme (AI)** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **İlaç etkileşim analizi** | ✅ | ❌ | ❌ | ❌ | ✅ (sınırlı) |
| **Semptom analizi** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Doğal alternatif önerileri** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Sağlık asistanı chatbot** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **İlaç hatırlatıcı** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Stok takibi** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **DND bypass alarm** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Nöbetçi eczane haritası** | ✅ | ❌ | ✅ | ❌ | ❌ |
| **Sağlık günlüğü** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Acil durum kartı** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Aile profilleri** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Tam Türkçe destek** | ✅ | ⚠️ (kısmi) | ✅ | ✅ | ❌ |
| **Çevrimdışı temel işlevler** | ✅ | ❌ | ❌ | ❌ | ✅ (sınırlı) |
| **Açık kaynak** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Ücretsiz / reklamsız** | ✅ | ⚠️ (freemium) | ✅ | ✅ | ⚠️ (freemium) |

> **Lejant:** ✅ Destekli, ❌ Desteklenmiyor, ⚠️ Kısmi / koşullu destek

---

## 4. Yapay Zekâ Entegrasyonu

### 4.1 Eczanem — Gemini 2.5 Flash

Eczanem, Google'ın Gemini 2.5 Flash modelini büyük dil modeli (LLM) altyapısı olarak kullanmaktadır. Yedi farklı AI endpoint sunulmaktadır:

| Endpoint | AI Kullanımı |
|---|---|
| `POST /api/drug/search` | İlaç profili üretimi (endikasyon, yan etki, uyarılar) |
| `POST /api/drug/analyze-image` | Görüntüden ilaç adı tanıma, aday ilaç çıkarımı |
| `POST /api/drug/prospectus` | Uzun prospektüs metnini yapılandırılmış özete dönüştürme |
| `POST /api/drug/interaction` | Çoklu ilaç etkileşim analizi (2–20 ilaç) |
| `POST /api/drug/natural-alternatives` | Bitkisel ve doğal ilaç alternatifleri |
| `POST /api/drug/chat` | Çok turlu ilaç danışma chatbot |
| `POST /api/drug/symptom-check` | Semptom değerlendirme + acil durum tespiti |

**Güvenlik önlemleri:** `temperature=0.3` (düşük rastgelelik → tutarlı klinik yanıt), exponential backoff (2^n saniye, 3 deneme), JSON payload ayrıştırma güvenlik katmanı (`_extract_json_payload`), ilaç arama için IP tabanlı rate limiting (60s pencerede maks. 10 istek).

### 4.2 Ada Health — Hibrit Kural + ML

Ada Health, ISO 13485 sertifikalı tıbbi cihaz yazılımı sınıfında değerlendirilmektedir. Semptom girişi yapılandırılmış soru-cevap akışıyla gerçekleştirilir; serbest metin girişi sınırlıdır. Gemini gibi genel amaçlı LLM kullanmaz; özelleştirilmiş tıbbi karar ağaçları ve klinik veri tabanları üzerinde eğitilmiş modeller kullanır.

**Fark:** Ada Health bir tanı destek sistemidir. Eczanem bir ilaç yönetim asistanıdır. İki uygulama birbirini tamamlar; Ada tanıyı destekler, Eczanem sonrasında ilaç yönetimini üstlenir.

### 4.3 Diğer Uygulamalar

Eczane.net, TİTCK ve Medisafe uygulamaları mevcut durumda büyük dil modeli veya görüntü tabanlı AI özellikleri sunmamaktadır.

---

## 5. Çevrimdışı Yetenek

| Özellik | Eczanem | Ada Health | Eczane.net | TİTCK | Medisafe |
|---|---|---|---|---|---|
| İlaç hatırlatıcıları | ✅ Tam çevrimdışı | — | — | — | ✅ Tam çevrimdışı |
| Acil durum kartı görüntüleme | ✅ Hive local | — | — | — | — |
| Sağlık notları görüntüleme | ✅ Hive local | — | — | — | — |
| Tarama geçmişi görüntüleme | ✅ Hive local | — | — | — | — |
| İlaç arama | ❌ AI gerektirir | ❌ | ❌ | ⚠️ Cache | ❌ |
| Nöbetçi eczane | ❌ Ağ gerektirir | — | ❌ | — | — |

Eczanem'in yerel depolama mimarisi (Hive + FlutterSecureStorage), internet bağlantısı olmaksızın temel sağlık bilgilerine erişimi garantiler. Kritik verilerin (hatırlatıcılar, acil kart) ağ kesintisinden etkilenmemesi tasarım gereksinimidir.

---

## 6. Veri Gizliliği ve Güvenlik

### 6.1 Eczanem

- **JWT HS256 kimlik doğrulama:** 7 günlük token, bcrypt parola hashleme
- **Yerel öncelikli mimari:** Sağlık verileri varsayılan olarak cihazda (Hive) tutulur; sunucuya yalnızca aile profilleri senkronize edilir
- **Production güvenlik koruması:** Varsayılan JWT secret tespit edildiğinde uygulama başlamayı reddeder
- **Görüntü güvenliği:** Maks. 10 MB, yalnızca `image/*` MIME tipi kabul edilir; içerik tipi doğrulaması
- **CORS konfigürasyonu:** Production'da belirli domain izni zorunlu
- **Rate limiting:** Auth (20 istek/60s), ilaç arama (10 istek/60s), IP bazlı

### 6.2 Ada Health

CE Mark ve FDA SaMD sınıfına tabi olduğundan GDPR ve HIPAA standartlarına uyum zorunludur. Semptom verisi sunucularda işlenir; yerel işlem yoktur. Avrupa veri merkezleri kullanılır.

### 6.3 TİTCK

T.C. Sağlık Bakanlığı altyapısı; kişisel veri saklamaz (sorgulama bazlı anonim kullanım). KVKK uyumlu.

### 6.4 Medisafe

ABD merkezli; HIPAA politikaları açıkça duyurulur. İlaç alma verisi sunucularda depolanır; üçüncü taraf analitik entegrasyonları bulunmaktadır.

### 6.5 Karşılaştırmalı Özet

| Kriter | Eczanem | Ada Health | TİTCK | Medisafe |
|---|---|---|---|---|
| Yerel veri önceliği | ✅ Yüksek | ❌ Düşük | ✅ Yok (anonim) | ❌ Düşük |
| Sunucuda sağlık verisi | Yalnızca aile profili | Tüm semptom geçmişi | Yok | Tüm ilaç geçmişi |
| Parola hashleme | bcrypt | Bilinmiyor | — | Bilinmiyor |
| Açık kaynak doğrulanabilirlik | ❌ | ❌ | ❌ | ❌ |

---

## 7. Yerelleştirme ve Türkiye'ye Özgün Uyum

### 7.1 Eczanem

- **Tam Türkçe + İngilizce:** `easy_localization` ile `tr.json` / `en.json` iki dil
- **Nöbetçi eczane:** Türkiye'ye özgü nöbetçi sistemi; il/ilçe bazlı sorgulama, BeautifulSoup4 ile eczaneler.gen.tr scraping, `_to_slug` ile Türkçe karakter URL normalizasyonu (`ş → s`, `ğ → g`, `ı → i` vb.)
- **Nominatim OSM:** Konum → il/ilçe tespiti ve eczane koordinat araması Türkçe adreslerle çalışacak şekilde yapılandırılmış
- **Gemini Türkçe:** Tüm AI endpoint'leri Türkçe yanıt üretecek şekilde sistem prompt'larıyla yapılandırılmış
- **TİTCK uyumu:** İlaç bilgisi sunan uyarı mesajları; "Bu bilgiler genel amaçlıdır, doktorunuza danışın" ibaresi

### 7.2 Ada Health

Türkçe arayüz mevcuttur ancak medikal içerik terminolojisi İngilizce kaynaklıdır ve çeviri kalitesi kısmi düzeyde kalabilmektedir. Türkiye nöbetçi eczane sistemi veya TİTCK veritabanıyla entegrasyon yoktur.

### 7.3 Eczane.net

Tamamen Türkçe; Türkiye nöbetçi eczane veri tabanına sahiptir. Ancak AI özellikleri yoktur ve kapsamı yalnızca eczane bulma ile ilaç prospektüsüdür.

### 7.4 TİTCK

Resmi Türkçe; Türkiye ilaç ruhsat veritabanı ve karekod doğrulama sistemi önemli bir güçtür. Ancak ilaç yönetimi, hatırlatıcı veya AI özelliği yoktur.

### 7.5 Medisafe

İngilizce birincil; Türkçe arayüz desteği bulunmamaktadır. Türkiye nöbetçi eczane sistemiyle entegrasyon yoktur.

---

## 8. Teknik Mimari Karşılaştırması

| Mimari Boyut | Eczanem | Ada Health | Eczane.net | Medisafe |
|---|---|---|---|---|
| **Mobil framework** | Flutter (Dart) | React Native | React Native | React Native |
| **State yönetimi** | Riverpod + fpdart | Redux | — | — |
| **Yerel depolama** | Hive (NoSQL K-V) | SQLite | — | SQLite |
| **API backend** | FastAPI (Python) | Özel | PHP/Laravel | Node.js (tahmini) |
| **AI / LLM** | Gemini 2.5 Flash | Özel tıbbi ML | Yok | Yok |
| **Cache katmanı** | Redis + in-memory dict | CDN | — | — |
| **Konteynerizasyon** | Docker Compose | Kubernetes (tahmini) | — | — |
| **Harita motoru** | flutter_map (OSM) | Google Maps | Google Maps | — |

---

## 9. Akademik Değerlendirme ve Özgün Katkılar

### 9.1 Araştırma Boşluğu

Literatür taraması, Türkiye pazarına yönelik şu özellikleri aynı anda sunan herhangi bir uygulamanın bulunmadığını ortaya koymaktadır:

1. Ücretsiz, reklamsız erişim
2. Gemini tabanlı çoklu AI işlevi (tanıma, analiz, sohbet, semptom değerlendirme)
3. Görüntüden ilaç tanıma
4. Tam çevrimdışı temel işlevler (hatırlatıcı, acil kart)
5. Türkiye nöbetçi eczane sistemiyle entegrasyon
6. Yerel öncelikli veri gizliliği mimarisi

### 9.2 Özgün Teknik Katkılar

**1. İki Katmanlı Cache Mimarisi**
Redis önbelleği (birincil) ile in-memory Python dict (yedek) kombinasyonu, Redis kesintisinde performans düşüşünü önler. Cache isabet oranında rate limiting bypass mekanizması, AI maliyetlerini düşürürken kullanıcı deneyimini korur.

**2. Çevrimdışı-Öncelikli Mobil Mimari**
Hive tabanlı yerel veri deposu, Flutter'ın reaktif Riverpod state yönetimiyle birleştirilerek kritik sağlık verilerinin ağsız ortamda tam işlevselliği sağlanmaktadır. Bu yaklaşım, sağlık bilişimi literatüründe "offline-first health app" deseni olarak tanımlanmaktadır.

**3. Acil Durum Tespiti**
`POST /api/drug/symptom-check` endpoint'i, Gemini yanıtını yapılandırılmış JSON'a dönüştürerek `acil_durum: bool` alanını üretir. Bu alan, mobil uygulamada kritik uyarı ekranını tetikler. Metin tabanlı AI çıktısından ikili sınıflandırma üretme, güvenlik açısından önem taşıyan bir mühendislik kararıdır.

**4. Türkçe Karakter Normalizasyonu**
Nöbetçi eczane scraping akışında `_to_slug` fonksiyonu, Türkçeye özgü karakterleri (`ş, ğ, ı, ö, ü, ç`) URL güvenli ASCII'ye dönüştürür. Bu, Python'ın `str.normalize('NFKD')` yaklaşımından farklı olarak her karakter için açık eşleme tablosu kullanır; böylece Türkçeye özgü `ı → i` ve `İ → I` dönüşümleri hatalı normalizasyona karşı korumalıdır.

**5. Railway Oriented Programming**
`fpdart` kütüphanesi ile `FutureEither<Failure, T>` desen kullanımı, hatanın tip sistemine gömülmesini sağlar. Try-catch blokları yerine fonksiyonel kompozisyon tercih edilmektedir. Bu yaklaşım, Dart/Flutter topluluğunda henüz yaygın değildir ve projenin mimari özgünlüğünü desteklemektedir.

### 9.3 Sınırlılıklar ve Gelecek Çalışmalar

| Sınırlılık | Gerekçe | Gelecek Öneri |
|---|---|---|
| Gemini yanıtlarının tıbbi doğruluğu doğrulanmamış | LLM halüsinasyon riski mevcut | TİTCK veritabanıyla yanıt doğrulama katmanı |
| Aile profilleri dosya tabanlı JSON'da | PostgreSQL entegrasyonu tamamlanmamış | Alembic migration + asyncpg ile tam geçiş |
| Görüntü tanıma yalnızca ilaç kutuları | El yazısı reçete tanıma test edilmedi | OCR ön-işleme katmanı |
| Rate limiting yalnızca IP bazlı | VPN kullanımı bypass edebilir | Kullanıcı kimlik bazlı limitleme |
| Çoklu dil yalnızca TR/EN | Türkiye'de Kürtçe, Arapça kullanım var | i18n kapsamının genişletilmesi |

---

## 10. Sonuç

Eczanem, mevcut sağlık uygulamalarının her birinden seçilmiş güçlü yönleri tek bir platformda birleştirmektedir:

- Ada Health'in AI danışma yetenekleri
- Eczane.net'in nöbetçi eczane yerelliği
- TİTCK'in ilaç bilgi odaklılığı
- Medisafe'in hatırlatıcı ve stok yönetimi

Bu kombinasyon, Türkiye kullanıcıları için özelleştirilmiş, çevrimdışı-dayanıklı, yerel öncelikli veri gizliliği anlayışıyla tasarlanmış bütünleşik bir çözüm oluşturmaktadır. Özellikle görüntüden ilaç tanıma ve Türkçe AI tabanlı semptom analizi, pazarda doğrudan rakibi bulunmayan özgün özelliklerdir.

Akademik açıdan ise proje; Railway Oriented Programming, iki katmanlı cache, offline-first sağlık uygulaması ve LLM tabanlı acil durum tespiti konularında pratik bir uygulama örneği sunmaktadır.
