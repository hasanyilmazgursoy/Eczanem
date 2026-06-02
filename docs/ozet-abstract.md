ÖZET

Bu çalışmada, Türkiye'deki bireylerin ilaç bilgisine erişimde yaşadığı güçlükleri gidermek amacıyla yapay zekâ destekli bir kişisel ilaç yönetim uygulaması olan Eczanem geliştirilmiştir. Uygulama; ilaç arama, görüntüden ilaç tanıma, prospektüs özetleme, ilaç etkileşim analizi, doğal alternatif önerileri, semptom değerlendirme, sağlık asistanı sohbeti, çevrimdışı ilaç hatırlatıcısı, nöbetçi eczane haritası, sağlık günlüğü, acil durum kartı ve aile profili yönetimi işlevlerini tek bir platformda bütünleştirmektedir.

Sistem, iki ana bileşenden oluşmaktadır. Mobil istemci Flutter (Dart) çerçevesi kullanılarak geliştirilmiş; Clean Architecture prensipleri ve Riverpod durum yönetimi ile dokuz özellik modülüne ayrılmıştır. Sunucu tarafında FastAPI (Python) tabanlı RESTful bir API katmanı bulunmakta olup yapay zekâ hizmetleri Google Gemini 2.5 Flash büyük dil modeli aracılığıyla sağlanmaktadır.

Sistemin performans ve güvenilirliği için Redis tabanlı iki katmanlı önbellek mekanizması (24 saatlik TTL), IP bazlı kayar pencere hız sınırlaması ve exponential backoff yeniden deneme stratejisi uygulanmıştır. Yerel veriler Hive NoSQL deposunda saklanarak kritik sağlık bilgilerinin (ilaç hatırlatıcısı, acil durum kartı) çevrimdışı ortamda da erişilebilir olması sağlanmıştır.

Çalışma kapsamında toplam 42 birim testi yazılmış, altı test dosyası üzerinde fonksiyonel doğrulama gerçekleştirilmiştir. Geliştirilen sistem, mevcut benzer uygulamalarla (Ada Health, Eczane.net, TİTCK, Medisafe) karşılaştırmalı olarak değerlendirilmiş; Türkiye pazarında yapay zekâ destekli, çevrimdışı-dayanıklı ve yerel öncelikli veri gizliliği anlayışıyla tasarlanmış bütünleşik bir çözüm sunulduğu ortaya konulmuştur.

Anahtar Kelimeler: Mobil Sağlık Uygulaması, Yapay Zekâ, Büyük Dil Modeli, Flutter, FastAPI, İlaç Yönetimi, Google Gemini, Prompt Mühendisliği


---


ABSTRACT

In this study, Eczanem, an artificial intelligence-powered personal medication management application, was developed to address the difficulties faced by individuals in Turkey in accessing drug information. The application integrates drug search, image-based drug identification, package insert summarization, drug interaction analysis, natural alternative suggestions, symptom assessment, health assistant chatbot, offline medication reminder, on-duty pharmacy map, health diary, emergency card, and family profile management into a single platform.

The system consists of two main components. The mobile client was developed using the Flutter (Dart) framework, organized into nine feature modules following Clean Architecture principles with Riverpod state management. On the server side, a RESTful API layer based on FastAPI (Python) is used, with artificial intelligence services provided through the Google Gemini 2.5 Flash large language model.

To ensure system performance and reliability, a two-tier Redis-based caching mechanism (24-hour TTL), IP-based sliding window rate limiting, and exponential backoff retry strategy were implemented. Local data is stored in a Hive NoSQL store, ensuring that critical health information (medication reminders, emergency card) remains accessible in offline environments.

Within the scope of the study, 42 unit tests were written and functional validation was performed across six test files. The developed system was comparatively evaluated against similar existing applications (Ada Health, Eczane.net, TİTCK, Medisafe), demonstrating that an integrated solution designed with AI support, offline resilience, and a local-first data privacy approach is presented for the Turkish market.

Keywords: Mobile Health Application, Artificial Intelligence, Large Language Model, Flutter, FastAPI, Medication Management, Google Gemini, Prompt Engineering
