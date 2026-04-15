import sys

def fix_file(path):
    with open(path, 'rb') as f:
        content = f.read()
    
    # remove all occurances of BOM
    content = content.replace(b'\xef\xbb\xbf', b'')
    
    # save back
    with open(path, 'wb') as f:
        f.write(content)

fix_file('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart')
fix_file('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart')
