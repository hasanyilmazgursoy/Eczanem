2. İLGİLİ ÇALIŞMALAR VE LİTERATÜR TARAMASI

Bu bölümde, çalışmanın temel araştırma alanlarını oluşturan mobil sağlık uygulamaları, büyük dil modelleri ve sağlık bilişimi, multimodal yapay zekâ sistemleri, Flutter tabanlı mHealth çalışmaları ve Türkiye sağlık bilişimi bağlamı üzerine yürütülen literatür taraması sunulmaktadır.


2.1 Mobil Sağlık Uygulamaları (mHealth)

Dünya Sağlık Örgütü (WHO), "mHealth" kavramını mobil cihazlar aracılığıyla sağlıklı yaşam ve hastalık yönetimini destekleyen uygulamaların bütünü olarak tanımlamaktadır [3]. Küresel uygulama mağazalarında 350.000'i aşkın sağlık uygulaması yer almakta olmakla birlikte bu uygulamaların büyük bölümü kronolojik olarak belirli bir hastalık ya da işlev alanına odaklanmaktadır [4].

Ventola [5], ilaç uyumunu artırmaya yönelik mobil uygulamaların etkinliğini sistematik biçimde incelemiş ve bildirim tabanlı hatırlatıcıların hasta uyumunu ortalama %15-25 oranında iyileştirdiğini ortaya koymuştur. Bu bulgu, Eczanem'in çevrimdışı ilaç hatırlatıcısı modülünü tasarlamadaki motivasyonu doğrudan desteklemektedir.

Boudreaux ve ark. [6], mHealth uygulamalarının klinik entegrasyon sürecindeki güvenlik boyutlarını ele almış; uygulamaların Yazılım olarak Tıbbî Cihaz (SaMD) sınıflandırmasına giren durumlarda FDA ya da AB MDR onayı gerektirdiğine dikkat çekmiştir. Eczanem, tanı koymak yerine bilgi sunma işleviyle bu sınıflandırmanın dışında konumlandırılmıştır.

Klasik mHealth çalışmalarının kısıtı, çevrimdışı işlevsellik ile bulut tabanlı yapay zekâ hizmetlerini aynı mimaride birleştiren hibrit sistemlerin yeterince araştırılmamış olmasıdır. Bu çalışma söz konusu açığı gidermeye yönelik özgün bir katkı sunmaktadır.


2.2 Büyük Dil Modelleri ve Sağlık Bilişimi

Büyük dil modelleri (LLM), sağlık alanında klinik karar destek sistemleri, tıbbi belge özetleme ve hasta eğitimi gibi çeşitli kullanım senaryolarında araştırılmaktadır. Singhal ve ark. [7], Google'ın Med-PaLM 2 modelinin ABD Tıp Uzmanlık Sınav sorularında uzman hekim düzeyine yakın doğruluk elde ettiğini göstermiştir. Bu çalışma, genel amaçlı LLM'lerin tıbbi görevlerdeki potansiyelini sistematik olarak ortaya koyan öncü referanslardan biridir.

Nori ve ark. [8], GPT-4'ün klinik soru yanıtlama, tıbbi özetleme ve biçimlendirme görevlerindeki kapasitesini değerlendirmiş; Türkçe gibi düşük kaynaklı (low-resource) dillerde modelin performansının İngilizce'ye kıyasla gerilediğini saptamıştır. Bu bulgu, Eczanem'deki sıcaklık değerinin 0.3 ile sınırlandırılmasını ve yapılandırılmış JSON çıktı zorunluluğunu öngören tasarım kararını desteklemektedir.

Thirunavukarasu ve ark. [9], sağlık alanında LLM kullanımının en kritik riskinin "halüsinasyon" yani modelin gerçek olmayan ama inandırıcı görünen bilgi üretmesi olduğunu vurgulamıştır. Bu risk, Eczanem'de düşük temperature (0.3), role prompting ve güvenlik uyarılarının zorunlu eklenmesiyle hafifletilmeye çalışılmıştır.

Özellikle Türkçe tıbbi bilgi alanında LLM performansını ölçen sistematik bir akademik çalışma henüz literatürde yeterince yer bulmamıştır. Bu boşluk, araştırma sorusu RQ1'in temel motivasyonunu oluşturmaktadır.


2.3 Multimodal Yapay Zekâ ve Tıbbi Görüntü İşleme

Görüntü tabanlı ilaç tanıma ve prospektüs okuma, kâğıt merkezli tıbbi belge ekosisteminin dijitalleştirilmesi açısından kritik bir araştırma sorunudur. Lee ve ark. [10], OCR teknolojilerinin hasta eğitimine yönelik ilaç prospektüs metinlerini ne ölçüde doğru çıkardığını incelemiş ve karmaşık sütun düzenli metinlerde hata oranlarının ciddi boyutlara ulaşabildiğini göstermiştir.

