import re

with open('mobile/lib/src/features/drug/presentation/screens/drug_search_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(
    r'Widget _buildHeader\(\) \{.*?return Column\(.*?\)\;.*?\}',
    '''Widget _buildHeader() {
    return const SizedBox.shrink();
  }''',
    text,
    flags=re.DOTALL
)

with open('mobile/lib/src/features/drug/presentation/screens/drug_search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
