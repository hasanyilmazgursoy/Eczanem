"""Vize ara raporunu Word (.docx) formatında üretir."""

from docx import Document
from docx.shared import Pt, Cm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
import os

doc = Document()

# Sayfa kenar boşlukları
for section in doc.sections:
    section.top_margin = Cm(2.5)
    section.bottom_margin = Cm(2.5)
    section.left_margin = Cm(2.5)
    section.right_margin = Cm(2.5)

# Varsayılan stil
style = doc.styles["Normal"]
font = style.font
font.name = "Calibri"
font.size = Pt(11)
style.paragraph_format.space_after = Pt(6)
style.paragraph_format.line_spacing = 1.15


def add_heading(text, level=1):
    h = doc.add_heading(text, level=level)
    for run in h.runs:
        run.font.color.rgb = RGBColor(0x1A, 0x47, 0x6F)
    return h


def add_para(text, bold=False, italic=False, align=None):
    p = doc.add_paragraph()
    run = p.add_run(text)
    run.bold = bold
    run.italic = italic
    if align:
        p.alignment = align
    return p


def add_table(headers, rows):
    table = doc.add_table(rows=1, cols=len(headers), style="Light Grid Accent 1")
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    # Başlık satırı
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for paragraph in cell.paragraphs:
            for run in paragraph.runs:
                run.bold = True
                run.font.size = Pt(10)
    # Veri satırları
    for row_data in rows:
        row = table.add_row()
        for i, val in enumerate(row_data):
            row.cells[i].text = val
            for paragraph in row.cells[i].paragraphs:
                for run in paragraph.runs:
                    run.font.size = Pt(10)
    doc.add_paragraph()  # Tablo sonrası boşluk
    return table


# ── KAPAK ──
doc.add_paragraph()
doc.add_paragraph()
title = doc.add_heading("Eczanem — Bitirme Projesi\nVize Ara Raporu", level=0)
title.alignment = WD_ALIGN_PARAGRAPH.CENTER
for run in title.runs:
    run.font.color.rgb = RGBColor(0x1A, 0x47, 0x6F)

doc.add_paragraph()
info_lines = [
    ("Öğrenci:", "Hasan"),
    ("Danışman:", "Hasan Yetiş"),
    ("Tarih:", "15 Nisan 2026"),
    ("Proje Başlangıç Tarihi:", "9 Nisan 2026"),
]
for label, value in info_lines:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run_label = p.add_run(f"{label} ")
    run_label.bold = True
    run_label.font.size = Pt(12)
    run_val = p.add_run(value)
    run_val.font.size = Pt(12)

doc.add_page_break()

# ── 1. PROJE TANIMI ──
add_heading("1. Proje Tanımı ve Amacı")
add_para(
    "Eczanem, kullanıcıların ilaç bilgilerini metin veya fotoğraf aracılığıyla sorgulayabildiği, "
    "ilaçlar arası etkileşim kontrolü yapabildiği, hatırlatıcı kurabildiği ve prospektüs özetleri "
    "oluşturabildiği kapsamlı bir mobil sağlık asistanı uygulamasıdır."
)
add_para(
    "Projenin temel amacı; bireylerin günlük ilaç kullanım süreçlerini kolaylaştırmak, ilaç bilgilerine "
    "hızlı ve anlaşılır biçimde erişim sağlamak ve olası ilaç etkileşimi risklerini kullanıcıya önceden "
    "bildirmektir. Uygulama, yapay zekâ destekli analiz yetenekleri sayesinde geleneksel ilaç rehberi "
    "uygulamalarının ötesine geçmeyi hedeflemektedir."
)

# ── 2. TEKNOLOJİLER ──
add_heading("2. Kullanılan Teknolojiler ve Yöntemler")

add_heading("2.1 Mobil Uygulama (İstemci)", level=2)
add_table(
    ["Teknoloji", "Kullanım Amacı"],
    [
        ["Flutter (Dart)", "Çapraz platform mobil uygulama geliştirme"],
        ["Riverpod", "State management (durum yönetimi)"],
        ["Dio", "HTTP istemci katmanı (backend iletişimi)"],
        ["GoRouter", "Deklaratif sayfa yönlendirme"],
        ["Hive", "Yerel veri depolama (geçmiş, hatırlatıcılar)"],
        ["flutter_secure_storage", "JWT token'ların güvenli saklanması"],
        ["camera / image_picker", "Kamera ile çekim ve galeriden görsel seçme"],
        [
            "flutter_local_notifications",
            "Offline çalışan ilaç hatırlatıcı bildirimleri",
        ],
        ["easy_localization", "Çoklu dil (Türkçe/İngilizce) desteği"],
    ],
)

