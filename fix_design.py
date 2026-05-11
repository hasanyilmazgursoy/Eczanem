import re

# Fix home_page.dart contrast
path_home = 'mobile/lib/src/features/home/presentation/screens/home_page.dart'
with open(path_home, 'r', encoding='utf-8') as f:
    text_home = f.read()

# Replace _HugeActionCard build method
huge_card_replacement = '''  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Generate highly visible contrasting colors
    final backgroundColor = isDarkMode ? color.withValues(alpha: 0.2) : color;
    final textColor = isDarkMode ? color : Colors.white;
    final subtitleColor = isDarkMode ? color.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8);
    final iconContainerColor = isDarkMode ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white.withValues(alpha: 0.2),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: textColor, size: 40),
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
                        color: textColor,
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
                color: textColor,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }'''

text_home = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*?(?=\n\}\n)', huge_card_replacement, text_home, flags=re.DOTALL)
with open(path_home, 'w', encoding='utf-8') as f:
    f.write(text_home)

# Now fix drug_search_screen.dart
path_search = 'mobile/lib/src/features/drug/presentation/screens/drug_search_screen.dart'
with open(path_search, 'r', encoding='utf-8') as f:
    text_search = f.read()

search_field_replacement = '''  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _searchController,
        focusNode: FocusNode(),
        textInputAction: TextInputAction.search,
        style: context.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        decoration: InputDecoration(
          hintText: 'drug_search.search_hint'.tr(),
          hintStyle: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Icon(
              Icons.search_rounded,
              size: 40,
              color: context.colors.primary,
            ),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 30),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(32),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: AppSpacing.xxl,
            horizontal: AppSpacing.lg,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.trim().length < 3) return;
          _debouncer.run(_searchDrug);
        },
        onSubmitted: (_) => _searchDrug(),
      ),
    );
  }'''

text_search = re.sub(r'  Widget _buildSearchField\(\) \{.*?\n  \}(?=\n\n  Widget _buildRecentSearches)', search_field_replacement, text_search, flags=re.DOTALL)
with open(path_search, 'w', encoding='utf-8') as f:
    f.write(text_search)

