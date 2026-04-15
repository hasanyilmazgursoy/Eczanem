import re

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r\"'\\s*aktif hat[\\s\\S]*?var\.'\", r\"'\ tane aktif hatırlatıcınız var.'\", text)

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
