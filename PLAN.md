# ECZANEM — Proje Yol Haritası

**Proje:** Kişisel İlaç Asistanı Mobil Uygulaması  
**Başlangıç Tarihi:** 9 Nisan 2026  
**Teknolojiler:** Flutter (Dart) + FastAPI (Python) + OpenRouter (Gemini)  
**Durum:** 🟡 FAZ 2 Başladı

---

## Genel Bakış

Kullanıcıların ilaç bilgilerini yazarak veya fotoğraf çekerek sorguladığı, ilaçlar arası etkileşim
kontrolü yapan, hatırlatıcı kuran ve aile bireylerinin ilaçlarını yöneten kapsamlı bir mobil sağlık
asistanı uygulaması.

---

## Mimari

```
┌──────────────────────────────────────────┐
│         Flutter Mobil Uygulama            │
│  ┌──────────────────────────────────┐    │
│  │  📷 Kamera  │ 🔍 Arama │ 📊 Barkod│   │
│  ├──────────────────────────────────┤    │
│  │  💊 İlaç Bilgi  │ ⚠️ Etkileşim   │    │
│  │  ⏰ Hatırlatıcı  │ 👨‍👩‍👧 Aile Profil│    │
│  │  🏥 Nöbetçi Eczane│ 🆘 Acil Kart  │    │
│  │  🎤 Sesli Sorgu   │ 📝 Sağlık Notu│    │
│  └──────────────────────────────────┘    │
│  Local: SQLite + Hive (offline veri)     │
└──────────────────┬───────────────────────┘
                   │ HTTPS
                   ▼
┌──────────────────────────────────────────┐
│         FastAPI Backend (Python)          │
│  /api/drug/analyze-image   → OpenRouter  │
│  /api/drug/search          → OpenRouter  │
│  /api/drug/interaction     → OpenRouter  │
│  /api/drug/barcode/{code}  → İlaç DB     │
│  /api/pharmacy/nearby      → Eczane API  │
│  /api/auth/ (opsiyonel)    → JWT         │
│  /api/profile/             → Aile yönetim│
│  PostgreSQL + Redis (cache)              │
└──────────────────────────────────────────┘
```

---

## FAZ 0 — Proje Altyapısı & Kurulum (3-4 gün)

**Durum:** 🟢 Büyük ölçüde tamamlandı

### Backend (FastAPI)
- [x] Proje yapısı: FastAPI + modüler klasör yapısı (routers, services, models, schemas)
- [x] Gemini modeline istek atan servis katmanı
- [x] Environment yönetimi: `.env` ile API key, DB bağlantı bilgileri
- [ ] Docker Compose: FastAPI + PostgreSQL + Redis tek komutla ayağa kalkmalı
- [x] CORS ayarları: Flutter'dan gelen isteklere izin
- [x] Health check endpoint: `GET /health`

### Flutter (Mobil)
- [x] Flutter proje oluşturma: `lib/core`, `lib/features`, `lib/shared`
- [x] State management: Riverpod kurulumu
- [x] Tema & tasarım sistemi: Renk paleti, tipografi, karanlık/aydınlık mod altyapısı
- [x] HTTP client: `dio` paketi ile backend bağlantı katmanı
- [ ] Local storage: Hive yerine şu an SharedPreferences/SecureStorage kullanılıyor
- [x] Navigasyon: `go_router` ile sayfa yönetimi

### Çıktı
İki taraf da çalışır durumda, birbirine istek atabiliyor.

---

## FAZ 1 — Temel İlaç Sorgulama / MVP (1-2 hafta)

**Durum:** 🟢 Tamamlandı

### Backend
- [x] `POST /api/drug/search` — İlaç adını alır, Gemini'ye gönderir
- [x] Response yapısı: `{ ilaç_adı, etken_madde, dozaj, kullanım_şekli, yan_etkiler, uyarılar }`
- [x] Rate limiting: IP bazlı istek sınırlama
- [x] Response cache: 24 saat Redis cache + bellek içi fallback

### Gemini Prompt Tasarımı
```
Sen bir eczacı asistanısın. Kullanıcı sana bir ilaç adı verecek.
Aşağıdaki bilgileri Türkçe olarak JSON formatında döndür:
- ilac_adi, etken_madde, ne_icin_kullanilir
- dozaj_bilgisi, kullanim_sekli (aç/tok karnına, sabah/akşam)
- yan_etkiler (liste), uyarilar (liste), kimler_kullanmamali (liste)
ÖNEMLİ: Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz.
```

