# Release Checklist

Bu liste, `Eczanem` projesini demo, jüri sunumu veya mağaza yayını öncesinde sistematik şekilde kontrol etmek için hazırlanmıştır.

## 1. Kapsam dondurma

- [ ] Yayına girecek modüller netleştirildi
- [ ] Ertelenecek modüller ayrı backlog'a alındı
- [ ] `README.md`, `PLAN.md`, `CHANGELOG.md` güncel
- [ ] Sürüm numarası ve release notu birbiriyle uyumlu

## 2. Mobil doğrulama

- [ ] `flutter analyze --no-pub`
- [ ] Kritik testler çalıştı
- [ ] `flutter test`
- [ ] Boş durumlar, hata durumları ve loading durumları temel ekranlarda kontrol edildi
- [ ] Dark mode görünümü kritik ekranlarda kontrol edildi
- [ ] `tr.json` ve `en.json` anahtarları kodla uyumlu

## 3. Backend doğrulama

- [ ] `python -m compileall app`
- [ ] Kritik endpoint'ler smoke test ile doğrulandı
- [ ] `.env` değişkenleri eksiksiz
- [ ] CORS ve debug ayarları release hedefine uygun
- [ ] Secret anahtarlar repoya gömülü değil

## 4. Ürün ve UX kontrolleri

- [ ] Login / signup akışı çalışıyor
- [ ] İlaç arama ve detay akışı çalışıyor
- [ ] Kamera / galeri analizi çalışıyor
- [ ] Hatırlatıcı oluşturma ve bildirim akışı çalışıyor
- [ ] Aile profili akışı çalışıyor
- [ ] Nöbetçi eczane akışı çalışıyor
- [ ] Acil kart ve sağlık notları akışı çalışıyor

## 5. Yayın hazırlığı

- [ ] Uygulama ikonu ve splash kontrol edildi
- [ ] Privacy policy hazır
- [ ] Store açıklamaları hazır
- [ ] Ekran görüntüleri hazır
- [ ] Android imzalama / keystore hazır
- [ ] Release APK veya AAB başarıyla üretildi

## 6. Deploy ve operasyon

- [ ] Backend hedef ortamı seçildi (Railway / Render / VPS)
- [ ] Environment secrets yönetimi tanımlandı
- [ ] Temel loglama / hata takibi planı belirlendi
- [ ] Health check ve temel erişim doğrulandı

## 7. Kapanış

- [ ] Çalışma ağacı temiz
- [ ] Son commit mesajları ve changelog tutarlı
- [ ] Demo senaryosu veya release senaryosu prova edildi
