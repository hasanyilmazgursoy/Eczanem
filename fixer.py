import re

with open('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart', 'r', encoding='utf-8-sig') as f:
    text = f.read()

# fix ClipRRect
text = text.replace('ClipRReRect', 'ClipRRect')

# fix const EdgeInsets
text = re.sub(r'const\s*(EdgeInsets.*?AppSpacing[^)]*\))', r'\1', text)
text = re.sub(r'const\s*(SizedBox.*?AppSpacing[^)]*\))', r'\1', text)

with open('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'r', encoding='utf-8-sig') as f:
    rem_text = f.read()

# fix const AppSpacing
rem_text = re.sub(r'const\s*(EdgeInsets.*?AppSpacing[^)]*\))', r'\1', rem_text)
rem_text = re.sub(r'const\s*(SizedBox.*?AppSpacing[^)]*\))', r'\1', rem_text)

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'w', encoding='utf-8') as f:
    f.write(rem_text)
