# Eczanem — Akademik Ar-Ge Raporu

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Kapsam:** Araştırma-Geliştirme boyutu, teknik katkılar, akademik literatür değerlendirmesi
**Hazırlayan Amaç:** Lisans/Yüksek Lisans Bitirme Tezi Altyapı Belgesi
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Projenin Araştırma Soruları](#1-projenin-araştırma-soruları)
2. [Problem Tanımı ve Motivasyon](#2-problem-tanımı-ve-motivasyon)
3. [Kullanılan Yapay Zekâ Teknolojileri](#3-kullanılan-yapay-zekâ-teknolojileri)
4. [Prompt Mühendisliği Yaklaşımı](#4-prompt-mühendisliği-yaklaşımı)
5. [Multimodal Yapay Zekâ Entegrasyonu](#5-multimodal-yapay-zekâ-entegrasyonu)
6. [Sistem Mimarisi: Akademik Bakış](#6-sistem-mimarisi-akademik-bakış)
7. [Performans ve Güvenilirlik Mekanizmaları](#7-performans-ve-güvenilirlik-mekanizmaları)
8. [Veri Güvenliği ve Tıbbi Etik](#8-veri-güvenliği-ve-tıbbi-etik)
9. [Literatüre Katkı ve Özgünlük Analizi](#9-literatüre-katkı-ve-özgünlük-analizi)
10. [Sınırlılıklar ve Gelecek Çalışmalar](#10-sınırlılıklar-ve-gelecek-çalışmalar)
11. [Kaynakça Önerileri](#11-kaynakça-önerileri)

---

## 1. Projenin Araştırma Soruları

Bu proje aşağıdaki temel araştırma sorularını yanıtlamayı hedeflemektedir:

**RQ1:** Büyük Dil Modelleri (LLM), yapılandırılmamış metin girdileriyle Türkçe ilaç bilgisini ne ölçüde doğru ve tutarlı biçimde üretebilir?

**RQ2:** Multimodal yapay zekâ modelleri, ilaç kutusu veya prospektüs görüntülerinden klinik açıdan anlamlı bilgileri başarıyla çıkarabilir mi?

**RQ3:** Mobil sağlık (mHealth) uygulamalarında istemci-taraflı veri yerelliği ile bulut tabanlı yapay zekâ servislerinin hibrit mimarisi nasıl tasarlanmalıdır?

**RQ4:** Türk sağlık bilişimi bağlamında, hasta güvenliğini destekleyen bir ilaç bilgi sistemi mevcut açık uçlu API'lerle uygulanabilir mi?

---

## 2. Problem Tanımı ve Motivasyon

### 2.1 Sağlık Bilişiminde Mevcut Boşluk

Türkiye'de T.C. İlaç ve Tıbbî Cihaz Kurumu (TİTCK) kapsamlı bir ilaç veri tabanı sunmaktadır; ancak bu veri tabanına programatik erişim için resmi ve herkese açık bir REST API bulunmamaktadır. Mevcut çözümler şu açıklardan muzdariptir:

| Mevcut Durum | Sorun |
|---|---|
| Eczacıyla yüz yüze danışma | 7/24 erişilemiyor; yoğun saatlerde uzun bekleme |
| Kâğıt prospektüs | Küçük punto, tıbbi jargon, büyük yaş grubu için okunması güç |
| Web tabanlı ilaç siteleri | Mobil optimizasyonu yetersiz; etkileşim sorgusu yok |
| Genel amaçlı chatbot'lar | Türkiye'ye özgü ilaç adı ve formülasyon bilinmiyebilir |

### 2.2 Hedef Kullanıcı Profili

- Kronik hastalığı olan ve çok ilaç kullanan yetişkinler
- Yaşlı bireylerin ilaç takibini üstlenen bakım verenler
- Farklı doktorlardan gelen reçeteleri yönetmek zorunda olan hastalar
- İlaç adını okuyamayan veya anlayamayan düşük sağlık okuryazarlığı olan bireyler

### 2.3 Çözüm Yaklaşımının Özgünlüğü

Eczanem, metin ve görsel tabanlı sorguları tek bir Türkçe arayüzde birleştiren, çevrimdışı yerel veri depolama ile çevrimiçi yapay zekâ analizini hibrit biçimde kullanan bir mHealth uygulamasıdır. TİTCK API eksikliğini, Gemini 2.5 Flash'ın geniş eğitim verisi aracılığıyla telafi etmektedir.

---

## 3. Kullanılan Yapay Zekâ Teknolojileri

### 3.1 Temel Model: Google Gemini 2.5 Flash

| Özellik | Teknik Detay | Tez Bağlamında Önemi |
|---|---|---|
| **Model sürümü** | `gemini-2.5-flash` (Google AI Studio API) | Düşük gecikme + yüksek çıktı kalitesi dengesi |
| **Erişim yöntemi** | REST API, `generateContent` endpoint | Açık API standardı; bağımsız model değiştirilebilirlik |
| **Çıktı tipi** | JSON (structured output) ve düz metin | Güvenilir veri ayrıştırma; uygulamaya doğrudan bağlanabilirlik |
| **Sıcaklık (temperature)** | 0.3 (ilaç bilgisi sorgularında) | Halüsinasyonu azaltmak için düşük rastgelelik |
| **Multimodal destek** | Metin + görüntü (Base64 inlineData) | Prospektüs ve kutu okuma için zorunlu |
| **Bağlam penceresi** | Sohbet geçmişi dahil (~50 mesaj) | Konuşmaya dayalı akış; bağlam tutarlılığı |

### 3.2 Yapay Zekânın Kullanıldığı 7 Görev

```
┌─────────────────────────────────────────────────────────────┐
│                    GÖREV SINIFLANDIRMASI                     │
├──────────────────────────┬──────────────────────────────────┤
│ Görev                    │ Yapay Zekâ Türü                  │
├──────────────────────────┼──────────────────────────────────┤
│ 1. İlaç bilgisi üretimi  │ Text generation (NLG)            │
│ 2. Görsel ilaç tanıma    │ Multimodal — görüntü + metin     │
│ 3. Prospektüs özetleme   │ Multimodal — OCR + özetleme      │
│ 4. Etkileşim analizi     │ Text generation + risk sınıflandırma│
│ 5. Doğal alternatifler   │ Text generation (bilgi geri çağırma)│
│ 6. Eczacı sohbeti        │ Conversational AI (çok turlu)    │
│ 7. Semptom analizi       │ Text generation + binary sınıflandırma│
└──────────────────────────┴──────────────────────────────────┘
```

### 3.3 Diğer AI/ML Bileşenler

- **Nominatim (OpenStreetMap):** Kullanıcı koordinatlarını il/ilçe adına dönüştürmek için açık kaynak coğrafi kodlama (reverse geocoding). Ticari harita API'sine alternatif.
- **Pillow görüntü ön işleme:** Makine öğrenmesi görüntü boru hattı standardı olan yeniden boyutlandırma (maks. 1400×1400 piksel) ve EXIF döndürme normalleştirmesi, Gemini'ye gönderimden önce uygulanır.

---

## 4. Prompt Mühendisliği Yaklaşımı

Prompt mühendisliği (prompt engineering), LLM'lerin çıktı kalitesini şekillendiren kritik bir araştırma alanıdır. Bu projede 7 farklı özel prompt tasarlanmış, her biri belirli kısıtlamalara tabi tutulmuştur.

### 4.1 Prompt Tasarım İlkeleri

**Rol Ataması (Role Prompting):**
Her prompt, modele bir persona verir:
```
"Sen bir eczacı asistanısın."
```
Bu teknik, modelin davranışını belirli bir alan uzmanıyla sınırlandırarak genel bilgi gürültüsünü azaltır. Literatürde *role prompting* olarak bilinir ve çıktı tutarlılığını artırdığı gösterilmiştir.

**Yapılandırılmış Çıktı Zorunluluğu (Structured Output):**
Tüm sorgularda (sohbet hariç) çıktı formatı JSON şemasıyla önceden tanımlanmıştır:
```python
"generationConfig": {
    "temperature": 0.3,
    "responseMimeType": "application/json",
}
```
Bu yaklaşım *constrained generation* (kısıtlı üretim) olarak sınıflandırılır. Modelin format dışı yanıt üretmesini önler; uygulama katmanında ayrıştırma güvenilirliğini artırır.

**Halüsinasyon Azaltma Direktifleri:**
Her promptun sonunda modele açık talimat verilmiştir:
```
"Emin olmadığın bilgileri uydurma, 'Bilgi bulunamadı' yaz."
```
Bu yaklaşım LLM halüsinasyonunu sınırlamaya yönelik uygulama düzeyinde bir güvenlik mekanizmasıdır.

**Sıcaklık Parametresi Seçimi:**
İlaç bilgisi gerektiren görevlerde `temperature=0.3` kullanılmıştır. Bu değer:
- `temperature=0`: Tamamen deterministik — çeşitlilik yok
- `temperature=1.0`: Yüksek yaratıcılık — tıbbi bağlamda riskli
- `temperature=0.3`: Düşük rastgelelik; tutarlı ama robotik olmayan çıktı

**Güvenlik Duvarı Direktifleri:**
Semptom analizi ve sohbet promptlarında açıkça belirtilmiştir:
```
"`acil_durum` alanını yalnızca gerçekten acil olan durumlarda
(göğüs ağrısı, nefes darlığı vb.) true yap."
```
Bu, model çıktısı üzerine kural tabanlı güvenlik katmanı oluşturmanın bir örneğidir.

### 4.2 Prompt Başına Detaylı Analiz

| Prompt | Girdi Tipi | Çıktı Şeması Alanları | Tasarım Kararı |
|---|---|---|---|
| `DRUG_SEARCH_PROMPT` | Metin (ilaç adı) | 10 alan: ad, etken madde, endikasyon, dozaj, kullanım, yan etkiler, uyarılar, kontrendikasyon, alternatifler | Sıcaklık 0.3; JSON zorunu |
| `DRUG_IMAGE_PROMPT` | Görüntü + metin | 10 alan + `aday_ilaclar` (çoklu aday) | Belirsizlik yönetimi: birden fazla eşleşmeyi listeler |
| `PROSPECTUS_PROMPT` | Görüntü (prospektüs) | 8 alan: ad, tür, kullanım, nasıl, dikkat, yan etkiler, saklama, doktora ne zaman | OCR odaklı; "uydurma" direktifi kritik |
| `DRUG_INTERACTION_PROMPT` | Metin (ilaç listesi) | Genel risk seviyesi + ilaç çifti bazlı tablo | Risk sınıflandırma: dusuk/orta/yuksek |
| `NATURAL_ALTERNATIVES_PROMPT` | Metin (ilaç adı) | Hedef + alternatif listesi (tür, açıklama, dikkat) | Kategorize çıktı: bitkisel/beslenme/yaşam tarzı |
| `PHARMACIST_CHAT_PROMPT` | Metin + geçmiş | Serbest metin (Markdown) | Sıcaklık varsayılan; emoji ve başlık direktifleri |
| `SYMPTOM_ANALYSIS_PROMPT` | Metin (belirti) | 6 alan + `acil_durum: bool` | İkili sınıflandırma (acil/acil değil) kritik güvenlik alanı |

---

## 5. Multimodal Yapay Zekâ Entegrasyonu

### 5.1 Görüntü İşleme Boru Hattı

Görüntü tabanlı ilaç tanıma, projenin en özgün teknik katkılarından birini oluşturmaktadır. Standart metin tabanlı API çağrılarının ötesinde, görüntü verisi işleme boru hattı şu aşamalardan oluşmaktadır:

```
Mobil kamera / galeri
        │
        ▼ (Flutter tarafında)
JPEG sıkıştırma (%82 kalite)
Maksimum 1400×1400 piksel küçültme
EXIF döndürme uygulaması
        │
        ▼ HTTP multipart/form-data
Backend (FastAPI)
        │
        ▼ (Python Pillow)
İkinci doğrulama katmanı:
  · EXIF transpose (normalize)
  · RGB dönüşümü (PNG/RGBA uyumluluk)
  · Yeniden optimize JPEG çıkışı
        │
        ▼ Base64 encode
Gemini API (inlineData)
  · MIME type: image/jpeg
  · Multimodal prompt: metin + görüntü
        │
        ▼
Yapılandırılmış JSON yanıt
  · ilac_adi (tek tanımlama)
  · aday_ilaclar (çoklu olasılık)
```

### 5.2 Çift Taraflı Görüntü Optimizasyonu

Proje, görüntü optimizasyonunu hem istemci (Flutter) hem de sunucu (Python/Pillow) tarafında uygulamaktadır. Bu çift katmanlı yaklaşım:

- **İstemci tarafı:** Ağ bant genişliği ve Gemini API giriş boyutu maliyetini azaltır
- **Sunucu tarafı:** Hatalı sıkıştırılmış görselleri kurtarır; EXIF tutarsızlıklarını giderir; farklı mobil cihazların farklı sıkıştırma çıktılarını normalize eder

Bu yaklaşım, güvenilirlik açısından tek noktalı başarısızlığı (single point of failure) önleyen savunmacı programlama (defensive programming) örneğidir.

### 5.3 Belirsizlik Yönetimi (Ambiguity Handling)

Görüntü tanımada model, birden fazla olası eşleşme dönebildiğinde `aday_ilaclar` alanı ile kullanıcıya seçim listesi sunar. Bu yaklaşım:

- Yanlış pozitif (false positive) riski yerine kullanıcıyı karar sürecine dahil etmeyi tercih eder
- Özellikle görüntü kalitesinin düşük olduğu senaryolarda güvenlik açısından kritik bir tasarım kararıdır
- Makine öğrenmesinde *confidence-based fallback* (güven eşiği tabanlı geri dönüş) pratiğinin uygulama düzeyinde uygulamasıdır

---

## 6. Sistem Mimarisi: Akademik Bakış

### 6.1 Katmanlı Hibrit Mimari

Eczanem, üç farklı veri yerlilik düzeyi içeren hibrit bir mimari sunar:

```
┌─────────────────────────────────────────────────────┐
│              MİMARİ KATMANLAR                        │
├─────────────────┬───────────────────────────────────┤
│ Katman          │ Bileşenler                         │
├─────────────────┼───────────────────────────────────┤
│ Cihaz-yerel     │ Hive (anahtar-değer deposu)        │
│                 │ FlutterSecureStorage (JWT)          │
│                 │ flutter_local_notifications         │
│                 │ → Acil kart, sağlık notları,       │
│                 │   hatırlatıcılar, arama geçmişi    │
├─────────────────┼───────────────────────────────────┤
│ Backend API     │ FastAPI + PostgreSQL + Redis        │
│                 │ → Kimlik doğrulama, aile profili   │
├─────────────────┼───────────────────────────────────┤
│ AI Servisi      │ Google Gemini 2.5 Flash API        │
│                 │ → Tüm yapay zekâ işlemleri         │
└─────────────────┴───────────────────────────────────┘
```

**Akademik katkı:** Bu hibrit yaklaşım, mHealth literatüründe tartışılan *privacy-by-design* (tasarım gereği gizlilik) ilkesini somutlaştırmaktadır. Hassas sağlık verileri (acil kart, sağlık günlüğü, hatırlatıcı bilgisi) sunucuya gönderilmez; yalnızca anonimleştirilebilir sorgular (ilaç adı metni, aile profili) bulut katmanına ulaşır.

### 6.2 Clean Architecture Uygulaması

Mobil tarafta, her özellik modülü kendi içinde katmanlı olarak izole edilmiştir:

```
feature/
├── data/          # Harici bağımlılıklar (API, Hive)
│   ├── models/    # Veri nesneleri (JSON ↔ Dart)
│   └── *_repository.dart
├── domain/        # Saf iş mantığı (bağımlılık yok)
└── presentation/  # UI + Riverpod state
```

Bu yapı, Robert C. Martin'in *Clean Architecture* ilkelerine dayanmaktadır ve sınav/sınav dışı (testable/non-testable) kod ayrımına olanak tanır. Proje, bu yapıyı 9 feature modülü için tutarlı biçimde uygulamaktadır.

### 6.3 Durum Yönetimi Paradigması

Riverpod 2.x `AsyncNotifier` tabanlı durum yönetimi, Flutter'ın standart `setState` yaklaşımının ötesinde reaktif bir veri akış modeli kurar:

```
Kullanıcı eylemi
    │
    ▼
Provider (AsyncNotifier)
    │
    ├─ loading → UI yükleniyor
    ├─ data    → UI güncelleniyor
    └─ error   → UI hata gösteriyor
```

`FutureEither<Failure, T>` tipi (fpdart kütüphanesi), fonksiyonel programlamadaki *Railway Oriented Programming* (ROP) örüntüsünü Dart'a taşır. Başarı ve hata akışları ayrı kollardan ilerler; `try-catch` bloklarına gerek kalmaz.

---

## 7. Performans ve Güvenilirlik Mekanizmaları

### 7.1 İki Katmanlı Cache Mimarisi

İlaç arama sorgularında iki katmanlı önbellek uygulanmıştır:

```python
async def query_drug_info_with_guard(drug_name: str, client_key: str) -> dict:
    # 1. Katman: Redis (kalıcı, dağıtılmış)
    cached = await _get_cached_response_from_redis(drug_name)

    # 2. Katman: In-memory dict (Redis erişilemez ise)
    if cached is None:
        cached = _get_cached_response(drug_name)

    if cached is not None:
        return _clone_payload(cached)  # Derin kopya: immutability güvencesi

    # Cache miss → rate limit kontrolü → Gemini API
    _enforce_rate_limit(client_key)
    response = await query_drug_info(drug_name)
    ...
```

**TTL (Time-to-Live):** 86400 saniye (24 saat). İlaç bilgisi kısa sürede değişmediğinden bu değer, API maliyet optimizasyonu için uygundur.

**Akademik bağlam:** Bu mimari, Çevrimiçi Sistemler ve Servis Yönelimli Mimari literatüründe tanımlanan *cache-aside pattern* (önbellek yanı örüntüsü) ile *graceful degradation* (zarif bozunma) ilkelerini birlikte uygular.

### 7.2 Üssel Geri Çekilme (Exponential Backoff)

Gemini API geçici 5xx hatası döndürdüğünde sistem üssel geri çekilme uygular:

```python
for attempt in range(3):
    response = await client.post(...)
    if response.status_code == 200:
        return response
    if response.status_code >= 500 and attempt < 2:
        await asyncio.sleep(2**attempt)  # 1s, 2s
```

Bu teknik, AWS, Google ve Netflix mühendislik bloglarında belgelenen dağıtık sistem hata toleransının temel örüntüsüdür.

### 7.3 Kayan Pencere Hız Sınırlayıcı (Sliding Window Rate Limiter)

Hem ilaç arama hem de auth endpoint'leri için IP tabanlı kayan pencere algoritması uygulanmıştır:

```python
# İlaç arama: IP başına dakikada 10 istek
drug_search_rate_limit_max_requests: int = 10
drug_search_rate_limit_window_seconds: int = 60

# Auth: IP başına dakikada 20 istek
_AUTH_MAX_REQUESTS = 20
_AUTH_WINDOW_SECONDS = 60
```

**Not:** Cache hit'leri (önbellekte bulunan sorgular) rate limite dahil edilmez. Bu kararın gerekçesi: maliyet, API istek sayısında oluşur; önbellekten sunulan yanıt kaynak tüketmez.

### 7.4 Çevrimdışı Dayanıklılık (Offline Resilience)

İlaç hatırlatıcıları, sağlık notları ve acil kart modülleri tamamen çevrimdışı çalışmaktadır. Android'in `AlarmManager` tabanlı bildirimleri ağ bağlantısından bağımsız planlanır; ayrı bir `alarm` kanalı, DND (Rahatsız Etme) modunu bypass eder.

Bu özellik, bağlantı kesintilerinin öngörülebileceği gerçek dünya sağlık senaryolarında (taşıma, kırsal bölge) kritik öneme sahiptir.

---

## 8. Veri Güvenliği ve Tıbbi Etik

### 8.1 Uygulanan Güvenlik Kontrolleri

| Tehdit | Kontrmesaj | Uygulama |
|---|---|---|
| Brute-force login | Auth rate limiter | 60s/20 istek IP başına |
| API kötüye kullanımı | Drug search rate limiter | 60s/10 istek IP başına |
| JWT tahrifi | Production'da varsayılan secret reddedilir | Startup validator |
| Hassas veri sızıntısı | Privacy-by-design | Acil kart / sağlık notu sunucuya gitmez |
| Prompt injection | Yapılandırılmış JSON çıktısı | Model serbest metin üretemez |
| Görüntü manipülasyonu | Boyut + format normalleştirme | Pillow pipeline |
| CORS saldırıları | Yapılandırılabilir allowed_origins | .env override zorunluluğu |

### 8.2 Tıbbi Sorumluluk (Medical Disclaimer) Tasarımı

Yapay zekâ çıktıları, kasıtlı olarak tıbbi tavsiye sınırının dışında tutulmuştur. Bu tasarım kararı üç katmanda uygulanmaktadır:

1. **Prompt katmanı:** Her promptun sonunda `"Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz."` direktifi
2. **API katmanı:** Her yanıta `disclaimer` alanı otomatik eklenir
3. **UI katmanı:** Kullanıcıya görünen her AI çıktısında sabit uyarı mesajı

Bu yaklaşım, FDA'nın Dijital Sağlık İnovasyon Eylem Planı ve AB Yapay Zekâ Yönetmeliği'nde (AI Act) yüksek riskli yapay zekâ uygulamaları için öngörülen *human oversight* (insan denetimi) gerekliliğiyle uyumludur.

### 8.3 Halüsinasyon Riski Yönetimi

LLM'lerin faktüel hata üretme riski (halüsinasyon), tıbbi uygulamalarda kritik bir güvenlik sorunudur. Projede bu risk şu yollarla azaltılmıştır:

- `temperature=0.3` ile deterministik eğilimli çıktı
- Prompt düzeyinde "uydurma" yasağı ve "bilinmiyor" direktifi
- Kullanıcıya açık disclaimer ile nihai kararı insana bırakma
- Acil durum tespitinde ikili (`bool`) çıktı zorunluluğu

---

## 9. Literatüre Katkı ve Özgünlük Analizi

### 9.1 Özgün Teknik Katkılar

**Katkı 1 — Türkçe İlaç Bilgisi için Görev Odaklı Prompt Seti**
Resmi TİTCK API'si olmaksızın, Türkçe ilaç bilgisi üretimi için 7 ayrı, görev-spesifik prompt şeması geliştirilmiştir. Her prompt, alanın kısıtlamalarını (halüsinasyon yasağı, güvenlik direktifleri, yapılandırılmış çıktı) içermektedir. Bu şemalar, benzer mHealth projeleri için başlangıç noktası (baseline) olarak kullanılabilir.

**Katkı 2 — Çift Taraflı Görüntü Optimizasyon Boru Hattı**
Hem istemci (Dart/Flutter) hem de sunucu (Python/Pillow) tarafında görüntü normalleştirme uygulayarak Gemini'ye gönderilen görselin boyut ve format tutarlılığını garanti altına alan bir boru hattı tasarlanmıştır. Bu yaklaşım, farklı mobil donanımların kamera çıktı farklılıklarından kaynaklanan güvenilirlik sorununu çözmektedir.

**Katkı 3 — Privacy-by-Design mHealth Mimarisi**
Hassas sağlık verilerini (acil kart, sağlık günlüğü, ilaç hatırlatıcıları) tamamen cihazda saklarken yalnızca anonim içerikli sorguları (ilaç adı metni) bulut katmanına yönlendiren üç katmanlı hibrit mimari, Türkçe mHealth literatüründe az çalışılmış bir alan olan yerel-öncelikli (local-first) sağlık uygulaması tasarımı için somut bir referans mimarisi sunmaktadır.

**Katkı 4 — İki Katmanlı Cache + Rate Limiting Entegrasyonu**
Redis öncelikli, bellek içi yedek (fallback) ikincil cache mimarisinde, API maliyet optimizasyonu için cache hit'lerin rate limit kapsamı dışında tutulması özgün bir tasarım kararıdır. Bu karar, AI API maliyeti ile kullanıcı deneyimi arasındaki dengeyi optimize eder.

**Katkı 5 — Güvenilir Multimodal Belirsizlik Çözümü**
Görüntü tanımada düşük güven durumunda `aday_ilaclar` alanı ile çoklu hipotez listesi sunmak ve son kararı kullanıcıya bırakmak, tıbbi uygulamalarda insan-AI işbirliği (human-AI collaboration) ilkesini pratik bir tasarım deseni olarak uygulamaktadır.

### 9.2 Mevcut Çalışmalarla Karşılaştırma

| Çalışma / Sistem | Dil/Bölge | AI Kullanımı | Multimodal | Çevrimdışı | Fark |
|---|---|---|---|---|---|
| Ada Health (UK) | İngilizce | Semptom analizi | Hayır | Kısmen | Türkçe ilaç odağı yok |
| Meditab iMedx | İngilizce | İlaç bilgisi | Hayır | Evet | EHR entegrasyonu; bireysel kullanım değil |
| Sağlık.gov.tr uygulaması | Türkçe | Hayır | Hayır | Kısmen | Randevu odaklı; ilaç bilgisi yok |
| Eczane.net | Türkçe | Hayır | Hayır | Hayır | Statik veri tabanı |
| **Eczanem (bu çalışma)** | **Türkçe** | **7 görev, Gemini** | **Evet** | **Evet** | **Entegre; bireysel; açık** |

### 9.3 mHealth Literatürü Bağlamı

Bu çalışmanın konumlandığı akademik alanlar:

- **Mobile Health (mHealth):** WHO tanımıyla tıbbi ve halk sağlığı uygulamalarının mobil cihazlarda sunulması
- **Clinical Decision Support (CDS):** Klinisyenler veya hastalar için karar desteği sistemleri
- **Conversational AI in Healthcare:** Sağlık chatbot'ları ve sanal asistan araştırması
- **Multimodal Information Retrieval:** Metin + görüntü girdisiyle bilgi geri çekme
- **Federated/Local-first Data Architecture:** Kullanıcı gizliliği odaklı dağıtılmış veri yönetimi

---

## 10. Sınırlılıklar ve Gelecek Çalışmalar

### 10.1 Mevcut Sınırlılıklar

| Sınırlılık | Teknik Neden | Olası Çözüm |
|---|---|---|
| **İlaç bilgisi doğrulanamaz** | Gemini çıktısı referans alınan kaynak belirtmez | TİTCK veri tabanıyla doğrulama katmanı eklenmesi |
| **Gerçek zamanlı nöbet verisi yok** | eczaneler.gen.tr HTML scraping; sayfa yapısı değişirse kırılır | Resmi API veya structured data feed |
| **Kişiselleştirme yok** | Kullanıcı tıbbi geçmişi modele iletilmiyor | Profil verilerini prompt bağlamına dahil etme |
| **Klinik validasyon yapılmamış** | Eczacı veya doktor denetimli değerlendirme eksik | Pilot çalışma + uzman değerlendirmesi |
| **Sadece Türkçe** | Prompt dili ve etiket seti Türkçe | Çok dilli prompt mimarisi |
| **Görüntü kalitesine bağımlılık** | Kötü aydınlatma veya bulanık görüntülerde tanıma başarısız | Fine-tuned OCR modeli entegrasyonu |

### 10.2 Önerilen Gelecek Çalışmalar

**Kısa vadeli (1–6 ay):**
- TİTCK veri tabanıyla hibrit doğrulama: Gemini çıktısı ile resmi etken madde listesinin karşılaştırılması
- A/B testi ile prompt varyantlarının karşılaştırmalı değerlendirmesi
- Kullanıcı çalışması: 30+ kullanıcıyla kullanılabilirlik ve güven değerlendirmesi

**Orta vadeli (6–18 ay):**
- Retrieval-Augmented Generation (RAG) entegrasyonu: TİTCK kılavuzlarının vektör veri tabanında indekslenmesi ve Gemini prompt bağlamına eklenmesi
- Fine-tuned ilaç görüntü sınıflandırıcısı: Türkiye'de yaygın 500 ilaç için özel eğitimli CNN veya ViT modeli
- Eczacı ve doktor değerlendirmesiyle klinik doğruluk metrikleri (hassasiyet, özgüllük, F1)

**Uzun vadeli (18+ ay):**
- Federated learning ile kullanıcı gizliliğini koruyarak model iyileştirme
- EHR (Elektronik Sağlık Kaydı) sistemleriyle entegrasyon (HL7 FHIR standardı)
- Düzenleyici onay süreçleri araştırması (CE Medical Device, FDA 510(k))

---

## 11. Kaynakça Önerileri

Tez yazımında aşağıdaki alanlarda kaynak araştırılması önerilmektedir:

### Yapay Zekâ ve LLM

- Brown, T. et al. (2020). "Language Models are Few-Shot Learners." *NeurIPS*. — GPT-3 ve few-shot learning temeli
- Wei, J. et al. (2022). "Chain-of-Thought Prompting Elicits Reasoning in Large Language Models." *NeurIPS*. — Prompt mühendisliği
- Ouyang, L. et al. (2022). "Training language models to follow instructions with human feedback." *NeurIPS*. — RLHF ve güvenli AI
- Bommasani, R. et al. (2021). "On the Opportunities and Risks of Foundation Models." *Stanford HAI*. — LLM risk analizi

### Sağlık Bilişimi ve mHealth

- Topol, E. (2019). "High-performance medicine: the convergence of human and artificial intelligence." *Nature Medicine*. — Sağlıkta AI
- Steinhubl, S. R. et al. (2015). "The emerging field of mobile health." *Science Translational Medicine*. — mHealth tanımı
- Bates, D. W. et al. (2014). "Big data in health care: using analytics to identify and manage high-risk and high-cost patients." *Health Affairs*. — Sağlık verisi
- Peek, N. et al. (2015). "Thirty years of artificial intelligence in medicine (AIME) conferences." *Artificial Intelligence in Medicine*. — AI in medicine genel bakış

### Yazılım Mimarisi

- Martin, R. C. (2017). *Clean Architecture: A Craftsman's Guide to Software Structure and Design*. Prentice Hall. — Clean Architecture
- Newman, S. (2021). *Building Microservices* (2. baskı). O'Reilly. — Servis mimarisi
- Kleppmann, M. (2017). *Designing Data-Intensive Applications*. O'Reilly. — Cache, rate limiting, dağıtık sistemler

### Güvenlik ve Gizlilik

- Cavoukian, A. (2009). "Privacy by Design: The 7 Foundational Principles." Information and Privacy Commissioner of Ontario. — Privacy-by-Design
- OWASP Foundation. (2021). *OWASP Top 10 Web Application Security Risks*. — Güvenlik referansı
- Regulation (EU) 2024/1689 (AI Act). — AB Yapay Zekâ Yönetmeliği

### Türkiye'ye Özgü

- Sağlık Bakanlığı Dijital Dönüşüm Ofisi. Türkiye Sağlık Bilişimi Raporu.
- TİTCK. Beşeri Tıbbî Ürünler Kılavuzu.

---

## Özet: Tez İçin Öne Çıkarılacak Noktalar

| Bölüm | Öne Çıkan İddia | Kanıt |
|---|---|---|
| **Özgünlük** | Türkçe ilaç bilgisi için özelleştirilmiş LLM prompt seti | 7 ayrı görev şeması; halüsinasyon azaltma direktifleri |
| **Teknik derinlik** | Multimodal AI + görüntü optimizasyon boru hattı | Pillow pipeline; çift taraflı sıkıştırma; EXIF normalize |
| **Sistem tasarımı** | Privacy-by-design hibrit mimari | Local-first veri modeli; sunucu → yalnızca anonim sorgular |
| **Güvenilirlik** | İki katmanlı cache + exponential backoff | Redis + in-memory; 3 deneme; 2^n bekleme |
| **Güvenlik** | OWASP uyumlu; çok katmanlı rate limiting | Auth 20req/dk; drug 10req/dk; JWT production validator |
| **Etik** | İnsan denetimli AI; disclaimer katmanlama | Prompt + API + UI düzeyinde 3 katman |
| **Pratik değer** | TİTCK API eksikliğinin açık araçlarla giderilmesi | Nominatim + scraping + Gemini kombinasyonu |

---

*Bu döküman, bitirme tezi yazım sürecinde teorik altyapı ve teknik referans olarak kullanılmak amacıyla hazırlanmıştır. İçerik; kaynak taraması, metodoloji bölümü ve sonuç bölümü için ham materyal niteliği taşımaktadır.*
