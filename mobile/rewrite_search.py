import re

with open('lib/src/features/drug/presentation/screens/drug_search_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace _buildHeader completely or make it empty
text = re.sub(
    r'Widget _buildHeader\(\) {.*?return Column\(.*?\]\,\n    \);.*?\}',
    '''Widget _buildHeader() {
    return const SizedBox.shrink();
  }''',
    text,
    flags=re.DOTALL
)

with open('lib/src/features/drug/presentation/screens/drug_search_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
