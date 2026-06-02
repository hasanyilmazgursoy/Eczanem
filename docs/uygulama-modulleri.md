# Uygulama Modülleri Rehberi — Özellik Bazlı Açıklamalar

**Proje:** Eczanem — Kişisel İlaç Asistanı
**Kapsam:** Tüm uygulama modülleri, kullanım senaryoları ve faydaları
**Güncelleme Tarihi:** Haziran 2026

---

## İçindekiler

1. [İlaç Arama](#1-ilaç-arama)
2. [Fotoğrafla İlaç Tanıma](#2-fotoğrafla-ilaç-tanıma)
3. [Prospektüs Okuyucu](#3-prospektüs-okuyucu)
4. [İlaç Etkileşim Kontrolü](#4-ilaç-etkileşim-kontrolü)
5. [Doğal Alternatifler](#5-doğal-alternatifler)
6. [Yapay Zekâ Eczacı Sohbeti](#6-yapay-zekâ-eczacı-sohbeti)
7. [Semptom Analizi](#7-semptom-analizi)
8. [İlaç Hatırlatıcısı](#8-ilaç-hatırlatıcısı)
9. [Aile Profili Yönetimi](#9-aile-profili-yönetimi)
10. [Nöbetçi Eczane Bulucu](#10-nöbetçi-eczane-bulucu)
11. [Sağlık Notları](#11-sağlık-notları)
12. [Acil Durum Kartı](#12-acil-durum-kartı)
13. [Arama ve Tarama Geçmişi](#13-arama-ve-tarama-geçmişi)

---

## 1. İlaç Arama

**Route:** `/drug-search` → `/drug-detail`

### Ne Yapar?

Kullanıcının yazarak veya sesli olarak sorduğu ilaç adına karşılık Google Gemini yapay zekâsı aracılığıyla kapsamlı bir ilaç bilgisi raporu üretir.

### Kullanım Senaryoları

- Eczaneden yeni aldığınız bir ilaç hakkında bilgi edinmek
- Yabancı bir ilacın Türkçe karşılığını veya içeriğini öğrenmek
- Bir ilacın dozajı ve kullanım talimatlarını hızlıca kontrol etmek
- Geceleri eczane kapalıyken ilaç bilgisine ihtiyaç duymak

### Sunulan Bilgiler

| Bilgi Alanı | Açıklama |
|---|---|
| **Etken madde** | İlacın aktif bileşeni, kimyasal adı |
| **Endikasyon** | Hangi hastalıklar veya belirtiler için kullanılır |
| **Dozaj ve kullanım** | Nasıl, ne zaman, kaç günlük kullanım |
| **Yan etkiler** | Yaygın ve nadir görülen yan etkiler |
| **Uyarılar** | Alkol, araç kullanımı, hamilelik, emzirme uyarıları |
| **İlaç sınıfı** | Analjezik, antibiyotik, antihipertansif vb. |
| **Sakınımlar** | Kullanılmaması gereken durumlar |
| **Genel tavsiye** | Doktora danışılması gereken durumlar |

### Faydaları

- **Zaman tasarrufu:** Prospektüsü açıp okumak yerine saniyeler içinde özet bilgi
- **Anlaşılır dil:** Tıbbi terimler yerine sade Türkçe açıklamalar
- **7/24 erişim:** Eczane ve doktor çalışma saatlerinden bağımsız
- **Sesli arama:** Yazı yazmak zorunda kalmadan mikrofona söyleyerek sorgulama
- **Geçmiş kaydı:** Daha önce aranan ilaçlara tek tıkla geri dönme

### Teknik Not

Sık sorgulanan ilaçlar Redis önbelleğinde 24 saat saklanır. Önbellekte bulunan sorgular için yapay zekâ API'si çağrılmaz — yanıt anında gelir ve kullanıcı başına istek sınırına sayılmaz.

---

## 2. Fotoğrafla İlaç Tanıma

**Route:** `/drug-photo-scan` → `/drug-camera-capture` → `/drug-image-candidates` → `/drug-detail`

### Ne Yapar?

İlacın kutusunu, blisterini veya şişesini fotoğraflayarak ilacı otomatik tanır ve detaylı bilgi sunar. Aynı görselde birden fazla ilaç adayı tespit edilirse seçim listesi sunulur.

### Kullanım Senaryoları

- İlaç adını okuyamamak veya anımsamamak
- Yazısı silinmiş ya da yabancı dildeki ilaçları tanımak
- Yaşlı bir aile üyesi için ellerindeki ilacı hızlıca tanıtmak
- Birden fazla ilacın aynı anda tanınması (blister paketi)

### Fotoğraf Kaynakları

Uygulama iki farklı görsel kaynağını destekler:

| Kaynak | Açıklama |
|---|---|
| **Kamera** | Uygulama içi kamera önizlemesi ile anlık fotoğraf |
| **Galeri / Dosyalar** | Cihazda daha önce çekilmiş fotoğraf seçimi |

### Aday Seçim Ekranı

Gemini görsel analizi birden fazla ilaç adayı tespit ettiğinde (`/drug-image-candidates`), kullanıcıya liste sunulur ve doğru ilacı seçmesi istenir. Bu sayede belirsiz görsellerde bile doğru sonuca ulaşılır.

### Arka Planda Neler Olur?

```
Fotoğraf çekilir / seçilir
       │
Backend'e gönderilmeden önce optimize edilir:
  · Maksimum 1400×1400 piksel boyutuna küçültülür
  · JPEG formatına %82 kalite ile sıkıştırılır
  · EXIF döndürme bilgisi uygulanır (yan çekilen fotoğraflar düzeltilir)
       │
Optimize görsel Gemini 2.5 Flash'a gönderilir
       │
Model, kutu yazısını, renk kodlarını ve barkod alanını analiz eder
       │
İlaç adı ve aday listesi döner
```

### Faydaları

- **İsim bilmeden tanıma:** Görsel okuma, metin girişi gerektirmez
- **Hızlı tarama:** Çantadaki tüm ilaçları tek tek fotoğraflayarak kataloglamak
- **Yabancı ilaç desteği:** Yurt dışından getirilen ilaçlar da tanınabilir
- **Düşük veri kullanımı:** Görsel optimize edilerek gönderildiği için bant genişliği az kullanılır

---

## 3. Prospektüs Okuyucu

**Route:** `/drug-prospectus-summary`

### Ne Yapar?

İlaç kutusunun içindeki kâğıt prospektüsü veya kutu üzerindeki yazıları fotoğraflayarak, uzun ve karmaşık teknik metni okunabilir kategoriler hâlinde özetler.

### Kullanım Senaryoları

- Çok sayfalı prospektüsü baştan sona okumak yerine özet görmek
- Küçük puntolu baskıları okumakta zorlanan yaşlı kullanıcılar için
- Doktor tarafından önerilen prospektüs bölümlerini hızlıca bulmak
- Yabancı dildeki prospektüs metnini Türkçe özetlemek

### Özet Kategorileri

Yapay zekâ prospektüsü aşağıdaki başlıklar altında düzenler:

| Kategori | İçerik |
|---|---|
| **Ne için kullanılır** | Kısa endikasyon özeti |
| **Nasıl kullanılır** | Doz ve uygulama talimatı |
| **Dikkat edilecekler** | Önemli uyarılar ve kontrendikasyonlar |
| **Yan etkiler** | Yaygın ve ciddi yan etkiler |
| **Saklama koşulları** | Sıcaklık, ışık, nem bilgisi |
| **Özel durumlar** | Hamilelik, emzirme, çocuk, yaşlı notları |

### Faydaları

- **Zaman tasarrufu:** Sayfalar dolusu metin dakikalar yerine saniyeler içinde anlaşılır hâle gelir
- **Erişilebilirlik:** Küçük font boyutu veya yoğun tıbbi dil engeli ortadan kalkar
- **Güvenlik:** Önemli uyarılar öne çıkarılır; gözden kaçırma riski azalır

---

## 4. İlaç Etkileşim Kontrolü

**Route:** `/drug-interaction`

### Ne Yapar?

Aynı anda kullanılan birden fazla ilacın birbirleriyle oluşturabileceği etkileşimleri analiz ederek risk düzeyini ve açıklamasını sunar.

### Kullanım Senaryoları

- Doktor tarafından yeni bir ilaç yazıldığında mevcut ilaçlarla uyumunu kontrol etmek
- Reçetesiz satın alınan ilaçları reçeteli ilaçlarla birlikte kullanmadan önce güvenlik kontrolü
- Vitamin ve takviye ürünlerinin ilaçlarla etkileşimini sorgulamak
- Aile üyeleri için çoklu ilaç güvenlik değerlendirmesi

### Risk Seviyeleri

| Seviye | Renk | Anlam |
|---|---|---|
| **Güvenli** | Yeşil | Bilinen bir etkileşim tespit edilmedi |
| **Dikkat** | Sarı | Hafif etkileşim; doktora danışmak önerilir |
| **Orta Risk** | Turuncu | Doz ayarlaması veya izlem gerekebilir |
| **Yüksek Risk** | Kırmızı | Bu kombinasyon kullanılmamalı; doktora başvurun |

### Sunulan Bilgiler

- Her ilaç çiftinin özel etkileşim açıklaması
- Etkileşimin nasıl ortaya çıktığı (farmakokınetik / farmakodinamik)
- Önerilen eylem (doz ayarlama, alternatif, izlem sıklığı)
- Genel risk değerlendirme özeti

### Faydaları

- **Proaktif güvenlik:** Sorun oluşmadan önce riski görmek
- **Çoklu ilaç desteği:** İkiden fazla ilaç aynı anda analiz edilebilir
- **Anlaşılır sonuç:** Tıbbi jargon olmadan net risk gösterimi

---

## 5. Doğal Alternatifler

**Route:** `/drug-natural-alternatives`

### Ne Yapar?

Kullanılan bir ilaç için bitkisel, beslenme ve yaşam tarzı temelli alternatif veya tamamlayıcı yaklaşımları önerir.

### Kullanım Senaryoları

- İlaç yan etkilerini azaltmak amacıyla destekleyici yöntem arayanlar
- Hafif semptomlar için ilaçsız seçenek merak edenler
- Holistik sağlık yaklaşımını benimseyen kullanıcılar
- Kronik ilaç kullanımını azaltmak isteyen (doktor takibinde) bireyler

### Önerilerin Kapsamı

| Kategori | Örnekler |
|---|---|
| **Bitkisel** | Zencefil, zerdeçal, ekinezya, melisa |
| **Beslenme** | Omega-3, magnezyum, D vitamini, kefir |
| **Yaşam tarzı** | Egzersiz, uyku düzeni, stres yönetimi |
| **Tamamlayıcı tedaviler** | Akupunktur, meditasyon, nefes egzersizleri |

> **Önemli Uyarı:** Bu öneriler ilaç tedavisinin yerini almaz; yalnızca tamamlayıcı bilgi niteliğindedir. Mevcut tedavide değişiklik yapmadan önce doktora danışılması gerekir.

### Faydaları

- **Bütüncül sağlık bakışı:** İlaç bilgisinin ötesinde yaşam tarzı farkındalığı
- **Bilimsel temel:** Yapay zekâ önerileri kanıta dayalı tıp perspektifinden üretilir
- **Kişiselleştirilmiş:** Her ilaç için özgün öneriler, genel sağlık tavsiyeleri değil

---

## 6. Yapay Zekâ Eczacı Sohbeti

**Route:** `/ai-chat`

### Ne Yapar?

İlaçlar, sağlık ve ilaç kullanımı hakkındaki sorulara Markdown formatında, akıcı ve detaylı yanıtlar veren bir sohbet arayüzü sunar. Önceki mesajlar konuşma geçmişi olarak hatırlanır.

### Kullanım Senaryoları

- "Bu ilacı yemekten önce mi, sonra mı almalıyım?" gibi pratik sorular
- Bir ilacın fiyatı veya jenerik karşılıkları hakkında genel bilgi
- Çeşitli sağlık konularında bilgi edinme (uyku, beslenme, kronik hastalık yönetimi)
- Doktor ziyareti öncesinde soru listesi oluşturma

### Sohbet Asistanının Özellikleri

- **Bağlam hafızası:** Aynı konuşma içindeki önceki sorular hatırlanır; "onun yerine ne kullanabilirim?" gibi atıflı sorular anlaşılır
- **Markdown render:** Listeler, kalın metin, tablo ve başlıklar düzgün görüntülenir
- **Sıcak ton:** Resmi olmayan, empatik ve sabırlı bir eczacı üslubu
- **Sorumluluk sınırı:** Tanı koymaz; belirgin rahatsızlıklar için doktora yönlendirir

### Faydaları

- **Erişim kolaylığı:** Küçük bir soru için eczaneye gitmeden yanıt almak
- **Sohbet akışı:** Tek seferlik arama yerine konuşarak derinleştirme imkânı
- **Çeşitli format:** Adım adım talimatlar, karşılaştırma tabloları, önem sıralamaları

---

## 7. Semptom Analizi

**Route:** `/symptom-analysis`

### Ne Yapar?

Kullanıcının tarif ettiği belirtileri analiz ederek olası nedenleri listeler, acil durum gerekip gerekmediğini değerlendirir ve önerilen ilk adımları sunar.

### Kullanım Senaryoları

- Birden fazla belirtinin birlikte neye işaret edebileceğini anlamak
- Acil servise gitmek gerekip gerekmediğini ön değerlendirme
- Hangi uzmana başvurulması gerektiğini öğrenmek
- Belirti takibi için geçmiş kayıt oluşturma (Sağlık Notları ile entegre)

### Analiz Çıktısı

| Bölüm | İçerik |
|---|---|
| **Olası nedenler** | En muhtemelden az muhtemele sıralı liste |
| **Acil durum uyarısı** | Kırmızı bayrak belirtileri varsa öne çıkarılır |
| **Önerilen uzman** | Dahiliye, kardiyoloji, nöroloji vb. yönlendirme |
| **İlk yapılacaklar** | Doktora gitmeden önce uygulanabilecek adımlar |
| **Dikkat edilecek belirtiler** | Durumu kötüleşebilecek sinyal listesi |

### Acil Durum Tespiti

Yapay zekâ göğüs ağrısı + nefes darlığı, ani görme kaybı, bilinç bulanıklığı gibi kritik semptom kombinasyonlarını tespit ettiğinde analiz sonucunun en üstünde belirgin **kırmızı uyarı** gösterir ve acil servise başvuru tavsiyesi verir.

> **Önemli Uyarı:** Bu modül tıbbi teşhis aracı değildir. Semptomlarınız ciddi veya kalıcıysa mutlaka bir sağlık kuruluşuna başvurunuz. Semptom analizi yalnızca genel bilgilendirme amacı taşır.

### Faydaları

- **Panik önleyici:** "Bu ne olabilir ki?" sorusuna sakin, bilimsel bir ilk yanıt
- **Triaj yardımcısı:** Acil mi, beklenir mi, gözlemle mi sorusunu yanıtlar
- **Zaman tasarrufu:** Kaynakça araştırması yerine toplu, güvenilir değerlendirme

---

## 8. İlaç Hatırlatıcısı

**Route:** `/medication-reminders`

### Ne Yapar?

Günlük ilaç kullanımını zamanında hatırlatan, stok takibi yapan ve stok azaldığında uyaran tam özellikli bir ilaç yöneticisidir. İnternet bağlantısı gerektirmez; tamamen cihaz üzerinde çalışır.

### Temel Özellikler

#### Zamanlama

- Günde birden fazla hatırlatıcı saati tanımlanabilir (sabah 08:00, öğle 13:00, gece 22:00)
- Her saat için ayrı bildirim planlanır
- Cihazın saat dilimi otomatik tespit edilir; seyahatlerde saat kayması yaşanmaz

#### Stok Takibi

| Özellik | Açıklama |
|---|---|
| **Başlangıç stoku** | Kutudaki ilaç adedi (örn. 28 tablet) |
| **Doz başına birim** | Her doz alımında düşülecek miktar (örn. 1 tablet) |
| **Düşük stok eşiği** | Bu seviyenin altına inince uyarı (örn. 5 kaldığında) |
| **Doz aldım butonu** | Bir tıkla stok güncelleme ve son doz zamanı kaydetme |

Stok eşiği aşıldığında ayrı bir **"İlaç bitiyor"** bildirimi gönderilir.

#### DND (Rahatsız Etme) Bypass

Kritik ilaçlar için hatırlatıcılar ayrı bir **alarm kanalında** planlanır. Bu kanal Android'in Rahatsız Etme modunu bypass eder; gece alınması gereken ilaçlarda veya yüksek sesli ortamlarda bile bildirim çalar.

#### Sıralama ve Önceliklendirme

Hatırlatıcı listesi şu öncelik sırasına göre otomatik düzenlenir:

1. **Aktif + düşük stoklu** — en üst (acil ilgi gerektirir)
2. **Aktif + normal stok** — zaman sırasına göre
3. **Duraklatılmış hatırlatıcılar** — en alt

### Kullanım Senaryoları

- Unutkanlık nedeniyle atlanan ilaç dozlarını önlemek
- Yaşlı aile üyesi adına hatırlatıcı kurmak
- Birden fazla kronik ilaç kullananlar için düzenli takip
- Antibiyotik gibi belirli gün kürü olan ilaçları eksiksiz tamamlamak
- Stok bitmeden önce eczaneden yeni kutu almayı planlamak

### Faydaları

- **Tedavi uyumu:** Düzenli ilaç kullanımı tedavi etkinliğini doğrudan etkiler; hatırlatıcılar bu uyumu destekler
- **Stok farkındalığı:** Son tablet kaldığında sürpriz yaşanmaz
- **Tamamen çevrimdışı:** İnternet yokken de bildirimler çalışır
- **Sessiz senkronizasyon:** Uygulama her açıldığında bildirimler otomatik yenilenir; güncelleme sonrası kayıp yaşanmaz

---

## 9. Aile Profili Yönetimi

**Route:** `/family` → `/family-member-detail`

### Ne Yapar?

Birden fazla kişi (anne, baba, eş, çocuk vb.) için ayrı ilaç listeleri oluşturmanızı ve yönetmenizi sağlar. Her aile üyesinin düzenli kullandığı ilaçlar, dozajları ve notları tek ekranda görüntülenir.

### Aile Üyesi Kartı İçeriği

| Alan | Açıklama |
|---|---|
| **Ad ve emoji** | Kişiyi temsil eden özelleştirilebilir emoji (👩, 👴, 👶) |
| **Yakınlık derecesi** | Anne, baba, eş, çocuk, büyükanne vb. |
| **Yaş** | Yaşa bağlı doz hesaplama için referans |
| **İlaç listesi** | Düzenli kullanılan ilaçlar, dozaj, frekans ve notlar |

### İlaç Kaydı Alanları

Her ilaç kaydı şu bilgileri içerir:

- İlaç adı
- Dozaj (örn. "500 mg", "1 tablet")
- Kullanım sıklığı (örn. "Günde 3 kez", "Haftalık")
- Notlar (örn. "Yemekten sonra alınacak")
- Ekleme tarihi

### Kullanım Senaryoları

- Yaşlı bir aile üyesinin ilaç listesini dijital ortamda tutmak
- Birden fazla doktordan reçete alan hastalarda ilaç takibini merkezileştirmek
- Eczaneye giderken hangi ilacın bittiğini hızlıca kontrol etmek
- Acil serviste doktora sunmak üzere ilaç listesini hazır tutmak
- Bakım veren kişinin (hemşire, refakatçı) hızlı bilgiye erişimi

### Local-First Mimari

Veriler önce cihazda Hive'a kaydedilir; arka planda sunucu ile senkronize edilir. Bu sayede internet bağlantısı kesilse bile liste görüntülenebilir ve düzenlenebilir.

### Faydaları

- **Tüm aile tek uygulamada:** Her birey için ayrı uygulama gerekmez
- **Doktor ziyaretine hazırlık:** İlaç listesi her an eksiksiz görüntülenebilir
- **İlaç yönetim merkezi:** Kim ne zaman ne alıyor sorusunun cevabı tek ekranda

---

## 10. Nöbetçi Eczane Bulucu

**Route:** `/pharmacy-nearby`

### Ne Yapar?

Bulunduğunuz konuma veya seçtiğiniz il/ilçeye göre o gün nöbetçi olan eczaneleri harita üzerinde gösterir; adres, telefon ve mesafe bilgisi sunar.

### Konum Tespiti Yöntemleri

| Yöntem | Açıklama |
|---|---|
| **Otomatik GPS** | "Konumumu kullan" butonu ile cihaz GPS'i devreye girer; Nominatim ile il/ilçe otomatik tespit edilir |
| **Manuel seçim** | İl ve ilçe açılır listesinden manuel seçim; GPS izni gerekmez |

### Harita Özellikleri

- OpenStreetMap tabanlı harita (Google Maps API anahtarı gerektirmez)
- Her nöbetçi eczane haritada iğne (pin) olarak işaretlenir
- İğneye tıklandığında adres, telefon ve yaklaşık mesafe bilgisi içeren panel açılır
- Harita kaydırılabilir ve yakınlaştırılabilir

### İlçe Bulunamadığında Fallback

İlçede o gün nöbetçi eczane yoksa sistem otomatik olarak **il genelinde** arama yapar ve sonuçları gösterir; kullanıcı boş ekranla karşılaşmaz.

### Eczane Kartı Bilgileri

Her eczane için gösterilen bilgiler:

| Bilgi | Kaynak |
|---|---|
| Eczane adı | eczaneler.gen.tr scraping |
| Adres | eczaneler.gen.tr scraping |
| Telefon | eczaneler.gen.tr scraping |
| İlçe | eczaneler.gen.tr scraping |
| Harita koordinatları | Nominatim geocoding (adres → koordinat dönüşümü) |
| Mesafe | GPS konumu varsa hesaplanır |

### Kullanım Senaryoları

- Gece ya da hafta sonunda açık eczane bulmak
- Seyahatte bulunulan şehirde nöbetçi eczane aramak
- Birden fazla eczane arasında en yakını seçmek
- Telefon etmeden önce adresi ve saati doğrulamak

### Faydaları

- **Konum bağımsız:** Her il ve ilçe için sorgulama yapılabilir
- **Gerçek zamanlı:** Veriler her sorguda anlık olarak çekilir; güncel nöbet bilgisi
- **GPS izni opsiyonel:** Konum vermek istemeyenler manuel seçimle de kullanabilir
- **Hızlı telefon erişimi:** Eczane numarasına tıklayarak anında arama başlatılabilir

---

## 11. Sağlık Notları

**Route:** `/health-notes`

### Ne Yapar?

Kan basıncı, kan şekeri, ağrı düzeyi ve genel sağlık durumu gibi klinik ölçümleri tarih bazlı kayıt altına alır; grafik ve takvim görünümü ile zaman içindeki değişimi görselleştirir.

### Not Kategorileri

| Kategori | Özel Alanlar | Kullanım |
|---|---|---|
| **Genel** | Metin, ruh hali, semptom etiketleri | Günlük sağlık durumu |
| **Tansiyon** | Sistolik / diastolik (mmHg) | Hipertansiyon takibi |
| **Kan Şekeri** | Glukoz değeri (mg/dL) | Diyabet yönetimi |
| **Ağrı** | Ağrı düzeyi (0–10 skala), lokasyon | Kronik ağrı takibi |
| **Psikoloji** | Ruh hali, stres düzeyi | Mental sağlık günlüğü |
| **Diğer** | Serbest metin | Özel ölçümler |

### Kayıt Alanları (Ortak)

Tüm kategorilerde bulunan ortak alanlar:

- **Tarih:** Kullanıcı tarafından seçilir; geçmiş tarihli kayıt eklenebilir
- **Not metni:** Serbest açıklama
- **Ruh hali:** Emoji ile hızlı durum ifadesi (😊, 😐, 😟)
- **Semptom etiketleri:** Bulantı, baş dönmesi, yorgunluk gibi hızlı etiket seçimi
- **İlaç alındı mı?** Evet/hayır işaretleme

### Görselleştirme

- **Trend grafiği (`fl_chart`):** Tansiyon ve kan şekeri değerlerinin zaman çizgisi
- **Takvim görünümü (`table_calendar`):** Kayıt olan günler vurgulanır; geçmiş tarihe tıklayarak o güne ait notlara erişilir
- **Liste görünümü:** Tüm kayıtların kronolojik listesi

### Kullanım Senaryoları

- Diyabetik hastanın günlük kan şekeri takibi
- Hipertansiyon hastasının sabah/akşam tansiyon ölçüm kaydı
- Doktora götürülecek ölçüm verilerinin hazırlanması
- Ağrı günlüğü ile tedavi etkinliğinin değerlendirilmesi
- Ruh hali günlüğü ile psikolojik sağlık takibi
- İlaç alım düzeni ile semptom ilişkisini görsel olarak inceleme

### Faydaları

- **Doktor ziyaretine değer katar:** Hafızadan değil, gerçek ölçümlerden oluşan rapor
- **Trend farkındalığı:** Tek ölçüm değil, zamanla değişim görülür
- **Tamamen yerel:** Hassas sağlık verileri cihazda kalır, sunucuya gönderilmez
- **Çok boyutlu takip:** Farklı kategorileri aynı uygulamada bir arada tutmak

---

## 12. Acil Durum Kartı

**Route:** `/emergency-card`

### Ne Yapar?

Kan grubu, alerjiler, kronik hastalıklar, düzenli kullanılan ilaçlar ve acil iletişim bilgilerini içeren dijital bir sağlık kartı oluşturur. Bu kart QR kod olarak paylaşılabilir.

### Kart İçeriği

| Alan | Açıklama |
|---|---|
| **Kan grubu** | A Rh+, 0 Rh- vb. |
| **Alerjiler** | İlaç, besin, madde alerjileri |
| **Kronik hastalıklar** | Diyabet, hipertansiyon, astım vb. |
| **Düzenli ilaçlar** | Hızlı referans için ilaç listesi |
| **Acil iletişim kişisi** | Ad ve telefon numarası |
| **Doktor bilgisi** | Aile hekimi veya uzman adı ve telefonu |
| **Ek notlar** | Özel bilgiler (organ nakli, kalp pili vb.) |

### Paylaşım Yöntemleri

| Yöntem | Açıklama |
|---|---|
| **QR Kod** | Kart içeriği QR koda dönüştürülür; sağlık personeli taratarak okuyabilir |
| **Sistem Paylaşımı** | `share_plus` ile WhatsApp, e-posta veya SMS üzerinden metin olarak gönderim |

### Kullanım Senaryoları

- Yurt dışı seyahatinde sağlık kartı gibi taşımak
- Bilinç kaybı veya iletişim güçlüğü durumunda sağlık personelinin hızlı bilgiye erişimi
- Bakım evine ya da hastaneye yatışta bilgi formu olarak sunmak
- Yaşlı aile üyesi adına doldurup cihazda hazır bulundurmak
- Spor etkinliklerinde veya maceralı aktivitelerde güvenlik önlemi

### Güvenlik Notu

Acil durum kartı verileri **yalnızca cihazda** saklanır; sunucuya gönderilmez. Bu hassas sağlık bilgisinin bulut ortamında depolanmamasını bilinçli olarak tercih eden kullanıcılar için önemlidir.

### Faydaları

- **Kritik anlarda hayat kurtarır:** Kan grubu veya alerji bilgisi doğru müdahale için hayati önem taşır
- **Her an erişilebilir:** Telefon açıldığında saniyeler içinde ulaşılabilir
- **Evrensel format:** QR kod dünya genelinde okunan standart bir format
- **Güncelleme kolaylığı:** Kâğıt karta göre yeni ilaç veya durum anında eklenebilir

---

## 13. Arama ve Tarama Geçmişi

**Route:** `/drug-search-history` ve `/drug-scan-history`

### Ne Yapar?

Daha önce yapılan ilaç aramalarını ve görsel taramaları kaydederek tekrar aramasına gerek kalmadan hızlı erişim sağlar.

### Arama Geçmişi

- Her başarılı metin araması otomatik kaydedilir
- Son aranan ilaca tek tıkla tekrar ulaşılır
- Geçmiş girdileri tek tek veya toplu silinebilir

### Tarama Geçmişi

- Görsel analiz ile tanınan her ilaç, analiz sonucuyla birlikte kaydedilir
- Geçmiş tarama sonuçları yeniden görüntülenebilir (yeni API çağrısı yapılmaz)
- Önizleme görseli ile hangi fotoğrafın tarandığı hatırlanır

### Faydaları

- **Tekrar aramanın önüne geçer:** Geçen hafta baktığınız ilaca hemen dönebilirsiniz
- **Bant genişliği tasarrufu:** Önbellekteki geçmiş sonuçlar için yeni API çağrısı yapılmaz
- **Referans olarak kullanım:** Doktor ziyaretinde geçmişte araştırılan ilaçları göstermek

---

## Modüller Arası İlişki Haritası

```
İlaç Arama ──────────────────────────────┐
Fotoğrafla Tanıma ──────────────────────►│
                                          │
                                  İlaç Detay Ekranı
                                          │
                          ┌───────────────┤
                          │               │
                    Etkileşim         Doğal
                    Kontrolü       Alternatifler

İlaç Hatırlatıcısı ◄────── Aile Profili
(kişiye bağlı)             (üye + ilaç listesi)

Semptom Analizi ──────────► Sağlık Notları
(belirtileri kaydet)        (takip ve grafik)

Nöbetçi Eczane             Acil Durum Kartı
(konum bağımlı)            (her zaman hazır)

Yapay Zekâ Sohbeti ────────► Tüm sorular için
```

---

## Modüllerin Çevrimiçi / Çevrimdışı Durumu

| Modül | İnternet Gerekli? | Açıklama |
|---|---|---|
| İlaç Arama | Evet | Gemini API çağrısı; önbellekte varsa hayır |
| Fotoğrafla Tanıma | Evet | Görsel analiz |
| Prospektüs Okuyucu | Evet | Görsel analiz |
| İlaç Etkileşimi | Evet | Gemini analizi |
| Doğal Alternatifler | Evet | Gemini analizi |
| AI Sohbet | Evet | Gemini sohbet |
| Semptom Analizi | Evet | Gemini analizi |
| İlaç Hatırlatıcısı | **Hayır** | Tamamen yerel |
| Aile Profili | Kısmen | Okuma yerel; yazma senkronizasyonu için bağlantı önerilir |
| Nöbetçi Eczane | Evet | Anlık scraping |
| Sağlık Notları | **Hayır** | Tamamen yerel |
| Acil Durum Kartı | **Hayır** | Tamamen yerel |
| Geçmiş (arama/tarama) | **Hayır** | Yerel Hive |

---

*Bu döküman, yeni modül eklendikçe veya mevcut modüllerde kullanıcıya yönelik değişiklik yapıldıkça güncellenmelidir.*
