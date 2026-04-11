import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

class DrugSearchScreen extends StatelessWidget {
  const DrugSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.title'.tr()),
      body: const DrugSearchContent(),
    );
  }
}

class DrugSearchContent extends ConsumerStatefulWidget {
  final bool showHeader;

  const DrugSearchContent({super.key, this.showHeader = true});

  @override
  ConsumerState<DrugSearchContent> createState() => _DrugSearchContentState();
}

class _DrugSearchContentState extends ConsumerState<DrugSearchContent> {
  static const _recentSearchesKey = 'drug_recent_searches';
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  bool _isLoading = false;
  String? _error;
  List<String> _recentSearches = const [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final recentSearches =
        StorageService.instance.getStringList(_recentSearchesKey) ?? const [];
    if (!mounted) return;
    setState(() => _recentSearches = recentSearches);
  }

  Future<void> _saveRecentSearch(String query) async {
    final updated = [
      query,
      ..._recentSearches
          .where((item) => item.toLowerCase() != query.toLowerCase()),
    ].take(8).toList();

    await StorageService.instance.setStringList(_recentSearchesKey, updated);
    if (!mounted) return;
    setState(() => _recentSearches = updated);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchDrug() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await DrugRepository.instance.searchDrug(query);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = 'drug_search.error'.tr();
        _isLoading = false;
      }),
      (data) {
        _saveRecentSearch(query);
        setState(() => _isLoading = false);
        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              SizedBox(height: AppSpacing.lg),
              _buildHeader(),
              SizedBox(height: AppSpacing.xl),
            ],
            _buildSearchField(),
            SizedBox(height: AppSpacing.md),
            if (_recentSearches.isNotEmpty) ...[
              _buildRecentSearches(),
              SizedBox(height: AppSpacing.md),
            ],
            _buildSearchButton(),
            SizedBox(height: AppSpacing.md),
            if (_error != null) _buildError(),
            if (_isLoading) _buildLoadingSkeleton(),
            if (!_isLoading && _error == null) _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💊 Eczanem',
          style: context.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'home.home_subtitle'.tr(),
          style: context.textTheme.bodyLarge?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return AppTextField(
      controller: _searchController,
      hint: 'drug_search.search_hint'.tr(),
      prefixIcon: const Icon(Icons.search),
      textInputAction: TextInputAction.search,
      onFieldSubmitted: (_) => _searchDrug(),
      onChanged: (value) {
        setState(() {});
        if (value.trim().length < 3) return;
        // FAZ 1: kullanıcı yazmayı bitirince aramayı hızlı başlat.
        _debouncer.run(_searchDrug);
      },
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
          : null,
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'drug_search.recent_title'.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _recentSearches
              .map(
                (query) => ActionChip(
                  label: Text(query),
                  avatar: const Icon(Icons.history, size: 18),
                  onPressed: () {
                    _searchController.text = query;
                    _searchDrug();
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return AppButton(
      label: _isLoading
          ? 'drug_search.searching'.tr()
          : 'drug_search.search_button'.tr(),
      onPressed: _isLoading ? null : _searchDrug,
      isLoading: _isLoading,
      isFullWidth: true,
      prefixIcon: const Icon(Icons.medication_outlined),
    );
  }

  Widget _buildError() {
    return AppErrorWidget(
      message: _error!,
      onRetry: _searchDrug,
    );
  }

  Widget _buildLoadingSkeleton() {
    return Expanded(
      child: Skeletonizer(
        child: ListView.builder(
          itemCount: 4,
          itemBuilder: (_, __) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: AppCard(
              child: SizedBox(height: 80.h),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: AppEmptyState(
        icon: Icons.local_pharmacy_outlined,
        title: 'drug_search.empty_hint'.tr(),
      ),
    );
  }
}