Google'ın Gemini ailesi, birleşik metin-görüntü işleme kapasitesiyle multimodal görevler için açık kaynak alternatiflere kıyasla düşük gecikme süresi ve yüksek Türkçe kapsama oranı sunmaktadır [11]. Eczanem, bu modeli Base64 kodlamalı görüntü verisi üzerinden REST API aracılığıyla kullanarak yüksek maliyet gerektiren özel model eğitiminden kaçınmıştır.

Pillow tabanlı ön işleme (1400×1400 piksel yeniden boyutlandırma ve EXIF döndürme normalleştirmesi) olmaksızın aşırı yüksek çözünürlüklü görüntülerin API gecikme süresini önemli ölçüde artırdığı gözlemlenmiş olup bu bulgu uygulama optimizasyonu açısından değerlidir.


2.4 Flutter ile Mobil Sağlık Uygulamaları

Flutter, tek bir kod tabanından iOS, Android, Web ve masaüstü platformlarına derleme yapılmasını sağlayan açık kaynak bir UI çerçevesidir [12]. MHealth geliştirme bağlamında Flutter'ın tercih edildiği pek çok çalışma yayımlanmış olmakla birlikte özellikle Clean Architecture ve feature-first modüler organizasyonun birlikte ele alındığı kapsamlı bir referans kaynak bulunmamaktadır.

Riverpod, Flutter için reaktif durum yönetimi amacıyla geliştirilen ve Provider'ın sınırlılıklarını aşan bir kütüphanedir [13]. AsyncNotifier + FutureEither<Failure, T> paradigması, Railway Oriented Programming (ROP) yaklaşımını Flutter ekosistemine taşıyan özgün bir pattern olarak değerlendirilmektedir; bu konuda literatürde yeterli akademik referans mevcut değildir.

GoRouter, Flutter ekibi tarafından geliştirilmiş ve Navigator 2.0 API'sini soyutlayan bir navigasyon kütüphanesidir [14]. Eczanem'de 31 rota, kimlik doğrulama ve ilk katılım (onboarding) yönlendirme korumasıyla yönetilmektedir.


2.5 Türkiye Sağlık Bilişimi Bağlamı

Türkiye'de sağlık bilişimi yatırımları son on yılda Sağlıkta Dönüşüm Programı kapsamında hızlanmıştır. Dijital altyapı iyileşmelerine karşın ilaç veri erişimi, bağımsız geliştiriciler için önemli bir kısıt olmaya devam etmektedir [15]. TİTCK, reçeteli ve reçetesiz ilaçlara ait verileri resmi web sitesi üzerinden sunmakta; ancak bu verilere programatik erişimi sağlayan açık bir REST API hizmet vermemektedir.

Nöbetçi eczane bilgisi ise il sağlık müdürlükleri tarafından tutulmakla birlikte standart bir API yayımlanmamıştır. Bu nedenle Eczanem, nöbetçi eczane verilerini eczaneler.gen.tr üzerinden BeautifulSoup4 kütüphanesiyle web kazıma (scraping) yoluyla elde etmekte; koordinat çözümlemesi için Nominatim/OpenStreetMap hizmetini kullanmaktadır. Bu hibrit yaklaşım, üçüncü taraf API bağımlılığını azaltarak veri erişimini olası değişimlere karşı daha dayanıklı kılmaktadır.


2.6 Mevcut Uygulamalarla Karşılaştırmalı Özet

Literatür taraması ve pazar analizi, mevcut çözümlerin hiçbirinin aşağıdaki özellikleri aynı platformda birleştirmediğini ortaya koymaktadır:

| Özellik | Eczanem | Ada Health | Eczane.net | TİTCK | Medisafe |
|---|---|---|---|---|---|
| Türkçe tam destek | ✓ | Kısmen | ✓ | ✓ | ✗ |
| Yapay zekâ entegrasyonu | ✓ | ✓ | ✗ | ✗ | ✗ |
| Görüntüden ilaç tanıma | ✓ | ✗ | ✗ | ✗ | ✗ |
| Çevrimdışı hatırlatıcı | ✓ | ✗ | ✗ | ✗ | ✓ |
| Nöbetçi eczane haritası | ✓ | ✗ | ✓ | ✗ | ✗ |
| Aile profili yönetimi | ✓ | ✗ | ✗ | ✗ | ✓ |
| Açık kaynak / ücretsiz | ✓ | ✗ | ✗ | ✓ | Kısmen |

Bu karşılaştırma, Eczanem'in Türkiye kullanıcı kitlesine yönelik özgün katkısını net biçimde ortaya koymaktadır. Mevcut çalışmaların hiçbirinde çevrimdışı-dayanıklı mimari ile multimodal yapay zekâ entegrasyonu aynı Türkçe platformda buluşmamıştır.
