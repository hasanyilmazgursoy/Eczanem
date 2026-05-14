import json
import re
import os

dart_keys = set()
for root, _, files in os.walk('c:/Users/hasan/Desktop/Eczanem/mobile/lib'):
    for f in files:
        if f.endswith('.dart'):
            txt = open(os.path.join(root, f), encoding='utf-8').read()
            for m in re.findall(r"'([a-zA-Z0-9_.]+)'\.tr\(\)", txt):
                dart_keys.add(m)

with open('c:/Users/hasan/Desktop/Eczanem/mobile/assets/translations/tr.json', encoding='utf-8') as f:
    tr = json.load(f)

def flatten(d, prefix=''):
    result = {}
    for k, v in d.items():
        key = f'{prefix}.{k}' if prefix else k
        if isinstance(v, dict):
            result.update(flatten(v, key))
        else:
            result[key] = v
    return result

flat_tr = flatten(tr)

missing = [k for k in dart_keys if k not in flat_tr and '.' in k]
print(f'Toplam kullanilan anahtar: {len(dart_keys)}')
print(f'tr.json toplam anahtar: {len(flat_tr)}')
print(f'tr.json eksik anahtar sayisi: {len(missing)}')
if missing:
    for m in sorted(missing)[:30]:
        print(' -', m)
