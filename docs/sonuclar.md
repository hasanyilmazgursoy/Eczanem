SONUÇLAR VE ÖNERİLER

Bu çalışmada, Türkiye'deki bireysel ilaç kullanıcılarının ilaç bilgisine erişimde yaşadıkları güçlükleri gidermeye yönelik yapay zekâ destekli bir mobil sağlık platformu olan Eczanem geliştirilmiştir. Aşağıda çalışmadan elde edilen sonuçlar araştırma soruları ekseninde özetlenmekte, katkılar ve sınırlılıklar değerlendirilmekte, gelecek araştırma önerilerine yer verilmektedir.


Araştırma Sorularına Yanıtlar

**RQ1: Büyük dil modelleri, yapılandırılmamış Türkçe metin girdileriyle ilaç bilgisini ne ölçüde doğru ve tutarlı biçimde üretebilir?**

Google Gemini 2.5 Flash, metin tabanlı ilaç sorgularında (ilaç arama, etkileşim analizi, doğal alternatifler, semptom değerlendirme) Türkçe yanıtlar üretebilmektedir. Halüsinasyon riskini minimize etmek amacıyla `temperature=0.3` ayarı uygulanmış ve tüm yanıtlara yapılandırılmış JSON çıktı zorunluluğu getirilmiştir. Bu tasarım kararı, modelin keyfi metin üretme özgürlüğünü kısıtlayarak klinik olarak tutarsız çıktı olasılığını azaltmaktadır. Bununla birlikte, Türkçe tıbbi terminoloji alanındaki LLM doğruluğunun bağımsız klinik uzman değerlendirmesiyle ölçülmesi bu çalışmanın kapsamı dışındadır.

**RQ2: Multimodal yapay zekâ modelleri, ilaç kutusu veya prospektüs görüntülerinden klinik açıdan anlamlı bilgileri başarıyla çıkarabilir mi?**

Gemini'nin multimodal kapasitesi, Base64 kodlamalı görüntü verisi üzerinden başarıyla kullanılmıştır. İlaç kutusu tanıma ve prospektüs özetleme işlevleri tek bir API endpoint'iyle (`/drug/analyze-image`) gerçekleştirilmektedir. Pillow ön işleme aşaması (maksimum 1400×1400 piksel yeniden boyutlandırma ve EXIF normalleştirme), API gecikme süresini ve başarısız istek oranını belirgin biçimde azaltmıştır. Üretilen JSON yapısı standart olup Flutter istemcisinde ek ayrıştırma mantığı gerekmeden kullanılabilmektedir.

**RQ3: Mobil sağlık uygulamalarında istemci taraflı veri yerelliği ile bulut tabanlı yapay zekâ servislerinin hibrit mimarisi nasıl tasarlanmalıdır?**

Eczanem, offline-first yaklaşımını başarıyla uygulayan bir hibrit mimari örneği sunmaktadır. Kritik sağlık verileri (ilaç hatırlatıcısı, acil durum kartı, sağlık notları) yalnızca cihaz üzerindeki Hive deposunda tutulurken yapay zekâ servisleri yalnızca bağlantı mevcutken kullanılmaktadır. Bu ayrım, ağ bağlantısı kesintileri sırasında bile uygulamanın temel sağlık yönetimi işlevlerini yerine getirmesini sağlamaktadır.

**RQ4: Türk sağlık bilişimi bağlamında, hasta güvenliğini destekleyen bir ilaç bilgi sistemi mevcut açık API'lerle uygulanabilir mi?**

TİTCK resmi ilaç API'si yokluğuna karşın sistem, Gemini'nin geniş eğitim verisi ve web kazıma teknikleriyle işlevselliğini sürdürmektedir. Bu yaklaşım, üçüncü taraf veri kaynaklarına bağımlılığı beraberinde getirmekle birlikte kısa vadeli pratik bir çözüm sunmaktadır. Uzun vadede TİTCK'ın açık API hizmeti sunması, bu tür projelerin veri kalitesi ve güvenilirliğini önemli ölçüde iyileştirecektir.


Çalışmanın Katkıları

Bu çalışma aşağıdaki özgün katkıları sunmaktadır:

1. **Bütünleşik Türkçe mHealth Platformu:** 12 farklı sağlık işlevini tek platformda birleştiren ve Türk kullanıcı kitlesine özel olarak tasarlanan açık kaynak bir mobil uygulama.