add_heading("2.2 Backend (Sunucu)", level=2)
add_table(
    ["Teknoloji", "Kullanım Amacı"],
    [
        ["FastAPI (Python)", "RESTful API sunucusu"],
        ["Google Gemini API", "Yapay zekâ destekli ilaç sorgulama ve görsel analiz"],
        ["JWT", "Kullanıcı kimlik doğrulama ve oturum yönetimi"],
        ["Redis", "API yanıt cache'leme (24 saat) ve rate limiting"],
        ["bcrypt", "Parola hash'leme"],
        ["Docker Compose", "Geliştirme ortamı konteynerizasyonu"],
    ],
)

add_heading("2.3 Mimari Yaklaşım", level=2)
add_para(
    "Proje, Clean Architecture prensiplerine uygun olarak katmanlı bir yapıda tasarlanmıştır:"
)
bullets = [
    "Mobil taraf: Feature-first klasör yapısı (features/auth, features/drug, features/reminder); "
    "her özellik kendi data, domain ve presentation katmanlarına sahiptir.",
    "Backend taraf: Modüler FastAPI yapısı (routers, services, models, schemas) ile sorumluluklar ayrılmıştır.",
    "Veri akışı: Mobil ↔ Backend arasında HTTPS üzerinden JSON tabanlı RESTful iletişim; "
    "yapay zekâ sorguları backend üzerinden Gemini API'ye yönlendirilmektedir.",
]
for b in bullets:
    doc.add_paragraph(b, style="List Bullet")
doc.add_paragraph()

add_heading("2.4 Yapay Zekâ Kullanımı", level=2)
add_para(
    "Projede Google Gemini büyük dil modeli (LLM), aşağıdaki görevler için kullanılmaktadır:"
)
ai_items = [
    "Metin tabanlı ilaç sorgulama: İlaç adı girilerek etken madde, dozaj, yan etkiler, uyarılar ve "
    "kullanım şekli bilgilerinin yapılandırılmış JSON formatında üretilmesi.",
    "Görsel ilaç tanıma: İlaç kutusu, blister veya etiket fotoğrafından ilacın tanımlanması (multimodal analiz).",
    "Prospektüs özetleme: Prospektüs veya kutu arkası görselinden okunabilir, kategorize edilmiş özet oluşturulması.",
    "İlaç etkileşim analizi: Birden fazla ilacın birlikte kullanım risklerinin değerlendirilmesi.",
    "Doğal alternatif önerileri: Belirli bir ilaç için bitkisel/doğal alternatif önerilerinin sunulması.",
]
for item in ai_items:
    doc.add_paragraph(item, style="List Bullet")

doc.add_page_break()

# ── 3. YAPILANLAR ──
add_heading("3. Yapılan Çalışmalar ve Mevcut Durum")
add_para(
    "Proje, 9 Nisan 2026 tarihinde başlamış olup bugüne kadar aşağıdaki fazlar tamamlanmıştır:"
)

add_heading("3.1 Tamamlanan Fazlar", level=2)

