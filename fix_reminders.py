import re

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''Text(
            '\ tane aktif hatırlatıcınız var.',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),'''

text = re.sub(
    r"Text\([\s\n]*\'medication_reminder\.hero_subtitle\'\.tr\([\s\n]*args: \[[\s\S]*?\],[\s\n]*\),[\s\n]*style: context\.textTheme\.bodyLarge\?\.copyWith\([\s\n]*color: Colors\.white\.withValues\(alpha: 0\.9\),[\s\n]*\),[\s\n]*\),",
    replacement,
    text,
    flags=re.DOTALL
)

with open('mobile/lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
