import re

path = 'mobile/lib/src/features/drug/presentation/screens/drug_search_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace _buildSearchBar
huge_search_bar = '''  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
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
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.xxl,
                horizontal: AppSpacing.lg,
              ),
            ),
            onSubmitted: _submitSearch,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }'''

text = re.sub(r'  Widget _buildSearchBar\(\) \{.*?\n  \}(?=\n\n  Widget _buildContent)', huge_search_bar, text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
