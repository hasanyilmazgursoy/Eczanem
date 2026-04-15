# Eczanem — Bitirme Projesi Vize Ara Raporu

**Öğrenci:** Hasan  
**Danışman:** Hasan Yetiş  
**Tarih:** 15 Nisan 2026  
**Proje Başlangıç Tarihi:** 9 Nisan 2026

---

## 1. Giriş ve Projenin Amacı

**Eczanem**; ilaç arama, fotoğraftan ilaç tanıma, prospektüs özetleme, ilaç etkileşim kontrolü, doğal alternatif önerisi ve ilaç hatırlatıcı gibi işlevleri tek bir mobil uygulamada birleştiren, yapay zekâ destekli bir kişisel ilaç asistanıdır. Flutter (Dart) ile geliştirilen mobil istemci ve FastAPI (Python) ile geliştirilen sunucu bileşenlerinden oluşmaktadır.

Projenin temel motivasyonu, Türkiye'de hastaların ilaç bilgisine erişimde yaşadığı zorluklar, prospektüs metinlerinin karmaşıklığı ve kullanıcıların birden fazla ilacı bir arada kullanırken etkileşim risklerinden haberdar olamamasıdır. Eczanem, bu sorunlara teknolojik bir çözüm sunarak bireylerin sağlık okuryazarlığına katkı sağlamayı amaçlamaktadır.

---

## 2. Kullanılan Teknolojiler ve Yöntemler

### 2.1 Mimari Yaklaşım

Proje, istemci-sunucu mimarisine dayalı, iki ana bileşenden oluşmaktadır:

- **Mobil İstemci:** Flutter (Dart) ile geliştirilmiş, Clean Architecture prensiplerine uygun feature-first klasör yapısı. Her özellik kendi `data`, `domain` ve `presentation` katmanlarına sahiptir.
- **Sunucu:** FastAPI (Python) ile geliştirilmiş, modüler yapıda (`routers`, `services`, `models`, `schemas`) RESTful API.
- **Veri Akışı:** Mobil ↔ Backend arasında HTTPS üzerinden JSON tabanlı iletişim; yapay zekâ sorguları backend üzerinden Gemini API'ye yönlendirilmektedir.

```
Flutter Mobil Uygulama
 ├─ Auth (Kayıt / Giriş / Oturum)
 ├─ Home / 4 Sekmeli Navigasyon
 ├─ Drug Search (Metin + Görsel)
 ├─ Photo Scan + Prospectus Summary
 ├─ Search / Scan History
 ├─ Drug Interaction Check
 ├─ Natural Alternatives
 └─ Medication Reminder + Stock Tracking

FastAPI Backend
 ├─ /health
 ├─ /api/auth/* (signup, login, me, logout)
 ├─ /api/drug/search
 ├─ /api/drug/analyze-image
 ├─ /api/drug/prospectus
 ├─ /api/drug/interaction
 └─ /api/drug/natural-alternatives
```

### 2.2 Mobil Teknoloji Yığını

| Teknoloji | Kullanım Amacı |
|-----------|----------------|
| **Flutter (Dart)** | Çapraz platform mobil uygulama geliştirme |
| **Riverpod** | Durum yönetimi (state management) |
| **Dio** | HTTP istemci katmanı |
| **GoRouter** | Deklaratif sayfa yönlendirme |
| **Hive** | Yerel NoSQL veri depolama |
| **flutter_secure_storage** | JWT token'ların şifrelenmiş saklanması |
| **camera / image_picker** | Kamera çekimi ve galeriden görsel seçme |
| **flutter_local_notifications** | Offline ilaç hatırlatıcı bildirimleri |
| **easy_localization** | Çoklu dil desteği (Türkçe / İngilizce) |
| **fpdart** | Fonksiyonel programlama (Either/Task pattern) |
| **Skeletonizer** | Yükleme durumu animasyonları |

### 2.3 Backend Teknoloji Yığını

