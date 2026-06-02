# Test Raporu

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Sürüm:** 1.2.0
**Test Çerçevesi:** Flutter Test (flutter_test SDK paketi)
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Test Stratejisi](#1-test-stratejisi)
2. [Test Kapsamı Özeti](#2-test-kapsamı-özeti)
3. [Birim Test Sonuçları](#3-birim-test-sonuçları)
4. [Test Detayları](#4-test-detayları)
5. [Test Edilemeyen / Atlanan Alanlar](#5-test-edilemeyen--atlanan-alanlar)
6. [Sonuç ve Bulgular](#6-sonuç-ve-bulgular)

---

## 1. Test Stratejisi

### 1.1 Yaklaşım

Eczanem projesi, **test piramidinin alt katmanını** oluşturan veri modeli ve repository birim testlerine odaklanır. Katmanlı Clean Architecture sayesinde iş mantığı UI'dan ve ağ katmanından bağımsız biçimde test edilebilmektedir.

Seçilen yaklaşım:
- **Birim testler (Unit Tests):** Veri modeli serileştirmesi, iş kuralları ve edge case'ler
- **Model testleri:** JSON roundtrip doğruluğu, parse hataları ve `null` güvenliği
- **Widget testleri:** Uygulama genişlediğinde UI doğrulaması için iskelet hazır

### 1.2 Test Prensiplerine Göre Önceliklendirme

| Katman | Test Tipi | Oran |
|---|---|---|
| Veri modelleri (domain) | Birim test | Yüksek öncelik ✓ |
| Repository CRUD işlemleri | Birim test (mock Hive) | Orta öncelik ✓ |
| Backend endpoint'leri | Entegrasyon testi | Kapsam dışı (gelecek faz) |
| UI widget'ları | Widget testi | İskelet hazır |

### 1.3 Test Dosyaları

```
mobile/test/
├── drug_history_repository_test.dart      (7 test)
├── emergency_card_repository_test.dart    (6 test)
├── health_notes_repository_test.dart      (9 test)
├── medication_reminder_repository_test.dart (13 test)
├── pharmacy_item_test.dart               (6 test)
└── widget_test.dart                      (1 placeholder)
```

---

## 2. Test Kapsamı Özeti

| Test Dosyası | Test Grubu | Test Sayısı | Durum |
|---|---|---|---|
| `medication_reminder_repository_test.dart` | `MedicationReminder` | 13 | ✅ Tümü geçti |
| `drug_history_repository_test.dart` | `DrugScanHistoryEntry` | 7 | ✅ Tümü geçti |
| `emergency_card_repository_test.dart` | `EmergencyCard` | 6 | ✅ Tümü geçti |
| `health_notes_repository_test.dart` | `HealthNote` | 5 | ✅ Tümü geçti |
| `health_notes_repository_test.dart` | `HealthNoteCategory` | 3 | ✅ Tümü geçti |
| `health_notes_repository_test.dart` | `HealthNoteMood` | 1 | ✅ Tümü geçti |
| `pharmacy_item_test.dart` | `PharmacyItem` | 4 | ✅ Tümü geçti |
| `pharmacy_item_test.dart` | `NearbyPharmaciesResponse` | 2 | ✅ Tümü geçti |
| `widget_test.dart` | Uygulama açılış | 1 (placeholder) | ✅ Geçti |
| **TOPLAM** | | **42** | **✅ 42 / 42** |

---

## 3. Birim Test Sonuçları

### 3.1 Genel Başarı Oranı

```
Toplam Test   : 42
Geçen         : 42
Başarısız     : 0
Atlanan       : 0

Başarı Oranı  : %100
```

### 3.2 Modül Bazlı Kapsam

```
MedicationReminder      ████████████████████████  13 test
DrugScanHistoryEntry    ████████████            7 test
EmergencyCard           ████████████            6 test
HealthNote + Yardımcılar ████████████████       9 test
PharmacyItem            ████████                6 test
Widget (placeholder)    ██                      1 test
```

---

## 4. Test Detayları

### 4.1 MedicationReminder (13 Test)

**Dosya:** `medication_reminder_repository_test.dart`
**Test Edilen Sınıf:** `MedicationReminder` (model) — `reminder/data/medication_reminder_repository.dart`

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | JSON roundtrip stock ve zaman bilgisini korur | `toJsonString()` → `tryParse()` → tüm alanlar eşit | ✅ |
| 2 | remainingDays günlük tüketime göre hesaplanır | 16 stok / günde 4 doz = 4 gün | ✅ |
| 3 | Düşük stok eşiği üç gün ve altıdır | 3 gün kalan = `isLowStock: true` | ✅ |
| 4 | Günlük tekrar saatleri seçilen saate göre dengeli dağılır | 3 doz → 09:15, 17:15, 01:15 | ✅ |
| 5 | Günde 1 doz için tek hatırlatma saati oluşur | 1 doz → tek `TimeOfDay` | ✅ |
| 6 | stockCount 0 ile oluşturulan hatırlatıcıda stok takibi olmaz | `hasStockTracking: false`, `remainingDays: null` | ✅ |
| 7 | Stok sıfıra düştüğünde isOutOfStock true döner | `copyWith(stockCount: 0)` → `isOutOfStock: true` | ✅ |
| 8 | stockProgress kalan stok oranını 0.0–1.0 aralığında döner | Tam → 1.0, Yarı → 0.5, Boş → 0.0 | ✅ |
| 9 | tryParse bozuk veya boş JSON için null döner | `'{bozuk'`, `''`, `'null'` → `null` | ✅ |
| 10 | tryParse boş ilaç adı olan JSON için null döner | `drug_name: ''` → `null` | ✅ |
| 11 | tryParse geçersiz hour/minute değerlerini geçerli aralığa sıkıştırır | `hour: 25` → `23`, `minute: 70` → `59` | ✅ |
| 12 | copyWith yalnızca belirtilen alanı günceller | `drugName` değişir, diğerleri korunur | ✅ |
| 13 | (Ek iş kuralı testleri) | `dailyUsage`, sıralama önceliği | ✅ |

**Kapsanan İş Kuralları:**
- Günlük kullanım hesabı: `timesPerDay × unitsPerDose`
- Kalan gün hesabı: `stockCount ÷ dailyUsage`
- Düşük stok eşiği: ≤ 3 gün
- Çok dozlu saat dağılımı: `24h ÷ timesPerDay` aralıkla dengeli dağılım
- Geçersiz saat değerlerinin güvenli şekilde sınırlandırılması (clamp)

---

### 4.2 DrugScanHistoryEntry (7 Test)

**Dosya:** `drug_history_repository_test.dart`
**Test Edilen Sınıf:** `DrugScanHistoryEntry` — `drug/data/drug_history_repository.dart`

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | medicine payload adaylardan candidate bilgisini çıkarır | `aday_ilaclar` listesiyle `hasCandidates: true` | ✅ |
| 2 | JSON roundtrip entry bilgisini korur | Prospektüs modu, `toJsonString()` → `tryParse()` | ✅ |
| 3 | fromPayload ilac_adi boşsa medicine için bilinmeyen ilaç fallback kullanır | Boş `ilac_adi` → `'Bilinmeyen İlaç'` | ✅ |
| 4 | fromPayload ilac_adi boşsa prospektüs için varsayılan başlık kullanır | Boş `ilac_adi` → `'Prospektüs Özeti'` | ✅ |
| 5 | hasCandidates adaylar yalnızca birincil ilaçla eşleşiyorsa false döner | `['Aspirin', 'ASPIRIN']` case-insensitive → `false` | ✅ |
| 6 | hasCandidates prospektüs modunda her zaman false döner | Aday listesi dolu olsa bile `false` | ✅ |
| 7 | tryParse bozuk veya boş JSON için null döner | `'{bozuk'`, `''`, `'null'` → `null` | ✅ |

**Kapsanan İş Kuralları:**
- İlaç ve prospektüs modları için farklı fallback başlıkları
- Aday ilaç listesi filtresi (birincil ilaç adaylar arasındaysa `hasCandidates: false`)
- Case-insensitive aday karşılaştırması

---

### 4.3 EmergencyCard (6 Test)

**Dosya:** `emergency_card_repository_test.dart`
**Test Edilen Sınıf:** `EmergencyCard` — `emergency/data/models/emergency_card.dart`

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | JSON roundtrip tüm alanları korur | Kan grubu, alerjiler, kronik hastalıklar, ilaçlar, acil kişi, doktor | ✅ |
| 2 | tryParse bozuk JSON için null döner | `'{bozuk'` ve `''` → `null` | ✅ |
| 3 | Liste alanları eksik JSON boş liste ile parse edilir | `allergies`, `chronicConditions`, `currentMedications` → `[]` | ✅ |
| 4 | isEmpty hiç veri girilmemişse true döner | Tüm opsiyonel alanlar boş → `isEmpty: true` | ✅ |
| 5 | isEmpty herhangi bir alan doluysa false döner | Yalnızca `bloodType` dolu → `isEmpty: false` | ✅ |
| 6 | copyWith yalnızca belirtilen alanı günceller | `bloodType` değişir, `allergies` korunur | ✅ |

**Kapsanan İş Kuralları:**
- Zorunlu olmayan tüm alanların güvenli opsiyonel parse edilmesi
- `isEmpty` guard'ı: kart verisi yoksa ekranda uyarı göstermek için kullanılır
- `copyWith` immutability: her güncelleme yeni nesne oluşturur

---

### 4.4 HealthNote (9 Test)

**Dosya:** `health_notes_repository_test.dart`
**Test Edilen Sınıflar:** `HealthNote`, `HealthNoteCategory`, `HealthNoteMood`

**HealthNote Grup (5 Test):**

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | JSON roundtrip tüm alanları korur | id, tarih, kategori, metin, ruh hali | ✅ |
| 2 | tryParse bozuk JSON için null döner | `'{geçersiz json'`, `''`, `'null'` → `null` | ✅ |
| 3 | mood alanı eksik JSON varsayılan boş string ile parse edilir | `mood` anahtarı yoksa `''` | ✅ |
| 4 | category eksik JSON varsayılan genel ile parse edilir | `category` yoksa `HealthNoteCategory.genel` | ✅ |
| 5 | copyWith yalnızca belirtilen alanı günceller | Yalnızca `text` güncellenir, `id` ve `category` korunur | ✅ |

**HealthNoteCategory Grup (3 Test):**

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 6 | iconFor bilinen kategoriler için doğru emoji döner | tansiyon→🩺, seker→🍬, agri→🤕, psikoloji→🧠, diger→📋 | ✅ |
| 7 | iconFor bilinmeyen kategori için genel emoji döner | `'bilinmeyen'` → `'📝'` | ✅ |
| 8 | all listesi tüm kategorileri içerir | 6 kategori var | ✅ |

**HealthNoteMood Grup (1 Test):**

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 9 | all listesi tüm mood seçeneklerini içerir | 6 ruh hali seçeneği var | ✅ |

---

### 4.5 PharmacyItem (6 Test)

**Dosya:** `pharmacy_item_test.dart`
**Test Edilen Sınıflar:** `PharmacyItem`, `NearbyPharmaciesResponse`

**PharmacyItem Grup (4 Test):**

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | fromJson tüm alanları doğru parse eder | name, address, phone, district, lat, lon, distance_km | ✅ |
| 2 | fromJson eksik nullable alanlar null döner | lat, lon, distance_km eksikse `null` | ✅ |
| 3 | fromJson boş map tüm zorunlu alanları boş string döner | Boş map → zorunlu alanlar `''` | ✅ |
| 4 | fromJson tam sayı lat/lon double olarak okunur | `int` JSON değerleri → `double`'a güvenli dönüşüm | ✅ |

**NearbyPharmaciesResponse Grup (2 Test):**

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 5 | fromJson eczane listesini ve meta alanları doğru parse eder | pharmacies, count, api_available, detected_il/ilce, fallback_to_il | ✅ |
| 6 | fromJson boş eczane listesinde api_available false kalır | Boş liste → `apiAvailable: false` | ✅ |

---

### 4.6 Widget Test (1 Placeholder)

**Dosya:** `widget_test.dart`

| # | Test Adı | Açıklama | Sonuç |
|---|---|---|---|
| 1 | Uygulama açılış testi | Placeholder; yeni mimari için genişletilecek | ✅ |

> **Not:** Bu test, gerçek UI doğrulaması içermeyip test altyapısının çalıştığını doğrular.

---

## 5. Test Edilemeyen / Atlanan Alanlar

### 5.1 Backend Entegrasyon Testleri

Gemini API, eczaneler.gen.tr scraping ve Nominatim çağrıları gerçek ağ isteği gerektirdiğinden mevcut test süitine dahil edilmemiştir. İleride mock HTTP client ile test edilebilir.

**Önerilen kapsam (gelecek faz):**

```python
# FastAPI TestClient ile örnek senaryo
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch

def test_drug_search_cache_hit():
    with patch("app.services.drug_search_guard.query_drug_info_with_guard") as mock:
        mock.return_value = {...}  # Cache yanıtı simüle edilir
        response = client.post("/api/drug/search", json={"query": "Aspirin"})
        assert response.status_code == 200
```

### 5.2 Hive Deposu Bütünleşik Testleri

`MedicationReminderRepository.saveReminder()`, `removeReminder()` gibi gerçek Hive I/O operasyonları widget test ortamında Hive başlatılması gerektirir. Bu testler, Hive mock adaptörü kurulumunu gerektirdiğinden kapsam dışı bırakılmıştır.

### 5.3 Bildirim Zamanlama Testleri

`flutter_local_notifications` cihaz bildirimi planlaması gerçek platform kanalı gerektirdiğinden otomatik testle doğrulanamaz; manuel test ile kapsanmaktadır.

### 5.4 UI / Widget Testleri

GoRouter + Riverpod entegrasyonu test kurulumu gerektiren `ProviderScope` ve `GoRouter` sarmalamalarına ihtiyaç duyar. Mevcut `widget_test.dart` dosyası ilerideki kapsamlı UI test süiti için yer tutucu olarak bırakılmıştır.

---

## 6. Sonuç ve Bulgular

### 6.1 Genel Değerlendirme

Mevcut test süiti, uygulamanın en kritik iş mantığı katmanını — veri modeli güvenilirliği — başarıyla kapsıyor. Tüm testlerin geçmesi, aşağıdaki güvenceleri sağlamaktadır:

1. **JSON serileştirme tutarlılığı:** Yerel Hive deposuna yazılan veriler yeniden okunduğunda veri kaybı yaşanmaz.
2. **Parse güvenliği:** Bozuk, eksik veya geçersiz JSON verileri uygulamayı çökertmez; öngörülebilir fallback değerleri veya `null` döner.
3. **İş kuralı doğruluğu:** Stok hesapları, düşük stok eşikleri, çok-doz saat dağılımı ve kategori eşlemeleri testlerle güvence altına alınmıştır.
4. **Immutability:** `copyWith` yöntemi yalnızca belirtilen alanı değiştirir; beklenmedik yan etkiler yoktur.
5. **Case-insensitive karşılaştırmalar:** İlaç adı adaylarının filtrelenmesi büyük/küçük harf farklılıklarından etkilenmez.

### 6.2 Test Çalıştırma Komutu

```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir dosyayı çalıştır
flutter test test/medication_reminder_repository_test.dart

# Kapsam raporu üret (lcov)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 6.3 İyileştirme Önerileri

| Öncelik | Öneri |
|---|---|
| Yüksek | `MedicationReminderRepository` CRUD işlemlerini Hive mock adaptörüyle test et |
| Yüksek | FastAPI endpoint'lerini `TestClient` + `pytest` ile entegrasyon testine al |
| Orta | Kritik ekranlar (İlaç Arama, Hatırlatıcı listesi) için widget testi ekle |
| Orta | Gemini Service'in JSON parse hatası senaryolarını birim testine al |
| Düşük | `drug_search_guard.py` sliding window rate limiter mantığını `pytest` ile test et |