2. **Hibrit Çevrimdışı-Bulut Mimarisi:** Hive yerel depolama ile FastAPI bulut servisini clean architecture katmanlarıyla bir araya getiren belgelenmiş bir tasarım modeli.

3. **LLM Tabanlı Türkçe İlaç Bilgisi:** Kamuya açık TİTCK API'si olmaksızın Gemini 2.5 Flash modeliyle Türkçe ilaç bilgisi üretimini gerçekleştiren prompt mühendisliği yaklaşımı.

4. **Multimodal İlaç Tanıma:** İlaç kutusu ve prospektüs görüntülerinden yapılandırılmış klinik özet çıkaran entegre görüntü işleme akışı.

5. **Test Edilmiş Veri Katmanı:** Clean Architecture prensiplerine dayalı 42 birim testiyle doğrulanmış, bakımı kolay bir veri modeli altyapısı.


Çalışmanın Sınırlılıkları

Bu çalışmanın aşağıdaki sınırlılıkları bulunmaktadır:

- **LLM Doğruluk Değerlendirmesi:** Gemini yanıtlarının klinik doğruluğu bağımsız eczacı veya hekim değerlendirmesiyle ölçülmemiştir. Akademik rigor açısından bu ölçümün gelecek çalışmalarda gerçekleştirilmesi gerekmektedir.

- **Halüsinasyon Riski:** Büyük dil modelleri, ilaç bilgisi gibi kritik alanlarda yanlış bilgi üretebilir. Uygulanan teknik önlemler (düşük temperature, yapılandırılmış çıktı, güvenlik uyarıları) bu riski azaltmakta fakat tamamen ortadan kaldırmamaktadır.

- **Web Kazıma Kırılganlığı:** Nöbetçi eczane verisi, kaynak web sitesinin yapısal değişikliklerine karşı hassas olan web kazıma yöntemiyle elde edilmektedir.

- **Backend Entegrasyon Testi Eksikliği:** Mevcut test kapsamı veri modeli katmanına odaklanmaktadır; API endpoint ve AI servis testleri henüz uygulanmamıştır.

- **Kullanıcı Çalışması Yapılmamıştır:** Gerçek kullanıcılarla kullanılabilirlik (usability) veya klinik etkinlik çalışması yürütülmemiştir.


Gelecek Çalışma Önerileri

Bu çalışmanın devamı niteliğinde aşağıdaki araştırma yönleri önerilmektedir:

1. **Klinik Doğruluk Değerlendirmesi:** Gemini yanıtlarının eczacı uzman grubu tarafından bağımsız değerlendirilerek kesinlik (precision) ve geri çağırma (recall) metriklerinin ölçülmesi.

2. **İnce Ayar (Fine-tuning) Araştırması:** TİTCK ilaç prospektüs metinleri üzerinde küçük boyutlu açık kaynak LLM'lerin fine-tuning ile Türkçe ilaç alanına uyarlanması.

3. **TİTCK API Entegrasyonu:** TİTCK'ın resmi API hizmeti sunması durumunda web kazıma yaklaşımının halef olacak entegrasyon mimarisinin tasarımı.

4. **Klinik Karar Destek Genişlemesi:** Kronik hastalık takibi (diyabet, hipertansiyon) için kişiselleştirilmiş risk değerlendirme modüllerinin eklenmesi.

5. **Federe Öğrenme (Federated Learning):** Kullanıcı verilerinin merkezi sunucuya gönderilmeksizin kişiselleştirilmiş ilaç önerisi modelinin eğitilmesi.

6. **Wearable Entegrasyonu:** Akıllı saat ve fitness tracker verilerinin (kalp atış hızı, uyku düzeni) sağlık notları modülüyle ilişkilendirilmesi.


Genel Değerlendirme

Eczanem, Türkiye'deki bireysel ilaç kullanıcıları için mevcut dijital araçlardaki boşluğu doldurmaya yönelik işlevsel, test edilmiş ve açık kaynak bir platform olarak geliştirilmiştir. Flutter ve FastAPI teknoloji yığınının hibrit offline-cloud mimarisiyle birleşimi, mHealth uygulama geliştirme için yeniden kullanılabilir bir referans model sunmaktadır. Çalışma, TİTCK API yokluğu gibi altyapısal kısıtların varlığında bile anlamlı bir mHealth çözümünün geliştirilebileceğini pratikte göstermektedir.