phases = [
    (
        "FAZ 0 — Altyapı ve Kurulum",
        "Flutter proje iskeleti, backend API yapısı, ortam değişkenleri, CORS ayarları ve sağlık kontrolü "
        "endpoint'i hazırlanmıştır. Riverpod, Dio, GoRouter, Hive gibi temel paketler entegre edilmiştir.",
    ),
    (
        "FAZ 1 — Temel İlaç Sorgulama (MVP)",
        "Kullanıcı ilaç adını yazarak arama yapabilmekte, Gemini API üzerinden etken madde, dozaj, yan etkiler "
        "ve uyarı bilgilerini görüntüleyebilmektedir. Arama debounce (500ms), skeleton loading, arama geçmişi "
        "ve hata yönetimi tamamlanmıştır. Redis tabanlı 24 saat cache ve IP bazlı rate limiting aktiftir.",
    ),
    (
        "FAZ 2 — Kamera ile İlaç Tanıma ve Prospektüs Tarama",
        "Kamera veya galeriden seçilen ilaç kutusu fotoğrafı, Gemini multimodal API ile analiz edilmektedir. "
        "Çoklu ilaç adayı akışı (reçetede birden fazla ilaç tanıma) desteklenmektedir. Prospektüs fotoğrafından "
        "kategorize özet üretilmektedir. Görsel sıkıştırma ve yeniden boyutlandırma ile maliyet optimizasyonu yapılmıştır.",
    ),
    (
        "Ara Faz — Geçmiş Merkezi ve Profil Kısayolları",
        "Arama geçmişi ve tarama geçmişi ekranları oluşturulmuş, profil sekmesindeki kısayollarla entegre edilmiştir. "
        "Tekrar sorgulama, tekli silme ve tümünü temizleme işlevleri eklenmiştir.",
    ),
    (
        "FAZ 4 — İlaç Hatırlatıcı ve Stok Takibi",
        "Kullanıcı belirli saatlerde ilaç hatırlatıcısı kurabilmekte, günlük tekrar eden offline bildirimler "
        "alabilmektedir. Stok takip dashboard'u ile kalan tablet sayısına göre otomatik bitiş süresi hesaplanmakta, "
        "3 gün öncesinden düşük stok uyarısı verilmektedir. Bildirimler cihaz yeniden başlatması sonrası da korunmaktadır.",
    ),
    (
        "FAZ 5 — İlaç Etkileşim Kontrolü ve Doğal Alternatifler",
        "Kullanıcı birden fazla ilacı girerek aralarındaki etkileşimi kontrol edebilmektedir. Sonuçlar renk "
        "kodlarıyla (güvenli / dikkatli / tehlikeli) sunulmaktadır. İlaç detay ekranından doğal alternatif "
        "önerilerine erişim sağlanmaktadır.",
    ),
]
for phase_title, phase_desc in phases:
    add_heading(phase_title, level=3)
    add_para(phase_desc)

add_heading("3.2 Kısmen Tamamlanan Alanlar", level=2)
add_heading("FAZ 3 — Kullanıcı Sistemi ve Aile Profili", level=3)
add_para(
    "JWT tabanlı kayıt, giriş, oturum yönetimi ve şifre hash'leme altyapısı tamamlanmıştır. "
    "Aile profili yönetimi (aile bireyi ekleme, birey bazlı ilaç listesi) henüz geliştirilmemiştir."
)

add_heading("3.3 Çalışan Backend API Endpoint'leri", level=2)
add_table(
    ["Endpoint", "Yöntem", "İşlev"],
    [
        ["/health", "GET", "Sunucu sağlık kontrolü"],
        ["/api/auth/signup", "POST", "Kullanıcı kaydı"],
        ["/api/auth/login", "POST", "Giriş ve JWT token alma"],
        ["/api/auth/me", "GET", "Oturum bilgisi sorgulama"],
        ["/api/drug/search", "POST", "İlaç adıyla bilgi sorgulama"],
        ["/api/drug/analyze-image", "POST", "Görsel ilaç tanıma"],
        ["/api/drug/prospectus-summary", "POST", "Prospektüs özeti"],
        ["/api/drug/interactions", "POST", "İlaç etkileşim kontrolü"],
        ["/api/drug/natural-alternatives", "POST", "Doğal alternatif önerileri"],
    ],
)

add_heading("3.4 Doğrulama ve Test", level=2)
tests = [
    "Mobil uygulama flutter analyze ile statik analiz kontrolünden geçmektedir (sorun yok).",
    "flutter test ile hatırlatıcı repository ve ilaç geçmişi repository birim testleri başarıyla çalışmaktadır.",
    "Backend python -m compileall ile derleme doğrulamasından geçmektedir.",
    "Uygulama gerçek Android cihazda LAN bağlantısıyla test edilmiştir.",
]
for t in tests:
    doc.add_paragraph(t, style="List Bullet")

doc.add_page_break()

# ── 4. FİNAL ──
add_heading("4. Final İçin Yapılabilecekler ve Beklenen Etki")

