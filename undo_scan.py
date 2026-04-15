import sys
import subprocess

# We can just checkout from git
# I'll just git checkout the file
try:
    subprocess.run(['git', 'checkout', 'mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart'], check=True)
except Exception as e:
    print('Failed', e)
