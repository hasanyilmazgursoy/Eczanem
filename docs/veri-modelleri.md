# Veri Modelleri

**Proje:** Eczanem — Yapay Zekâ Destekli Kişisel İlaç Yönetim Sistemi
**Sürüm:** 1.2.0
**Tarih:** Haziran 2026

---

## İçindekiler

1. [Genel Bakış](#1-genel-bakış)
2. [Flutter Dart Modelleri](#2-flutter-dart-modelleri)
   - 2.1 [MedicationReminder](#21-medicationreminder)
   - 2.2 [EmergencyCard](#22-emergencycard)
   - 2.3 [HealthNote](#23-healthnote)
   - 2.4 [DrugScanHistoryEntry](#24-drugscanhistoryentry)
   - 2.5 [PharmacyItem / NearbyPharmaciesResponse](#25-pharmacyitem--nearbypharmaciesresponse)
   - 2.6 [FamilyMember / FamilyMemberDrug](#26-familymember--familymemberdrug)
   - 2.7 [AppUser](#27-appuser)
3. [Hive Yerel Depolama Anahtarları](#3-hive-yerel-depolama-anahtarları)
4. [Backend Pydantic Şemaları](#4-backend-pydantic-şemaları)
   - 4.1 [Auth Şemaları](#41-auth-şemaları)
   - 4.2 [Drug Şemaları](#42-drug-şemaları)
   - 4.3 [Pharmacy Şemaları](#43-pharmacy-şemaları)
   - 4.4 [Profile Şemaları](#44-profile-şemaları)
5. [JSON Temsil Örnekleri](#5-json-temsil-örnekleri)

---

## 1. Genel Bakış

Eczanem uygulaması iki katmanlı bir veri modeli mimarisi kullanır:

- **Mobil (Dart):** Tüm yerel veriler Hive key-value store üzerinde JSON string olarak saklanır. Modeller `toJson()` / `fromJson()` / `tryParse()` metodlarıyla serileştirme / deserileştirme yönetir.
- **Backend (Python):** Pydantic `BaseModel` sınıfları, FastAPI endpoint'lerinde hem istek doğrulaması hem de yanıt şeması olarak kullanılır.

Veriler arasındaki sınır Dio HTTP katmanından geçer; mobil `DomainModel ↔ JsonMap` dönüşümünü, backend `JsonMap ↔ PydanticModel` dönüşümünü gerçekleştirir.

---

## 2. Flutter Dart Modelleri

### 2.1 MedicationReminder

**Konum:** `mobile/lib/src/features/reminder/data/medication_reminder_repository.dart`
**Hive anahtarı:** `medication_reminders_v1`

İlaç hatırlatıcı kaydı. `flutter_local_notifications` ile yerel bildirim zamanlaması bu model üzerinden yönetilir.

#### Alanlar

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `id` | `String` | `id` | Benzersiz kimlik — `microsecondsSinceEpoch` |
| `drugName` | `String` | `drug_name` | İlaç adı |
| `hour` | `int` | `hour` | Hatırlatma saati (0–23) |
| `minute` | `int` | `minute` | Hatırlatma dakikası (0–59) |
| `timesPerDay` | `int` | `times_per_day` | Günlük doz sayısı |
| `unitsPerDose` | `int` | `units_per_dose` | Tek seferde alınan birim |
| `stockCount` | `int` | `stock_count` | Mevcut stok miktarı |
| `initialStockCount` | `int` | `initial_stock_count` | Başlangıç stok miktarı |
| `isActive` | `bool` | `is_active` | Hatırlatıcı aktif mi |
| `useAlarm` | `bool` | `use_alarm` | DND'yi bypass eden alarm kanalı |
| `notes` | `String?` | `notes` | Opsiyonel not |
| `createdAt` | `DateTime` | `created_at` | Oluşturma zamanı |
| `updatedAt` | `DateTime` | `updated_at` | Güncelleme zamanı |
| `lastTakenAt` | `DateTime?` | `last_taken_at` | Son ilaç alma zamanı |

#### Hesaplanan Özellikler

| Özellik | Formül | Açıklama |
|---|---|---|
| `dailyUsage` | `unitsPerDose × timesPerDay` | Günlük tüketim birimi |
| `remainingDays` | `stockCount ÷ dailyUsage` | Tahminen kaç gün yetecek |
| `isLowStock` | `remainingDays ≤ 3` | Düşük stok uyarısı |
| `stockProgress` | `stockCount ÷ initialStockCount` | 0.0–1.0 arasında stok yüzdesi |
| `reminderTimes` | `(hour*60 + minute + interval*i) % 1440` | Gün içine dengeli dağıtılmış saatler |

---

### 2.2 EmergencyCard

**Konum:** `mobile/lib/src/features/emergency/data/models/emergency_card.dart`
**Hive anahtarı:** `emergency_card`
**Depolama stratejisi:** Singleton — kullanıcı başına tek kayıt.

Acil durum kartı. Kan grubu, alerji listesi, kronik hastalıklar ve acil iletişim bilgilerini barındırır.

#### Alanlar

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `bloodType` | `String` | `blood_type` | Kan grubu (örn. "A Rh+") |
| `allergies` | `List<String>` | `allergies` | Alerji listesi |
| `chronicConditions` | `List<String>` | `chronic_conditions` | Kronik hastalıklar |
| `currentMedications` | `List<String>` | `current_medications` | Düzenli kullanılan ilaçlar |
| `emergencyContactName` | `String` | `emergency_contact_name` | Acil iletişim kişisi adı |
| `emergencyContactPhone` | `String` | `emergency_contact_phone` | Acil iletişim kişisi telefonu |
| `doctorName` | `String` | `doctor_name` | Doktor adı |
| `doctorPhone` | `String` | `doctor_phone` | Doktor telefonu |
| `notes` | `String` | `notes` | Ek notlar |
| `updatedAt` | `DateTime` | `updated_at` | Son güncelleme zamanı |

#### Mantıksal Özellik

| Özellik | Koşul |
|---|---|
| `isEmpty` | Tüm alanlar boş / liste alanlar boş listeyse |

---

### 2.3 HealthNote

**Konum:** `mobile/lib/src/features/health_notes/data/models/health_note.dart`
**Hive anahtarı:** `health_notes`

Sağlık günlüğü kaydı. Klinik ölçüm alanları (tansiyon, kan şekeri, ağrı) kategori seçimine göre opsiyonel olarak doldurulur.

#### Alanlar

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `id` | `String` | `id` | Benzersiz kimlik — `microsecondsSinceEpoch` |
| `date` | `DateTime` | `date` | Notun tarihi |
| `category` | `String` | `category` | Not kategorisi (enum değerleri aşağıda) |
| `text` | `String` | `text` | Not metni |
| `mood` | `String` | `mood` | Ruh hali emoji (opsiyonel) |
| `createdAt` | `DateTime` | `created_at` | Oluşturma zamanı |
| `systolic` | `int?` | `systolic` | Tansiyon üst (mmHg) |
| `diastolic` | `int?` | `diastolic` | Tansiyon alt (mmHg) |
| `glucoseValue` | `double?` | `glucose_value` | Kan şekeri (mg/dL) |
| `painLevel` | `int?` | `pain_level` | Ağrı seviyesi (0–10) |
| `symptoms` | `List<String>` | `symptoms` | Hızlı semptom etiketleri |
| `medicationTaken` | `bool` | `medication_taken` | İlaç alındı mı |

#### `HealthNoteCategory` Enum Değerleri

| Değer | Türkçe Açıklama | İkon |
|---|---|---|
| `genel` | Genel not | 📝 |
| `tansiyon` | Tansiyon ölçümü | ❤️ |
| `seker` | Kan şekeri | 🩺 |
| `agri` | Ağrı / acı | ⚡ |
| `psikoloji` | Psikolojik durum | 🧠 |
| `diger` | Diğer | 📋 |

#### `HealthNoteMood` Değerleri

| Değer | Emoji |
|---|---|
| `cok_iyi` | 😄 |
| `iyi` | 🙂 |
| `orta` | 😐 |
| `kotu` | 😕 |
| `cok_kotu` | 😢 |
| `bilinmiyor` | — |

#### Hesaplanan Özellik

| Özellik | Döner | Açıklama |
|---|---|---|
| `bloodPressureDisplay` | `String?` | `"120/80 mmHg"` formatında; her iki değer doluysa dolu |

---

### 2.4 DrugScanHistoryEntry

**Konum:** `mobile/lib/src/features/drug/data/drug_history_repository.dart`
**Hive anahtarı:** `drug_scan_history`

İlaç görüntü tanıma veya prospektüs özetleme işlemlerinin geçmiş kaydı. Ham API yanıtını `payload` alanında tutar.

#### Alanlar

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `id` | `String` | `id` | Benzersiz kimlik |
| `mode` | `DrugScanHistoryMode` | `mode` | `medicine` veya `prospectus` |
| `title` | `String` | `title` | İlaç adı / başlık |
| `subtitle` | `String` | `subtitle` | Etken madde veya prospektüs türü |
| `createdAt` | `DateTime` | `createdAt` | Tarama zamanı |
| `payload` | `Map<String, dynamic>` | `payload` | Ham API yanıtı |

#### `DrugScanHistoryMode` Enum

| Değer | Açıklama |
|---|---|
| `medicine` | Görüntüden ilaç tanıma (`/api/drug/analyze-image`) |
| `prospectus` | Prospektüs özetleme (`/api/drug/prospectus`) |

#### Hesaplanan Özellik

| Özellik | Açıklama |
|---|---|
| `hasCandidates` | `payload['aday_ilaclar']` listesinde `ilac_adi`'ndan farklı başka ilaç var mı. Prospektüs modunda her zaman `false`. |

#### Fallback Başlık Mantığı (`fromPayload`)

- `payload['ilac_adi']` boşsa ve mod `medicine` → `"Bilinmeyen İlaç"`
- `payload['ilac_adi']` boşsa ve mod `prospectus` → `"Prospektüs Özeti"`

---

### 2.5 PharmacyItem / NearbyPharmaciesResponse

**Konum:** `mobile/lib/src/features/pharmacy/data/models/pharmacy_item.dart`

#### `PharmacyItem` Alanları

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `name` | `String` | `name` | Eczane adı |
| `address` | `String` | `address` | Açık adres |
| `phone` | `String` | `phone` | Telefon |
| `district` | `String` | `district` | İlçe |
| `lat` | `double?` | `lat` | Enlem (Nominatim ile doldurulan) |
| `lon` | `double?` | `lon` | Boylam (Nominatim ile doldurulan) |
| `distanceKm` | `double?` | `distance_km` | Kullanıcıya uzaklık (km) |

#### `NearbyPharmaciesResponse` Alanları

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `pharmacies` | `List<PharmacyItem>` | `pharmacies` | Nöbetçi eczane listesi |
| `count` | `int` | `count` | Toplam eczane sayısı |
| `apiAvailable` | `bool` | `api_available` | CollectAPI çevrimiçi mi |
| `detectedIl` | `String` | `detected_il` | Nominatim ile tespit edilen il |
| `detectedIlce` | `String` | `detected_ilce` | Nominatim ile tespit edilen ilçe |
| `fallbackToIl` | `bool` | `fallback_to_il` | İlçe yetersizse il geneline düşüldü |

---

### 2.6 FamilyMember / FamilyMemberDrug

**Konum:** `mobile/lib/src/features/profile/data/models/family_member.dart`
**Hive anahtarı:** `family_members`

#### `FamilyMember` Alanları

| Alan | Dart Tipi | JSON Anahtarı | Açıklama |
|---|---|---|---|
| `id` | `String` | `id` | Benzersiz kimlik |
| `name` | `String` | `name` | Üye adı |
| `relationship` | `String` | `relationship` | İlişki tipi (anne, baba, eş, vb.) |
| `emoji` | `String` | `emoji` | Temsil emojisi (varsayılan: 👤) |
| `age` | `int?` | `age` | Yaş (opsiyonel) |
| `drugs` | `List<FamilyMemberDrug>` | `drugs` | Üye ilaç listesi |
| `createdAt` | `DateTime` | `created_at` | Oluşturma zamanı |
| `updatedAt` | `DateTime` | `updated_at` | Güncelleme zamanı |

---

### 2.7 AppUser

**Konum:** `mobile/lib/src/features/auth/data/models/user_model.dart`
**Depolama:** `FlutterSecureStorage` (JWT token). `AppUser` nesnesi uygulama içi Riverpod state olarak tutulur, Hive'a yazılmaz.

| Alan | Dart Tipi | Açıklama |
|---|---|---|
| `id` | `String` | Kullanıcı kimliği |
| `email` | `String` | E-posta adresi |
| `name` | `String?` | Görünen ad |
| `photoUrl` | `String?` | Profil fotoğrafı URL'si |

---

## 3. Hive Yerel Depolama Anahtarları

Uygulama Hive'ı type-adapter olmadan kullanır; tüm nesneler JSON string olarak `StringList` veya tek `String` halinde saklanır.

| Hive Anahtarı | Dart Modeli | Tip | Açıklama |
|---|---|---|---|
| `medication_reminders_v1` | `MedicationReminder` | `List<String>` (JSON) | Tüm hatırlatıcı kayıtları |
| `drug_search_history` | `String` | `List<String>` | İlaç metin arama geçmişi (sade string) |
| `drug_scan_history` | `DrugScanHistoryEntry` | `List<String>` (JSON) | Görüntü / prospektüs tarama geçmişi |
| `health_notes` | `HealthNote` | `List<String>` (JSON) | Sağlık notu kayıtları |
| `emergency_card` | `EmergencyCard` | `String` (JSON) | Tek acil kart (singleton) |
| `family_members` | `FamilyMember` | `List<String>` (JSON) | Aile profilleri (yerel cache) |

> **Not:** `medication_reminders_v1` anahtarındaki `_v1` soneki, olası gelecekteki şema değişikliklerinde veri geçişini kolaylaştırmak amacıyla eklenmiştir.

---

## 4. Backend Pydantic Şemaları

### 4.1 Auth Şemaları

**Konum:** `backend/app/routers/auth.py`

#### `SignupRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `email` | `str` | Kullanıcı e-postası |
| `password` | `str` | Parola |
| `name` | `str \| None` | Görünen ad (opsiyonel) |

#### `LoginRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `email` | `str` | E-posta |
| `password` | `str` | Parola |

#### `AuthResponse`

| Alan | Tip | Açıklama |
|---|---|---|
| `access_token` | `str` | JWT token (HS256, 7 gün) |
| `token_type` | `str` | `"bearer"` |
| `user` | `UserResponse` | Kullanıcı bilgisi |

#### `UserResponse`

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `str` | Kullanıcı kimliği |
| `email` | `str` | E-posta adresi |
| `name` | `str \| None` | Görünen ad |

#### `ChangePasswordRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `current_password` | `str` | Mevcut parola |
| `new_password` | `str` | Yeni parola |

---

### 4.2 Drug Şemaları

**Konum:** `backend/app/routers/drug.py`

#### `DrugSearchRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `query` | `str` | Aranacak ilaç adı veya etken madde |

#### `DrugInteractionRequest`

| Alan | Tip | Kısıt | Açıklama |
|---|---|---|---|
| `drugs` | `list[str]` | 2–20 eleman | Etkileşim kontrol edilecek ilaç listesi |

#### `ChatRequest`

| Alan | Tip | Kısıt | Açıklama |
|---|---|---|---|
| `message` | `str` | — | Kullanıcı mesajı |
| `history` | `list[ChatMessage]` | maks. 50 | Konuşma geçmişi |

#### `ChatMessage`

| Alan | Tip | Değerler | Açıklama |
|---|---|---|---|
| `role` | `str` | `"user"` / `"model"` | Mesaj sahibi |
| `content` | `str` | — | Mesaj içeriği |

#### `SymptomRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `symptoms` | `str` | Semptom açıklaması (serbest metin) |

#### `SymptomAnalysisResponse`

| Alan | Tip | Açıklama |
|---|---|---|
| `analysis` | `str` | Gemini yanıtı |
| `acil_durum` | `bool` | Acil tıbbi müdahale gerekip gerekmediği |

---

### 4.3 Pharmacy Şemaları

**Konum:** `backend/app/routers/pharmacy.py`

#### `PharmacyItem`

| Alan | Tip | Açıklama |
|---|---|---|
| `name` | `str` | Eczane adı |
| `address` | `str` | Adres |
| `phone` | `str` | Telefon |
| `district` | `str` | İlçe |
| `lat` | `float \| None` | Enlem |
| `lon` | `float \| None` | Boylam |
| `distance_km` | `float \| None` | Kullanıcıya uzaklık |

#### `NearbyPharmaciesResponse`

| Alan | Tip | Açıklama |
|---|---|---|
| `pharmacies` | `list[PharmacyItem]` | Nöbetçi eczane listesi |
| `count` | `int` | Toplam sayı |
| `api_available` | `bool` | CollectAPI durumu |
| `detected_il` | `str` | Tespit edilen il |
| `detected_ilce` | `str` | Tespit edilen ilçe |
| `fallback_to_il` | `bool` | İl geneline düşüldü mü |

---

### 4.4 Profile Şemaları

**Konum:** `backend/app/routers/profile.py`

#### `CreateFamilyMemberRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `name` | `str` | Üye adı |
| `relationship` | `str` | İlişki tipi |
| `emoji` | `str` | Temsil emojisi |
| `age` | `int \| None` | Yaş |

#### `FamilyMemberResponse`

| Alan | Tip | Açıklama |
|---|---|---|
| `id` | `str` | Üye kimliği |
| `name` | `str` | Adı |
| `relationship` | `str` | İlişki tipi |
| `emoji` | `str` | Emojisi |
| `age` | `int \| None` | Yaş |
| `created_at` | `str` | ISO-8601 oluşturma zamanı |
| `updated_at` | `str` | ISO-8601 güncelleme zamanı |

#### `AddMemberDrugRequest`

| Alan | Tip | Açıklama |
|---|---|---|
| `drug_name` | `str` | İlaç adı |
| `dosage` | `str \| None` | Doz bilgisi |
| `frequency` | `str \| None` | Kullanım sıklığı |
| `notes` | `str \| None` | Notlar |

---

## 5. JSON Temsil Örnekleri

### 5.1 MedicationReminder

```json
{
  "id": "1717823400000000",
  "drug_name": "Metformin 850mg",
  "hour": 8,
  "minute": 0,
  "times_per_day": 2,
  "units_per_dose": 1,
  "stock_count": 42,
  "initial_stock_count": 90,
  "is_active": true,
  "use_alarm": false,
  "notes": "Yemekten sonra alınacak",
  "created_at": "2026-06-01T08:00:00.000Z",
  "updated_at": "2026-06-07T10:30:00.000Z",
  "last_taken_at": "2026-06-07T08:05:00.000Z"
}
```

### 5.2 EmergencyCard

```json
{
  "blood_type": "A Rh+",
  "allergies": ["Penisilin", "Aspirin"],
  "chronic_conditions": ["Diyabet Tip 2", "Hipertansiyon"],
  "current_medications": ["Metformin 850mg", "Lisinopril 10mg"],
  "emergency_contact_name": "Ahmet Yılmaz",
  "emergency_contact_phone": "+90 532 123 45 67",
  "doctor_name": "Dr. Fatma Kaya",
  "doctor_phone": "+90 212 555 00 11",
  "notes": "İnsülin gerektiren durumlarda yanımda kalem var.",
  "updated_at": "2026-06-07T12:00:00.000Z"
}
```

### 5.3 HealthNote

```json
{
  "id": "1717832400000000",
  "date": "2026-06-07",
  "category": "tansiyon",
  "text": "Sabah ölçümü.",
  "mood": "🙂",
  "created_at": "2026-06-07T09:00:00.000Z",
  "systolic": 128,
  "diastolic": 82,
  "glucose_value": null,
  "pain_level": null,
  "symptoms": [],
  "medication_taken": true
}
```

### 5.4 DrugScanHistoryEntry

```json
{
  "id": "1717840000000000",
  "mode": "medicine",
  "title": "Augmentin 1000 mg",
  "subtitle": "Amoksisilin + Klavulanat",
  "createdAt": "2026-06-07T11:00:00.000Z",
  "payload": {
    "ilac_adi": "Augmentin 1000 mg",
    "etken_madde": "Amoksisilin + Klavulanat",
    "kullanim_amaci": "Bakteriyel enfeksiyonlar",
    "aday_ilaclar": ["Amoksiklav 1000 mg", "Klavulin 1000 mg"]
  }
}
```