### Flutter Ekranları
- [x] Ana Sayfa: Arama çubuğu + son sorgulanan ilaçlar + alt navigasyon
- [x] İlaç Detay: Kartlar halinde bilgiler
- [x] Yükleniyor: Skeleton/shimmer efekti
- [x] Disclaimer banner: Her ilaç detay ekranında uyarı

### Teknik Detaylar
- [x] Arama debounce (500ms)
- [x] Arama geçmişi local'de (Hive tabanlı saklama + SharedPreferences migration)
- [x] Hata yönetimi: internet yok, API hatası, boş sonuç durumları

### Çıktı
Çalışan bir ilaç arama uygulaması. Gerçek cihazda çalıştırma, auth, temel dashboard akışı, Redis cache ve Hive tabanlı yerel depolama hazır.

---

## FAZ 2 — Kamera ile Tanıma + Prospektüs Tarama (1-2 hafta)

**Durum:** 🟡 Başladı

### Backend
- [x] `POST /api/drug/analyze-image` — multipart image → Gemini multimodal
- [ ] `POST /api/drug/prospectus` — Prospektüs fotoğrafı → Gemini ile özetleme
- [ ] Görsel optimizasyon: boyut & maliyet optimizasyonu

### Flutter Ekranları
- [ ] Kamera Ekranı: `camera` paketi, çerçeve overlay, çekim butonu
- [ ] Fotoğraf Önizleme: "Analiz Et" / "Tekrar Çek" butonları
- [ ] Çoklu Sonuç: Reçetede birden fazla ilaç → liste + detay
- [ ] Prospektüs Özet: Kategorize edilmiş, okunabilir özet

### Flutter Paketleri
- `camera` — kamera kontrolü
- `image_picker` — galeriden seçme
- `image` — fotoğraf sıkıştırma

### Çıktı
Fotoğraf çekip ilaç tanıma, prospektüs özetleme çalışıyor.

---

## FAZ 3 — Kullanıcı Sistemi & Aile Profili (1-2 hafta)

**Durum:** ⬜ Başlanmadı

### Backend
- [ ] `POST /api/auth/register` — E-posta + şifre ile kayıt
- [ ] `POST /api/auth/login` — JWT token döndür
- [ ] `POST /api/auth/google` — Google ile giriş (opsiyonel)
- [ ] `CRUD /api/profile/family/` — Aile bireyi yönetimi
- [ ] `CRUD /api/profile/family/{id}/drugs/` — Aile bireyinin ilaç listesi

### Veritabanı Tabloları
- `users` (id, email, password_hash, name, created_at)
- `family_members` (id, user_id, name, relationship, age, avatar_emoji)
- `family_member_drugs` (id, family_member_id, drug_name, dosage, frequency, start/end_date, notes)

### Flutter Ekranları
- [ ] Giriş/Kayıt: Tab yapısı + Google ile giriş
- [ ] Profil Ana: Kendi profili + aile bireyleri grid (emoji avatarlar)
- [ ] Birey Detay: İlaç listesi, ekle/çıkar
- [ ] Birey Ekle: Ad, ilişki, yaş, emoji seç

### Önemli Kararlar
- Giriş yapmayanlar → tüm veri local'de (Hive/SQLite)
- Giriş yapanlar → veri backend'e senkron + local cache
- JWT token → `flutter_secure_storage` ile sakla

### Çıktı
Kullanıcı aile bireylerinin ilaçlarını ayrı ayrı yönetebiliyor.

---

## FAZ 4 — Hatırlatıcı & Stok Takibi (1-2 hafta)

**Durum:** ⬜ Başlanmadı

### Flutter Ekranları
- [ ] Hatırlatıcı Ekle: İlaç seç → saat/gün/sıklık → bildirim ayarla
- [ ] Hatırlatıcı Listesi: Aktif hatırlatıcılar + açma/kapama toggle
- [ ] Stok Giriş: Kutuda kaç tablet + günlük doz → otomatik bitiş hesabı
- [ ] Stok Dashboard: Kalan miktar progress bar + "X gün sonra bitecek" uyarısı
- [ ] Bildirim: "💊 Aspirin alma zamanı!" — local notification

### Flutter Paketleri
- `flutter_local_notifications` — local bildirim
- `timezone` — saat dilimi yönetimi
- `workmanager` — arka plan görevi

### Stok Hesaplama
```
kalan_gün = kalan_tablet / (günlük_doz × günlük_tekrar)
uyarı_tarihi = bugün + kalan_gün - 3  // 3 gün önceden uyar
```

### Önemli
- Bildirimler tamamen offline çalışmalı (local notification)
- "✅ Aldım" butonu → stok otomatik azalır

