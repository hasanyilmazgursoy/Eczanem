import re

path = r'c:\Users\hasan\Desktop\Eczanem\mobile\lib\src\features\home\presentation\screens\home_page.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''class _HugeActionCard extends StatelessWidget {
  const _HugeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use solid backgrounds for extreme contrast.
    final backgroundColor = isDarkMode ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08);
    final borderColor = isDarkMode ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.5);
    final titleColor = isDarkMode ? color : color.withValues(alpha: 1.0);
    final iconContainerColor = color;
    final iconColor = Colors.white;
    final chevronColor = isDarkMode ? color : color;

    // Ensure subtitle contrast
    final subtitleColor = isDarkMode ? context.colors.onSurfaceVariant.withValues(alpha: 0.9) : context.colors.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                     BoxShadow(
                       color: color.withValues(alpha: 0.3),
                       blurRadius: 8,
                       offset: const Offset(0, 4),
                     )
                  ]
                ),
                child: Icon(icon, color: iconColor, size: 40),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: chevronColor,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }
}'''

text = re.sub(r'class _HugeActionCard extends StatelessWidget \{.*?\n\}\n$', replacement, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