| Teknoloji | Kullanım Amacı |
|-----------|----------------|
| **FastAPI (Python)** | Asenkron RESTful API sunucusu |
| **Google Gemini 2.5 Flash** | Yapay zekâ destekli ilaç analizi (metin + görsel) |
| **JWT + bcrypt** | Kimlik doğrulama ve parola güvenliği |
| **Redis** | API yanıt cache'leme (24 saat TTL) ve rate limiting |
| **Pillow (PIL)** | Görsel ön işleme (yeniden boyutlandırma, EXIF düzeltme) |
| **HTTPX** | Asenkron HTTP istemci (Gemini API çağrıları) |
| **Docker Compose** | Geliştirme ortamının konteynerizasyonu |

### 2.4 Yapay Zekâ Entegrasyonu — Google Gemini API

Projenin yapay zekâ bileşeni Google Gemini 2.5 Flash modeli üzerinden çalışmaktadır. Beş farklı prompt stratejisi tasarlanmış ve entegre edilmiştir:

| # | Prompt Türü | Giriş | Çıkış |
|---|-------------|-------|-------|
| 1 | **İlaç Arama** | İlaç adı (metin) | Etken madde, dozaj, kullanım, yan etkiler, uyarılar (JSON) |
| 2 | **Görsel Analiz** | İlaç kutusu fotoğrafı | Tanımlanan ilaç bilgileri + çoklu aday listesi |
| 3 | **Prospektüs Özeti** | Prospektüs görseli | Kategorize edilmiş özet (kullanım, dikkat, saklama vb.) |
| 4 | **Etkileşim Kontrolü** | İlaç listesi | Risk seviyesi (güvenli / dikkatli / tehlikeli) + detaylar |
| 5 | **Doğal Alternatifler** | İlaç adı | Bitkisel, beslenme ve yaşam tarzı önerileri |

Her prompt Türkçe ve yapılandırılmış JSON çıktı üretecek biçimde tasarlanmıştır. Multimodal çağrılarda görsel optimizasyonu (1400px max boyut, %82 JPEG sıkıştırma, EXIF döndürme düzeltmesi) uygulanarak API maliyeti ve yanıt süresi optimize edilmiştir.

### 2.5 Veri Kaynakları

Proje, geleneksel anlamda statik bir veri seti kullanmamaktadır. Bunun yerine Gemini büyük dil modeli kendi eğitim verisi üzerinden yanıt üretmektedir. Ek veri kaynakları:

- **Kullanıcı verileri:** Dosya tabanlı JSON deposu (geliştirme aşaması); üretim ortamı için PostgreSQL + SQLAlchemy altyapısı hazırlanmıştır.
- **Yerel veri:** Hive NoSQL veritabanı üzerinden arama geçmişi, tarama geçmişi ve hatırlatıcı verileri cihazda saklanmaktadır.
- **Cache katmanı:** Redis tabanlı 24 saatlik sorgu cache'i ve bellek içi fallback mekanizması.

### 2.6 Güvenlik Önlemleri

- **Kimlik doğrulama:** JWT (HS256, 7 gün süre) + bcrypt parola hash'leme.
- **Rate limiting:** IP bazlı kayar pencere algoritması ile dakikada 10 istek sınırı; cache hit'ler limite sayılmaz.
- **Token güvenliği:** Mobilde `flutter_secure_storage` ile şifrelenmiş depolama.
- **Veri güvenliği:** Cache'ten çekilen veriler `deepcopy()` ile klonlanarak yan etki riski ortadan kaldırılmıştır.
- **Thread safety:** Kullanıcı deposu mutex (`asyncio.Lock`) ile korunmaktadır.

---

## 3. Yapılan Çalışmalar ve Özet Bulgular

Proje, 9 Nisan 2026 tarihinde başlamış olup bir haftalık yoğun geliştirme sürecinde aşağıdaki fazlar tamamlanmıştır:

### 3.1 Tamamlanan Modüller

**FAZ 0 — Altyapı ve Kurulum:**
Backend ve mobil proje iskeletleri oluşturulmuş, ortam değişkenleri, CORS ayarları, sağlık kontrolü endpoint'i, Docker Compose yapılandırması ve temel paket entegrasyonları tamamlanmıştır.

