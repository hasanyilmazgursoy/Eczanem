# ECZANEM — Proje Yol Haritası

**Proje:** Kişisel İlaç Asistanı Mobil Uygulaması  
**Başlangıç Tarihi:** 9 Nisan 2026  
**Teknolojiler:** Flutter (Dart) + FastAPI (Python) + OpenRouter (Gemini)  
**Durum:** 🟢 FAZ 0, 1, 2, Ara Faz, 4 ve 5 tamamlandı · 🟡 FAZ 3 büyük ölçüde hazır · 🟡 FAZ 6 sesli arama tamamlandı · 🟡 FAZ 7 büyük ölçüde hazır · 🟡 FAZ 8 aktif odak

---

## Genel Bakış

Kullanıcıların ilaç bilgilerini yazarak veya fotoğraf çekerek sorgulandığı, ilaçlar arası etkileşim
kontrolü yapan, hatırlayıcı kuran ve aile bireylerinin ilaçlarını yöneten kapsamlı bir mobil sağlık
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
│  │  ⏰ Hatırlayıcı  │ 👨‍👩‍👧 Aile Profil│    │
│  │  🏥 Nöbetçi Eczane│ 🆘 Acil Kart  │    │
│  │  🎤 Sesli Sorgu   │ 📝 Sağlık Notu│    │
│  └──────────────────────────────────┘    │
│  Local: SQLite + Hive (offline veri)     │
└──────────────────┌──────────────────────┘
                   │ HTTPS
                   ↓
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
- [x] Local storage: Hive tabanlı depolama aktif, eski SharedPreferences verisi migrate ediliyor
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
ÖNEMLİ: Bu bilgiler genel bilgilendirme amacıyla sunulmaktadır. Tıbbi tavsiye niteliği taşımaz.
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

## FAZ 2 — Kamera ile Tanıma + Prospüktüs Tarama (1-2 hafta)

**Durum:** 🟢 Tamamlandı

### Backend
- [x] `POST /api/drug/analyze-image` — multipart image → Gemini multimodal
- [x] `POST /api/drug/prospectus` — Prospüktüs fotoğrafı → Gemini ile özetleme
- [x] Mobil istemcide yükleme öncesi görsel yeniden boyutlandırma ve sıkıştırma eklendi
- [x] Backend tarafında ek maliyet optimizasyonları ve çoklu görsel stratejisi

### Flutter Ekranları
- [x] Kamera Ekranı: `camera` paketi, çerçeve overlay, çekim butonu
- [x] Mevcut arama ekranına kamera / galeri tabanlı görsel seçme akışı eklendi
- [x] Fotoğraf Önizleme: "Analiz Et" / "Görseli Kaldır" butonları
- [x] Çoklu Sonuç: Reçetede birden fazla ilaç → liste + detay
- [x] Prospüktüs Özet: Kategorize edilmiş, okunabilir özet

### Flutter Paketleri
- `camera` — kamera kontrolü
- `image_picker` — galeriden seçme
- `image` — fotoğraf sıkıştırma

### Çıktı
Fotoğraf çekip ilaç tanıma, çoklu aday seçimi ve prospüktüs özetleme çalışıyor.

---

## ARA FAZ — Geçmiş Merkezi & Profil Kısayolları (2-3 gün)

**Durum:** 🟢 Tamamlandı

### Flutter
- [x] Arama geçmişi ekranı eklendi, geçmiş sorgudan otomatik yeniden arama destekleniyor
- [x] Tarama geçmişi ekranı eklendi; ilaç tanıma ve prospüktüs özetleri yerel olarak saklanıyor
- [x] Profil sekmesindeki kısayollar gerçek geçmiş ekranlarına bağlandı
- [x] Arama/tarama geçmişi için ortak yerel repository katmanı oluşturuldu
- [x] Boş durum, tek silme ve tümünü temizleme aksiyonları eklendi

### Doğrulama
- [x] `flutter analyze`
- [x] `flutter test`