add_heading("4.1 Planlanan Geliştirmeler", level=2)
add_table(
    ["Faz", "Modül", "Açıklama"],
    [
        [
            "FAZ 3",
            "Aile Profili",
            "Aile bireyi ekleme, birey bazlı ilaç listesi yönetimi",
        ],
        [
            "FAZ 6",
            "Nöbetçi Eczane + Sesli Sorgu",
            "Konum tabanlı nöbetçi eczane bulma, harita entegrasyonu, sesli ilaç arama",
        ],
        [
            "FAZ 7",
            "Acil Durum Kartı",
            "Kan grubu, alerji, kronik hastalık bilgileri; PDF dışa aktarım; sağlık günlüğü",
        ],
        [
            "FAZ 8",
            "Test ve Yayın",
            "UI polish, karanlık mod, onboarding, kapsamlı test yazımı, Play Store yayını",
        ],
    ],
)

add_heading("4.2 Beklenen Etkiler", level=2)
effects = [
    "Aile Profili ile uygulama bireysel kullanımın ötesine geçerek aile bazlı ilaç yönetimi sunacaktır. "
    "Özellikle yaşlı aile bireyleri veya çocuklar için ilaç takibini kolaylaştıracaktır.",
    "Nöbetçi Eczane entegrasyonu ile kullanıcılar en yakın açık eczaneyi harita üzerinde görebilecek, "
    "yol tarifi alabilecek ve doğrudan arayabilecektir.",
    "Sesli Sorgulama ile yaşlı veya görme engelli kullanıcılar da uygulamayı rahatça kullanabilecektir.",
    "Acil Durum Kartı kritik sağlık bilgilerini tek bir ekranda sunarak acil durumlarda hızlı bilgi erişimi sağlayacaktır.",
    "Play Store Yayını ile uygulama gerçek kullanıcılara ulaştırılabilecek, kullanılabilirlik geri bildirimleri toplanabilecektir.",
]
for e in effects:
    doc.add_paragraph(e, style="List Bullet")

add_heading("4.3 Projenin Genel Etkisi", level=2)
add_para(
    "Eczanem projesi, yapay zekâ tabanlı ilaç bilgi erişimi, görsel tanıma, etkileşim analizi ve hatırlatıcı "
    "sistemlerini tek bir mobil uygulamada birleştirmektedir. Proje tamamlandığında:"
)
impacts = [
    "Kullanıcılar ilaç bilgilerine metin, fotoğraf veya ses yoluyla hızlı erişim sağlayabilecek,",
    "İlaç etkileşim riskleri proaktif olarak tespit edilerek olası sağlık sorunlarının önüne geçilebilecek,",
    "Hatırlatıcı ve stok takip sistemiyle tedaviye uyum oranı artırılabilecek,",
    "Aile bazlı ilaç yönetimi ile birden fazla bireyin ilaç takibi merkezi bir noktadan yapılabilecektir.",
]
for imp in impacts:
    doc.add_paragraph(imp, style="List Bullet")

# ── 5. ÖZET ──
add_heading("5. Özet")
add_para(
    "Proje, 9 Nisan 2026'da başlamış olup bir haftalık süreçte planlanan 8 fazdan 5'i tamamlanmış, "
    "1'i kısmen hazırlanmıştır. Metin ve görsel tabanlı ilaç sorgulama, prospektüs özetleme, etkileşim "
    "kontrolü, doğal alternatif önerileri, ilaç hatırlatıcı ve stok takibi gibi çekirdek özellikler çalışır "
    "durumdadır. Backend ve mobil uygulama arasında güvenli iletişim, JWT kimlik doğrulama, Redis cache, "
    "rate limiting ve offline bildirim altyapısı kurulmuştur."
)
add_para(
    "Final dönemine kadar aile profili tamamlama, nöbetçi eczane entegrasyonu, sesli sorgulama, acil durum "
    "kartı ve uygulama yayınlama fazlarının gerçekleştirilmesi planlanmaktadır."
)

# Kaydet
output_path = os.path.join(os.path.dirname(__file__), "Eczanem_Vize_Ara_Rapor.docx")
doc.save(output_path)
print(f"Rapor oluşturuldu: {output_path}")