**FAZ 1 — Temel İlaç Sorgulama (MVP):**
Kullanıcılar ilaç adı yazarak arama yapabilmekte ve Gemini API üzerinden etken madde, dozaj, kullanım şekli, yan etkiler ve uyarı bilgilerini detaylı olarak görüntüleyebilmektedir. Arama debounce (500ms), skeleton loading animasyonları, arama geçmişinin yerel depolanması (8 kayıt limiti) ve kapsamlı hata yönetimi (internet yok, API hatası, boş sonuç) tamamlanmıştır. Redis tabanlı 24 saatlik cache ve IP bazlı rate limiting sayesinde tekrarlayan sorguların maliyeti sıfırlanmıştır.

**FAZ 2 — Kamera ile İlaç Tanıma ve Prospektüs Tarama:**
Kamera veya galeriden seçilen ilaç kutusu fotoğrafı, Gemini multimodal API ile analiz edilmektedir. Reçete veya blister fotoğrafında birden fazla ilaç tespit edildiğinde çoklu aday akışı sunulmaktadır. Prospektüs fotoğrafından kullanım, dikkat, saklama koşulları ve yan etkiler gibi başlıklara ayrılmış kategorize özet üretilmektedir. Görsel ön işleme (1400px max boyut, %82 JPEG sıkıştırma, EXIF döndürme) ile API maliyeti ve yanıt süresi optimize edilmiştir.

**Ara Faz — Geçmiş Merkezi ve Profil Kısayolları:**
Arama geçmişi ve tarama geçmişi ekranları (12 kayıt limiti, görsel/prospektüs modu ayrımı) oluşturularak profil sekmesindeki kısayollarla entegre edilmiştir. Geçmişten tekrar sorgulama, tekli silme ve tümünü temizleme işlevleri eklenmiştir.

**FAZ 4 — İlaç Hatırlatıcı ve Stok Takibi:**
Tamamen offline çalışan ilaç hatırlatıcı sistemi kurulmuştur. Kullanıcı belirli saatlerde hatırlatıcı kurabilmekte, günlük tekrar eden yerel bildirimler alabilmektedir. Stok takip dashboard'unda kalan tablet sayısı, ilerleme çubuğu ve otomatik bitiş süresi hesaplanmaktadır. "Aldım" butonu ile stok otomatik azalmakta, 3 gün önceden düşük stok uyarısı verilmektedir. Bildirimler cihaz yeniden başlatması sonrasında da otomatik olarak yeniden kurulmaktadır.

**FAZ 5 — İlaç Etkileşim Kontrolü ve Doğal Alternatifler:**
Kullanıcılar birden fazla ilacı girerek aralarındaki etkileşimi kontrol edebilmektedir. Sonuçlar renk kodlarıyla (🟢 Güvenli, 🟡 Dikkatli, 🔴 Tehlikeli) ve detaylı açıklamalarla sunulmaktadır. Her ilaç için bitkisel, beslenme ve yaşam tarzı bazında doğal alternatif önerileri de entegre edilmiştir.

### 3.2 Kısmen Tamamlanan Modüller

**FAZ 3 — Kullanıcı Sistemi ve Aile Profili:**
JWT tabanlı kayıt, giriş, oturum yönetimi ve bcrypt parola güvenliği tamamlanmıştır. Aile profili yönetimi (aile bireyi ekleme, birey bazlı ilaç listesi) henüz geliştirilmemiştir.

### 3.3 Özet Bulgular

- Uygulama gerçek bir Android cihazda LAN bağlantısı üzerinden başarıyla test edilmiştir.
- Gemini API entegrasyonu beş farklı kullanım senaryosunda (metin arama, görsel analiz, prospektüs, etkileşim, doğal alternatif) kararlı çalışmaktadır.
- `flutter analyze` statik analiz kontrolü ve `flutter test` birim testleri sorunsuz geçmektedir.
- Redis cache katmanı sayesinde tekrarlayan ilaç sorgularında Gemini API maliyeti sıfıra düşmüştür.
- Rate limiting ile API'nin kötüye kullanımı engellenmiştir.
- Mobil uygulama 4 sekmeli ana sayfa, 10+ ekran ve offline çalışan hatırlatıcı desteğiyle MVP+ seviyesindedir.
- Toplam 6 backend endpoint, 10+ mobil ekran ve 2 test dosyası aktif olarak çalışmaktadır.

---

## 4. Final İçin Yapılabilecekler ve Beklenen Etki

### 4.1 Planlanan Geliştirmeler