### Çıktı
Kullanıcı hem metin aramalarını hem de görsel analiz geçmişini profile sekmesinden tekrar açabiliyor.

---

## FAZ 3 — Kullanıcı Sistemi & Aile Profili (1-2 hafta)

**Durum:** 🟡 Büyük ölçüde hazır

### Backend
- [x] `POST /api/auth/register` — E-posta + şifre ile kayıt
- [x] `POST /api/auth/login` — JWT token döndür
- [ ] `POST /api/auth/google` — Google ile giriş (opsiyonel)
- [x] `CRUD /api/profile/family/` — Aile bireyi yönetimi
- [x] `CRUD /api/profile/family/{id}/drugs/` — Aile bireyinin ilaç listesi

### Veritabanı Tabloları
- `users` (id, email, password_hash, name, created_at)
- `family_members` (id, user_id, name, relationship, age, avatar_emoji)
- `family_member_drugs` (id, family_member_id, drug_name, dosage, frequency, start/end_date, notes)

### Flutter Ekranları
- [x] Giriş/Kayıt temel ekranları
- [x] Profil Ana: Kendi profili + aile bireyleri grid (emoji avatarlar)
- [x] Birey Detay: İlaç listesi, ekle/çıkar
- [x] Birey Ekle: Ad, ilişki, yaş, emoji seç
- [ ] Backend senkronizasyonu ve tam release polish

### Önemli Kararlar
- Giriş yapmayanlar → tüm veri local'de (Hive/SQLite)
- Giriş yapanlar → veri backend'e senkron + local cache
- JWT token → `flutter_secure_storage` ile sakla

### Çıktı
Kullanıcı aile bireylerinin ilaçlarını ayrı ayrı yönetebiliyor.

---

## FAZ 4 — Hatırlayıcı & Stok Takibi (1-2 hafta)

**Durum:** 🟢 Tamamlandı

### Flutter Ekranları
- [x] Hatırlayıcı Ekle: İlaç seç → saat + günlük sıklık + stok bilgisi
- [x] Hatırlayıcı Listesi: Aktif hatırlayıcılar + açma/kapama toggle
- [x] Stok Giriş: Kutuda kaç tablet + günlük doz → otomatik bitiş hesabı
- [x] Stok Dashboard: Kalan miktar progress bar + "X gün sonra bitecek" uyardı
- [x] Bildirim: "💊 Aspirin alma zamanı!" — local notification

### Flutter Paketleri
- `flutter_local_notifications` — local bildirim
- `timezone` — saat dilimi yönetimi
- `flutter_timezone` — cihaz saat dilimini doğru çözme

### Stok Hesaplama
```
kalan_gün = kalan_tablet / (günlük_doz × günlük_tekrar)
uya rı_tarihi = bugün + kalan_gün - 3  // 3 gün önceden uyar
```

### Önemli
- [x] "✅ Aldım" butonu → stok otomatik azalır
- [x] Bildirimler tamamen offline çalışmalı (local notification)

### Çıktı
Yerel çalışan ilaç hatırlayıcı, stok takibi ve offline bildirim akışı hazır.

---

## FAZ 5 — İlaç Etkileşim Kontrolü & Doğal Alternatifler (1-2 hafta)

**Durum:** 🟢 Tamamlandı

### Backend
- [x] `POST /api/drug/interaction` — İlaç listesi → etkileşim analizi
- [x] `POST /api/drug/natural-alternatives` — Doğal çözüm önerileri

### Flutter Ekranları
- [x] Etkileşim Kontrol: Profildeki ilaçlar + manuel ekleme → "Kontrol Et"
- [x] Etkileşim Sonuç: Renk kodlu (🟢 Güvenli, 🟡 Dikkatli, 🔴 Tehlikeli)
- [x] Doğal Alternatifler: İlaç detayında CTA ile açılan ekran

### Çıktı
İlaç etkileşim kontrolü ve doğal alternatif önerileri çalışıyor.

---

## FAZ 6 — Nöbetçi Eczane + Sesli Sorgulama (1-2 hafta)

