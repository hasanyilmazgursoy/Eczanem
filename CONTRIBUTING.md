# Katkı Rehberi

Bu repo düzenli, okunabilir ve sürdürülebilir bir geliştirme süreci hedefler.

## Genel prensipler

- Değişiklikler küçük, anlaşılır ve test edilebilir parçalara bölünmelidir.
- İlgisiz refactor veya biçim değişiklikleri aynı commit içine karıştırılmamalıdır.
- Yeni davranış ekleniyorsa mümkün olduğunca doğrulama adımı da eklenmelidir.
- Kod açıklamaları Türkçe olabilir; commit mesajları **zorunlu olarak Türkçe** olmalıdır.

## Branch ve commit yaklaşımı

Önerilen commit tipleri:

- `feat:` yeni özellik
- `fix:` hata düzeltmesi
- `chore:` bakım / yapılandırma
- `docs:` dokümantasyon
- `refactor:` davranış değiştirmeyen düzenleme
- `test:` test ekleme / güncelleme

### Commit mesajı kuralları

- Türkçe yazılmalı
- Kısa ve eylem odaklı olmalı
- Gerekirse kapsam belirtmeli

Örnekler:

```text
feat(phase1): ilaç arama durumlarını iyileştir
fix(auth): mobil giriş için bcrypt sürümünü sabitle
chore(repo): readme ve changelog ekle
```

## Kod standartları

### Flutter

- Mevcut mimari ve klasör yapısına uyun
- Riverpod / servis / repository akışını koruyun
- Lokalizasyon anahtarı gerektiren metinleri doğrudan sabit yazmayın
- Analyzer temiz kalmalı

### Backend

- Router / service ayrımını koruyun
- Ortam değişkeni ile yönetilebilecek ayarlar config üzerinden ilerlemeli
- Hata mesajları kullanıcıya anlaşılır dönecek şekilde düşünülmeli

## PR beklentileri

Her PR şunları açıklamalı:

- Ne değişti?
- Neden değişti?
- Nasıl test edildi?
- Bilinen eksik veya sonraki adım var mı?

## Yayın öncesi kontrol listesi

- `flutter analyze` temiz mi?
- Backend sözdizimi kontrolü geçti mi?
- Gerekirse manuel cihaz testi yapıldı mı?
- README / CHANGELOG güncel mi?