| Faz | Modül | Açıklama | Tahmini Süre |
|-----|-------|----------|-------------|
| FAZ 3 (tamamlama) | Aile Profili | Aile bireyi ekleme, birey bazlı ilaç listesi yönetimi, senkronizasyon | 1-2 hafta |
| FAZ 6 | Nöbetçi Eczane + Sesli Sorgu | Konum bazlı nöbetçi eczane bulma, harita entegrasyonu, Türkçe sesli ilaç arama | 1-2 hafta |
| FAZ 7 | Acil Durum Kartı | Kan grubu, alerji, kronik hastalık bilgileri; PDF dışa aktarım; sağlık günlüğü | 1 hafta |
| FAZ 8 | Test ve Yayın | UI polish, karanlık mod, onboarding, kapsamlı test, Play Store yayını | 1-2 hafta |

### 4.2 Beklenen Etkiler

**Bireysel Etki:**
- Kullanıcılar ilaç bilgilerine metin, fotoğraf veya ses yoluyla hızlı ve anlaşılır biçimde erişebilecek.
- İlaç etkileşim riskleri proaktif olarak tespit edilerek olası sağlık sorunlarının önüne geçilebilecek.
- Hatırlatıcı ve stok takip sistemiyle tedaviye uyum oranı artırılabilecek.

**Toplumsal Etki:**
- Aile profili ile özellikle yaşlı bireyler ve çocuklar için merkezi ilaç takibi sağlanacak.
- Sesli sorgulama ile yaşlı veya görme engelli kullanıcılar da uygulamaya erişebilecek.
- Nöbetçi eczane entegrasyonu ile gece/tatil günü eczane arama sorunu çözülecek.
- Acil durum kartı kritik sağlık bilgilerini tek ekranda sunarak acil müdahaleyi hızlandıracak.

**Teknik ve Akademik Katkı:**
- Büyük dil modellerinin (LLM) sağlık alanındaki pratik kullanımına somut bir örnek oluşturulacak.
- Multimodal yapay zekâ (metin + görsel) entegrasyonunun mobil sağlık uygulamalarındaki potansiyeli ortaya konacak.
- Flutter + FastAPI + Gemini API üçlüsünün Clean Architecture prensipleriyle bir arada kullanıldığı teknik bir referans proje sunulacak.

---

## 5. Sonuç

Proje, 9 Nisan 2026'da başlamış olup bir haftalık yoğun geliştirme sürecinde sekiz fazlık yol haritasının beşi (FAZ 0, 1, 2, 4, 5) ve bir ara fazı başarıyla tamamlanmıştır. Uygulama; metin ve görsel tabanlı ilaç sorgulama, prospektüs özetleme, ilaç etkileşim kontrolü, doğal alternatif önerileri, offline ilaç hatırlatıcı ve stok takibi gibi çekirdek özelliklerle çalışan bir MVP+ seviyesindedir.

Backend tarafında JWT kimlik doğrulama, Redis cache, rate limiting ve görsel optimizasyonu; mobil tarafta Clean Architecture, Riverpod durum yönetimi, Hive yerel depolama ve offline bildirim altyapısı kurulmuştur. Tüm modüller gerçek Android cihazda test edilmiştir.

Final döneminde aile profili tamamlama, nöbetçi eczane entegrasyonu, sesli sorgulama, acil durum kartı ve Play Store yayını fazlarının gerçekleştirilmesi planlanmaktadır.

| Gösterge | Değer |
|----------|-------|
| Tamamlanan faz sayısı | 5 + 1 ara faz |
| Kalan faz sayısı | 3 (+ 1 kısmi) |
| Toplam backend endpoint | 6 aktif |
| Toplam mobil ekran | 10+ |
| Yapay zekâ prompt türü | 5 farklı senaryo |
| Test durumu | flutter analyze ✓, flutter test ✓ |
| Gerçek cihaz doğrulaması | Android (LAN üzerinden) ✓ |

> **Sorumluluk reddi:** Bu uygulama genel bilgilendirme amaçlıdır ve tıbbi tavsiye niteliği taşımamaktadır. Kullanıcılar, ilaç kullanımıyla ilgili konularda mutlaka bir sağlık profesyoneline danışmalıdır.
