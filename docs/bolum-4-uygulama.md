4. UYGULAMA

Bu bölümde Eczanem'in her bir modülünün implementasyon detayları, prompt mühendisliği kararları, veri modelleri, API endpoint yapısı ve kullanıcı arayüzü akışları aktarılmaktadır.


4.1 Proje Yapısı ve Teknik Altyapı

**4.1.1 Mobil Uygulama Bağımlılıkları**

Uygulamanın temel bağımlılıkları aşağıda listelenmiştir:

| Paket | Sürüm | Amaç |
|---|---|---|
| flutter_riverpod | 2.6.1 | Reaktif durum yönetimi |
| riverpod_annotation | 2.6.1 | Kod üretimi için anotasyon |
| fpdart | 1.2.0 | Railway Oriented Programming |
| dio | 5.9.2 | HTTP istemcisi |
| hive_flutter | 1.1.0 | Yerel NoSQL depolama |
| flutter_secure_storage | 10.0.0 | JWT güvenli depolama |
| go_router | 17.1.0 | Bildirimsel navigasyon |
| flutter_local_notifications | 19.4.2 | Çevrimdışı hatırlatıcı |
| flutter_map | 7.0.2 | OSM tabanlı harita |
| geolocator | 13.0.2 | GPS konum erişimi |
| easy_localization | 3.0.8 | TR/EN çoklu dil desteği |
| image_picker | 1.1.2 | Kamera / galeri erişimi |
| cached_network_image | 3.4.1 | Görüntü önbellekleme |

**4.1.2 Backend Bağımlılıkları**

| Paket | Sürüm | Amaç |
|---|---|---|
| fastapi | 0.115+ | Web çerçevesi |
| google-generativeai | 0.8+ | Gemini API istemcisi |
| python-jose | 3.3+ | JWT üretimi/doğrulaması |
| passlib[bcrypt] | 1.7+ | Parola hash'leme |
| redis | 5.0+ | Önbellek istemcisi |
| beautifulsoup4 | 4.12+ | Web kazıma |
| httpx | 0.27+ | Eşzamansız HTTP |
| Pillow | 10.0+ | Görüntü ön işleme |
| pydantic-settings | 2.0+ | Ortam değişkeni yönetimi |


4.2 İlaç Arama Modülü (drug_search)

**4.2.1 Kullanıcı Akışı**

Kullanıcı ana ekrandaki arama çubuğuna ilaç adı veya etken madde girer. İstek backend `/drug/search` endpoint'ine iletilir. Sonuç, Redis veya bellek içi önbellekten karşılanıyorsa doğrudan döndürülür; aksi takdirde Gemini 2.5 Flash modeli sorgulanır.

**4.2.2 Prompt Tasarımı**

```
Rol: "Sen bir eczacı asistanısın."
Görev: Verilen ilaç adı için kullanım alanlarını, yan etkilerini,
       kontrendikasyonlarını ve genel doz bilgisini JSON formatında üret.
Kısıt: Kesin tanı veya tedavi önerme; yalnızca genel bilgi sun.
Format: Yapılandırılmış JSON şeması
```

**4.2.3 Önbellek Mekanizması**

Sorgu metni normalize edilerek (küçük harf, boşluk temizleme) MD5 hash'i hesaplanır ve Redis anahtarı olarak kullanılır. Önbellek isabeti (cache hit) durumunda Gemini API çağrısından tamamen kaçınılır; bu yaklaşım API maliyetini ve gecikme süresini ciddi ölçüde düşürmektedir.


4.3 Görüntüden İlaç Tanıma Modülü (drug_scan)

**4.3.1 Görüntü İşleme Akışı**

Kullanıcı kamera veya galeriden bir fotoğraf seçer. Flutter tarafında `image_picker` ile alınan görüntü byte verisi olarak backend'e `multipart/form-data` ile gönderilir. Backend'de Pillow, görüntüyü yeniden boyutlandırır (maksimum 1400×1400 piksel), EXIF yönlendirmesini normalleştirir ve Base64 formatına kodlar.

**4.3.2 Desteklenen Analiz Türleri**

Görsel tabanlı analiz iki ayrı endpoint üzerinden sunulmaktadır:
- **`/drug/analyze-image` — İlaç Kutusu Tanıma:** Ambalaj fotoğrafından ilaç adı, etken madde ve üretici bilgisi çıkarılır. Yanıt `aday_ilaclar` listesiyle birden fazla eşleşmeyi destekler.
- **`/drug/prospectus` — Prospektüs Özetleme:** Kağıt prospektüs fotoğrafından kullanım talimatları, saklama koşulları, uyarılar ve yan etkiler yapılandırılmış `ProspectusSummaryResponse` formatında özetlenir.


4.4 İlaç Etkileşim Analizi Modülü

`/drug/interaction` endpoint'i, kullanıcının girdiği iki veya daha fazla ilaç arasındaki olası etkileşimleri analiz eder. Risk seviyesi düşük / orta / yüksek olarak sınıflandırılır. Yüksek riskli etkileşim tespit edildiğinde kullanıcı arayüzünde uyarı kartı gösterilir.

**4.4.1 Güvenlik Yaklaşımı**

Her etkileşim yanıtına "Bu bilgiler bilgilendirme amaçlıdır. İlaç etkileşimleri için doktorunuza veya eczacınıza danışınız." uyarısı otomatik eklenmektedir.


4.5 Semptom Değerlendirme Modülü