### Çıktı
İlaç hatırlatıcı + stok takibi çalışıyor.

---

## FAZ 5 — İlaç Etkileşim Kontrolü & Doğal Alternatifler (1-2 hafta)

**Durum:** ⬜ Başlanmadı

### Backend
- [ ] `POST /api/drug/interaction` — İlaç listesi → etkileşim analizi
- [ ] `POST /api/drug/natural-alternatives` — Doğal çözüm önerileri

### Flutter Ekranları
- [ ] Etkileşim Kontrol: Profildeki ilaçlar + manuel ekleme → "Kontrol Et"
- [ ] Etkileşim Sonuç: Renk kodlu (🟢 Güvenli, 🟡 Dikkatli, 🔴 Tehlikeli)
- [ ] Doğal Alternatifler: İlaç detayında ek tab "🌿 Doğal Alternatifler"

### Çıktı
İlaç etkileşim kontrolü ve doğal alternatif önerileri çalışıyor.

---

## FAZ 6 — Nöbetçi Eczane + Sesli Sorgulama (1-2 hafta)

**Durum:** ⬜ Başlanmadı

### Backend
- [ ] `GET /api/pharmacy/nearby?lat=X&lon=Y` — En yakın nöbetçi eczaneler
- [ ] Veri kaynağı: CollectAPI veya nosyapi.com
- [ ] Cache: 6 saat

### Flutter Ekranları
- [ ] Eczane Harita: Google Maps/OpenStreetMap üzerinde pinler
- [ ] Eczane Liste: Mesafe sıralı, telefon, adres, yol tarifi butonu
- [ ] Sesli Arama: Mikrofon butonu → STT → ilaç arama

### Flutter Paketleri
- `geolocator` — konum alma
- `google_maps_flutter` veya `flutter_map` — harita
- `url_launcher` — telefon arama, yol tarifi
- `speech_to_text` — Türkçe ses tanıma

### Çıktı
Nöbetçi eczane bulma + sesle ilaç sorgulama çalışıyor.

---

## FAZ 7 — Acil Durum Kartı & Sağlık Notu (1 hafta)

**Durum:** ⬜ Başlanmadı

### Flutter Ekranları
- [ ] Acil Kart Düzenle: Kan grubu, alerjiler, kronik hastalıklar, acil kişi
- [ ] Acil Kart Görüntüle: Tek ekranda tüm bilgi, büyük font, yüksek kontrast
- [ ] Paylaş: PDF olarak dışa aktar
- [ ] Sağlık Notu Ekle: Tarih, kategori, metin, emoji mood
- [ ] Not Geçmişi: Takvim görünümü + liste + filtreleme
- [ ] Doktor Raporu: Tarih aralığı seç → Gemini ile özetle

### Çıktı
Acil durum kartı + sağlık günlüğü çalışıyor.

---

## FAZ 8 — Test, UI Polish & Yayın (1-2 hafta)

**Durum:** ⬜ Başlanmadı

- [ ] UI/UX iyileştirme: Tutarlı tasarım, animasyonlar, empty state ekranları
- [ ] Karanlık mod: Tam dark theme desteği
- [ ] Onboarding: İlk açılışta 3-4 sayfalık tanıtım
- [ ] Hata yönetimi: Her ekranda yükleniyor/hata/boş/başarılı durumları
- [ ] Performans: Lazy loading, image caching, API response caching
- [ ] Güvenlik: HTTPS zorunlu, API key gizleme, input sanitization
- [ ] Test: Widget testleri + API testleri (Pytest)
- [ ] Play Store: App icon, screenshots, açıklama, privacy policy
- [ ] Backend Deploy: Railway / Render / VPS

---

## Özet Timeline

| Faz | İçerik | Süre | Durum |
|-----|--------|------|-------|
| 0 | Altyapı & Kurulum | 3-4 gün | ⬜ |
| 1 | MVP — İlaç Sorgulama | 1-2 hafta | ⬜ |
| 2 | Kamera + Prospektüs | 1-2 hafta | ⬜ |
| 3 | Kullanıcı + Aile Profili | 1-2 hafta | ⬜ |
| 4 | Hatırlatıcı + Stok Takibi | 1-2 hafta | ⬜ |
| 5 | Etkileşim + Doğal Alternatif | 1-2 hafta | ⬜ |
| 6 | Nöbetçi Eczane + Sesli Sorgu | 1-2 hafta | ⬜ |
| 7 | Acil Kart + Sağlık Notları | 1 hafta | ⬜ |
| 8 | Test & Yayın | 1-2 hafta | ⬜ |

**Toplam: ~8-14 hafta**
