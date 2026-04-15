import re

with open('lib/src/features/home/presentation/screens/home_page.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('showModalBottomSheet(', 'showModalBottomSheet<void>(')
text = text.replace('Divider(),', 'const Divider(),')
text = text.replace('const const', 'const')

with open('lib/src/features/home/presentation/screens/home_page.dart', 'w', encoding='utf-8') as f:
    f.write(text)