**Durum:** 🟡 Büyük ölçüde hazır

### Backend
- [x] `GET /api/pharmacy/nearby?lat=X&lon=Y` — En yakın nöbetçi eczaneler
- [x] Veri kaynağı: CollectAPI tabanlı servis katmanı
- [ ] Cache: 6 saat ve prod sertliği

### Flutter Ekranları
- [ ] Eczane Harita: Google Maps/OpenStreetMap üzerine pinler
- [x] Eczane Liste: Liste, telefon, adres ve temel aksiyonlar
- [x] Sesli Arama: Mikrofon butonu → STT → ilaç arama (speech_to_text ^7.0.0)
- [ ] Konum izinleri ve yayın seviyesi kullanıcı akışı polish

### Flutter Paketleri
- `geolocator` — konum alma
- `google_maps_flutter` veya `flutter_map` — harita
- `url_launcher` — telefon arama, yol tarifi
- `speech_to_text` — Türkçe ses tanıma

### Çıktı
Nöbetçi eczane bulma + sesle ilaç sorgulama çalışıyor.

---

## FAZ 7 — Acil Durum Kartı & Sağlık Notu (1 hafta)

**Durum:** 🟡 Büyük ölçüde hazır

### Flutter Ekranları
- [x] Acil Kart Düzenle: Kan grubu, alerjiler, kronik hastalıklar, acil kişi
- [x] Acil Kart Görüntüle: Tek ekranda tüm bilgi, büyük font, yüksek kontrast
- [ ] Paylaş: PDF olarak dışa aktar
- [x] Sağlık Notu Ekle: Tarih, kategori, metin, emoji mood
- [x] Not Geçmişi: Liste + kategori filtreleme
- [x] Takvim görünümü ve doktor raporu özeti (DraggableScrollableSheet + share_plus)

### Çıktı
Acil durum kartı + sağlık günlüğü çalışıyor.

---

## FAZ 8 — Test, UI Polish & Yayın (1-2 hafta)

**Durum:** 🟡 Başlatıldı

- [ ] UI/UX iyileştirme: Tutarlı tasarım, animasyonlar, empty state ekranları
- [ ] Karanlık mod: Tam dark theme desteği ve hardcoded color temizliği
- [x] Onboarding: İlk açılışta temel onboarding akışı
- [ ] Hata yönetimi: Her ekranda yükleniyor/hata/boş/başarılı durumları
- [ ] Performans: Lazy loading, image caching, API response caching
- [ ] Güvenlik: HTTPS zorunlu, API key gizleme, input sanitization, CORS sertl eştirme
- [x] Test: HealthNote + EmergencyCard model birim testleri eklendi (pure Dart)
- [ ] Play Store: App icon, screenshots, açıklama, privacy policy
- [ ] Backend Deploy: Railway / Render / VPS
- [ ] Dokümantasyon senkronizasyonu: README, PLAN, CHANGELOG, release checklist

---

## Özet Timeline

| Faz | İçerik | Süre | Durum |
|-----|--------|------|------|
| 0 | Altyapı & Kurulum | 3-4 gün | 🟢 |
| 1 | MVP — İlaç Sorgulama | 1-2 hafta | 🟢 |
| 2 | Kamera + Prospüktüs | 1-2 hafta | 🟢 |
| Ara Faz | Geçmiş Merkezi | 2-3 gün | 🟢 |
| 3 | Kullanıcı + Aile Profili | 1-2 hafta | 🟡 |
| 4 | Hatırlayıcı + Stok Takibi | 1-2 hafta | 🟢 |
| 5 | Etkileşim + Doğal Alternatif | 1-2 hafta | 🟢 |
| 6 | Nöbetçi Eczane + Sesli Sorgu | 1-2 hafta | 🟡 |
| 7 | Acil Kart + Sağlık Notları | 1 hafta | 🟡 |
| 8 | Test & Yayın | 1-2 hafta | 🟡 |

**Toplam: ~8-14 hafta**
