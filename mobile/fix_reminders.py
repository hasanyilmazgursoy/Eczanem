import re

with open('lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace long text from hero card
replacement = '''            Text(
              'Bugün için planlanan  aktif hatırlatıcınız var.',
              style: context.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),'''
text = re.sub(
    r"Text\([\s\n]*\'medication_reminder\.hero_subtitle\'\.tr\([\s\n]*args: \[[\s\S]*?\],[\s\n]*\),[\s\n]*style: context\.textTheme\.bodyLarge\?\.copyWith\([\s\n]*color: Colors\.white\.withValues\(alpha: 0\.9\),[\s\n]*\),[\s\n]*\),",
    replacement,
    text,
    flags=re.DOTALL
)

with open('lib/src/features/reminder/presentation/screens/medication_reminders_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
