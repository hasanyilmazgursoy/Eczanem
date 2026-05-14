"""Backend Python dosyalarındaki double-encoded UTF-8 karakterleri düzeltir.

Double-encoding oluşumu:
  Doğru UTF-8: ç = \xc3\xa7
  Bozuk hale gelmesi: \xc3\xa7 Latin-1 gibi okunup tekrar UTF-8'e encode edilince
  → Ã§ = \xc3\x83\xc2\xa7
"""
import os

# Bozuk → doğru byte eşlemeleri (Türkçe harfler + yaygın semboller)
REPLACEMENTS = [
    (b'\xc3\x83\xc2\xa7', b'\xc3\xa7'),   # ç
    (b'\xc3\x84\xc2\xb1', b'\xc4\xb1'),   # ı
    (b'\xc3\x84\xc5\xb8', b'\xc4\x9f'),   # ğ
    (b'\xc3\x85\xc5\xb8', b'\xc5\x9f'),   # ş
    (b'\xc3\x84\xc2\xb0', b'\xc4\xb0'),   # İ
    (b'\xc3\x83\xc2\xb6', b'\xc3\xb6'),   # ö
    (b'\xc3\x83\xc2\xbc', b'\xc3\xbc'),   # ü
    (b'\xc3\x83\xc2\x87', b'\xc3\x87'),   # Ç
    (b'\xc3\x84\xc2\x9f', b'\xc4\x9f'),   # ğ (alternatif)
    (b'\xc3\x85\xc2\x9f', b'\xc5\x9f'),   # ş (alternatif)
    (b'\xc3\x83\xc2\x96', b'\xc3\x96'),    # Ö  (Latin-1 yolu)
    (b'\xc3\x83\xe2\x80\x93', b'\xc3\x96'),  # Ö  (Windows-1252 yolu: \x96 → en dash)
    (b'\xc3\x83\xc2\x9c', b'\xc3\x9c'),   # Ü
    (b'\xc3\x84\xc2\x9e', b'\xc4\x9e'),   # Ğ
    (b'\xc3\x84\xc2\xb0', b'\xc4\xb0'),   # İ (tekrar)
    (b'\xc3\x83\x82\xc2\xb1', b'\xc4\xb1'),  # ı (üçlü encode)
]

backend_dir = 'c:/Users/hasan/Desktop/Eczanem/backend'
fixed_files = []

for root, _, files in os.walk(backend_dir):
    if '__pycache__' in root:
        continue
    for fname in files:
        if not fname.endswith('.py'):
            continue
        path = os.path.join(root, fname)
        with open(path, 'rb') as f:
            original = f.read()

        content = original
        for bad, good in REPLACEMENTS:
            content = content.replace(bad, good)

        if content != original:
            with open(path, 'wb') as f:
                f.write(content)
            fixed_files.append(path)
            print(f'Düzeltildi: {path}')

if not fixed_files:
    print('Bozuk dosya bulunamadı, tümü temiz.')
else:
    print(f'\nToplam {len(fixed_files)} dosya düzeltildi.')
