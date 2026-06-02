1. GİRİŞ

Sağlık hizmetlerine erişimin giderek daha karmaşık bir hal aldığı günümüzde, bireylerin kendi sağlıklarını yönetme kapasitesini artırmak kritik bir gereksinim hâline gelmiştir. Türkiye'de kronik hastalık yükü sürekli artmakta ve yaşlı nüfus oranı her geçen yıl yükselmektedir [1]. Bu demografik dönüşüm, ilaç kullanımının hem yaygınlığını hem de karmaşıklığını beraberinde getirmektedir. Birden fazla hastalığı olan hastalar çoğunlukla polifarmasi durumunda; yani birden fazla ilacı aynı anda kullanmak durumundadır. Bu durum, ilaç etkileşimi riskini, yanlış doz alma olasılığını ve ilaç uyumunu (adherence) olumsuz etkileyen faktörleri büyük ölçüde artırmaktadır [2].

Türkiye İlaç ve Tıbbi Cihaz Kurumu (TİTCK), geniş kapsamlı bir ilaç veri tabanına sahip olmasına karşın bu veri tabanına programatik erişim sağlayan açık bir uygulama programlama arayüzü (API) sunmamaktadır. Bu yapısal eksiklik, yazılım geliştiricilerin ulusal ilaç verisine doğrudan erişememesi anlamına gelmektedir. Mevcut mobil sağlık uygulamaları ise ya yalnızca nöbetçi eczane arama (Eczane.net), ya yalnızca ilaç hatırlatma (Medisafe), ya da yalnızca semptom değerlendirme (Ada Health) gibi tek bir işleve odaklanmaktadır. Birden fazla özelliği Türkçe destekli ve yapay zekâ entegrasyonlu biçimde sunan bütünleşik bir çözüm literatürde henüz belgelenmemiştir.

Bu bağlamda, yapay zekâ destekli kişisel ilaç yönetim sistemi Eczanem geliştirilmiştir. Eczanem; ilaç arama, görüntüden ilaç tanıma, prospektüs özetleme, ilaç etkileşim analizi, doğal alternatif önerileri, semptom değerlendirme, çok turlu sağlık asistanı sohbeti, çevrimdışı ilaç hatırlatıcısı, nöbetçi eczane haritası, sağlık günlüğü, acil durum kartı ve aile profili yönetimi işlevlerini tek bir mobil platformda birleştirmektedir.

Proje, iki temel teknoloji katmanından oluşmaktadır. Mobil uygulama Flutter (Dart) çerçevesi ile geliştirilmiş; sunucu tarafı ise FastAPI (Python) tabanlı bir RESTful mimarisi üzerine inşa edilmiştir. Yapay zekâ bileşeni olarak Google'ın Gemini 2.5 Flash büyük dil modeli kullanılmıştır. Bu model, hem metin tabanlı sorgulara hem de görüntü tabanlı analizlere yanıt verebilen çok modlu (multimodal) bir yapıya sahip olup Türkçe dil desteğiyle uygulamanın hedef kullanıcı kitlesine uygun bir deneyim sunmaktadır.

Çalışmanın temel araştırma soruları aşağıdaki şekilde belirlenmiştir:

RQ1: Büyük dil modelleri, yapılandırılmamış Türkçe metin girdileriyle ilaç bilgisini ne ölçüde doğru ve tutarlı biçimde üretebilir?

RQ2: Multimodal yapay zekâ modelleri, ilaç kutusu veya prospektüs görüntülerinden klinik açıdan anlamlı bilgileri başarıyla çıkarabilir mi?

RQ3: Mobil sağlık uygulamalarında istemci taraflı veri yerelliği ile bulut tabanlı yapay zekâ servislerinin hibrit mimarisi nasıl tasarlanmalıdır?

RQ4: Türk sağlık bilişimi bağlamında, hasta güvenliğini destekleyen bir ilaç bilgi sistemi mevcut açık API'lerle uygulanabilir mi?

Tez çalışmasının kapsam ve sınırlılıkları şu şekilde özetlenebilir: Uygulama geliştirme süreci Nisan 2026 ile Haziran 2026 dönemini kapsamaktadır. Sistem, klinik bir tanı veya tedavi aracı olarak tasarlanmamış; bireysel sağlık okuryazarlığını destekleyici bir yardımcı sistem olarak konumlandırılmıştır. Tüm yapay zekâ yanıtları "Bu bilgiler genel amaçlıdır; kesin tanı ve tedavi için doktorunuza danışınız" uyarısıyla sunulmaktadır. Gemini modelinin halüsinasyon üretme riski çalışmanın temel sınırlılıklarından birini oluşturmakta olup bu risk, düşük sıcaklık (temperature=0.3) ayarı ve yapılandırılmış JSON çıktı zorunluluğuyla minimize edilmeye çalışılmıştır.

Tezin devam eden bölümleri aşağıdaki şekilde organize edilmiştir: İkinci bölümde mHealth uygulamaları, büyük dil modelleri ve ilaç yönetim sistemleri üzerine yapılan literatür taramasına yer verilmektedir. Üçüncü bölümde sistemin mimari tasarımı; backend, mobil istemci ve yapay zekâ entegrasyon katmanları kapsamında ele alınmaktadır. Dördüncü bölümde uygulamanın özellik modülleri ve teknik detayları aktarılmaktadır. Beşinci bölümde birim testleri ve performans değerlendirmesine ilişkin bulgular sunulmaktadır. Son bölümde ise çalışmadan elde edilen sonuçlar özetlenerek gelecek araştırma yönlerine ilişkin öneriler paylaşılmaktadır.
