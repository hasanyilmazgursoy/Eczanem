import re

def fix_file(path):
    with open(path, 'r', encoding='utf-8-sig', errors='ignore') as f:
        text = f.read()

    # remove all bom chars
    text = text.replace('\ufeff', '')
    
    text = re.sub(r'const\s+EdgeInsets(.{0,100}AppSpacing[^\)]*\))', r'EdgeInsets\1', text, flags=re.DOTALL)
    text = re.sub(r'const\s+SizedBox(.{0,100}AppSpacing[^\)]*\))', r'SizedBox\1', text, flags=re.DOTALL)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(text)

fix_file('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart')
fix_file('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart')