`/drug/symptom-check` endpoint'i, kullanıcının doğal dilde aktardığı semptomları analiz ederek olası nedenler, aciliyeti ve önerilen adımlar hakkında yapılandırılmış çıktı üretir. `SymptomAnalysisResponse` şemasında `acil_durum: bool` alanı yer almaktadır; bu alan `true` döndüğünde kullanıcıya acil yardım alma yönlendirmesi yapılmaktadır.


4.6 Sağlık Asistanı Sohbeti Modülü

`/drug/chat` endpoint'i, kullanıcı ile çok turlu (multi-turn) konuşmayı yönetir. Sohbet geçmişi (~50 mesaj) her istekle birlikte Gemini'ye bağlam olarak iletilerek tutarlılık sağlanır. Bu modülde `temperature` değeri diğer modüllere kıyasla biraz daha yüksek tutulabilmekte; ancak yapılandırılmış JSON çıktı zorunluluğu yoktur.


4.7 Çevrimdışı İlaç Hatırlatıcısı Modülü (medication_reminder)

**4.7.1 Veri Modeli**

```dart
// Hive TypeAdapter ile yerel depolamada saklanır
class MedicationReminder {
  final String id;         // UUID
  final String drugName;   // İlaç adı
  final List<String> times; // ["08:00", "20:00"]
  final List<int> days;    // [1,2,3,4,5,6,7] (haftanın günleri)
  final String dosage;     // "1 tablet"
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
}
```

Hive anahtar değeri: `medication_reminders_v1`

**4.7.2 Bildirim Stratejisi**

Her hatırlatıcı için Android `ALARM` kanalı kullanılır; `wakeLockTimeout` ile ekran kilitli durumlarda da çalışması sağlanır. iOS'ta `UNTimeIntervalNotificationTrigger` kullanılarak yerel tetikleyiciler planlanır. Backend bağlantısı olmadan tamamen çalışır.


4.8 Nöbetçi Eczane Haritası Modülü (pharmacy_map)

**4.8.1 Veri Akışı**

Kullanıcı konumu → Nominatim → il/ilçe → `/pharmacy/nearby` → BeautifulSoup4 scraping → Eczane listesi → Nominatim koordinat çözümlemesi → flutter_map pin'leri

**4.8.2 Hata Toleransı**

Nominatim isteği başarısız olursa kullanıcı il/ilçe seçimini manuel gerçekleştirebilir (`/pharmacy/districts` endpoint'i ilçe listesini döndürür). Koordinat bulunamayan eczaneler haritada gösterilmez fakat liste görünümünde yer almaya devam eder.


4.9 Yerel Veri Depolama Mimarisi (Hive)

Tüm kişisel sağlık verileri Hive NoSQL deposunda anahtar-değer çiftleri olarak saklanmaktadır:

| Hive Anahtarı | Veri Tipi | İçerik |
|---|---|---|
| `medication_reminders_v1` | List<MedicationReminder> | Hatırlatıcılar |
| `drug_search_history` | List<DrugSearchHistory> | Arama geçmişi |
| `drug_scan_history` | List<DrugScanHistory> | Tarama geçmişi |
| `health_notes` | List<HealthNote> | Sağlık notları |
| `emergency_card` | EmergencyCard | Acil durum kartı |
| `family_members` | List<FamilyMember> | Aile profilleri (yerel) |

Aile profilleri PostgreSQL ile buluta senkronize edilebilmektedir (isteğe bağlı).


4.10 Kimlik Doğrulama Akışı

**4.10.1 Kayıt ve Giriş**

1. `POST /auth/signup` → bcrypt ile parola hash'lenir, kullanıcı `users.json`'a (geliştirme) veya PostgreSQL'e (prodüksiyon) yazılır.
2. `POST /auth/login` → Parola doğrulandıktan sonra HS256 imzalı 7 günlük JWT üretilir.
3. Token Flutter'da `flutter_secure_storage` ile şifreli depoya yazılır.
4. Sonraki isteklerde `Authorization: Bearer <token>` başlığıyla gönderilir.

**4.10.2 Rota Koruma Stratejisi**

GoRouter `redirect` fonksiyonunda token varlığı kontrol edilir. Token yoksa `/login` rotasına yönlendirilir. İlk açılışta onboarding sayfası gösterilir ve tamamlanma durumu `SharedPreferences`'da saklanır.


4.11 Çoklu Dil Desteği (Lokalizasyon)

`easy_localization 3.0.8` kütüphanesi, JSON tabanlı çeviri dosyaları (`assets/translations/tr.json`, `assets/translations/en.json`) üzerinden TR/EN lokalizasyonu yönetir. Dil tercihi `SharedPreferences`'da saklanır ve uygulama yeniden başlatıldığında korunur. Tüm kullanıcı arayüzü metinleri lokalizasyon anahtarları aracılığıyla erişilir; sabit kodlanmış Türkçe/İngilizce metin bulunmamaktadır.


4.12 Prompt Mühendisliği Özeti

Sistemdeki 7 AI görevi için geliştirilen promptların ortak özellikleri:

1. **Rol Atama:** "Sen bir eczacı asistanısın." — modeli alan uzmanı olarak konumlandırır.
2. **Yapılandırılmış Çıktı:** `response_mime_type: "application/json"` + JSON şema tanımı — parse hatasını engeller.
3. **Güvenlik Kısıtı:** Her promptta kesin tanı/tedavi önermeme yönergesi yer alır.
4. **Dil Kısıtı:** Yanıt her zaman Türkçe talep edilir; İngilizce sızma riski minimize edilir.
5. **Düşük Sıcaklık:** `temperature=0.3` — ilaç bilgisi gibi hassas alanlarda tutarlılık sağlar.
