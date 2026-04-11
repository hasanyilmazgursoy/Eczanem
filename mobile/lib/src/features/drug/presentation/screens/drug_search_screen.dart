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
  bool _hasSearched = false;
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
    if (query.isEmpty) {
      setState(() {
        _hasSearched = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _isLoading = true;
      _error = null;
    });

    final result = await DrugRepository.instance.searchDrug(query);

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = _mapFailureToMessage(failure);
        _isLoading = false;
      }),
      (data) {
        _saveRecentSearch(query);
        setState(() => _isLoading = false);
        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'drug_search.network_error'.tr();
    }

    final message = failure.message.toLowerCase();

    if (message.contains('429') ||
        message.contains('çok fazla') ||
        message.contains('too many')) {
      return 'drug_search.rate_limit_error'.tr();
    }

    if (message.contains('timed out') || message.contains('timeout')) {
      return 'drug_search.timeout_error'.tr();
    }

    if (message.contains('unable to reach the server') ||
        message.contains('connection') ||
        message.contains('socketexception')) {
      return 'drug_search.network_error'.tr();
    }

    return 'drug_search.error'.tr();
  }

  void _searchRecent(String query) {
    _searchController.text = query;
    _searchDrug();
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
            Expanded(child: _buildBodyState()),
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
                  onPressed: () => _searchRecent(query),
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
      title: 'drug_search.error_title'.tr(),
      message: _error!,
      onRetry: _searchDrug,
      retryLabel: 'shared.try_again'.tr(),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Skeletonizer(
      child: ListView.builder(
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppCard(
            child: SizedBox(height: 80.h),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentQuery = _searchController.text.trim();
    final hasTypedQuery = currentQuery.isNotEmpty;
    final shouldSuggestRecent =
        !_hasSearched && !hasTypedQuery && _recentSearches.isNotEmpty;

    return AppEmptyState(
      icon: Icons.local_pharmacy_outlined,
      title: hasTypedQuery && currentQuery.length < 3
          ? 'drug_search.min_length_title'.tr()
          : 'drug_search.empty_hint'.tr(),
      subtitle: shouldSuggestRecent
          ? 'drug_search.empty_with_recent_subtitle'.tr()
          : hasTypedQuery && currentQuery.length < 3
              ? 'drug_search.min_length_subtitle'.tr()
              : 'drug_search.empty_subtitle'.tr(),
      actionLabel: shouldSuggestRecent ? 'drug_search.search_last'.tr() : null,
      onAction: shouldSuggestRecent
          ? () => _searchRecent(_recentSearches.first)
          : null,
    );
  }

  Widget _buildBodyState() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return _buildError();
    }

    return _buildEmptyState();
  }
}
