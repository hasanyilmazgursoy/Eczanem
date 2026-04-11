import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

/// İlaç arama ekranı — ana sayfa yerine kullanılacak
class DrugSearchScreen extends ConsumerStatefulWidget {
  const DrugSearchScreen({super.key});

  @override
  ConsumerState<DrugSearchScreen> createState() => _DrugSearchScreenState();
}

class _DrugSearchScreenState extends ConsumerState<DrugSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
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
        setState(() => _isLoading = false);
        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.title'.tr()),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),
              _buildHeader(),
              SizedBox(height: AppSpacing.xl),
              _buildSearchField(),
              SizedBox(height: AppSpacing.md),
              _buildSearchButton(),
              SizedBox(height: AppSpacing.md),
              if (_error != null) _buildError(),
              if (_isLoading) _buildLoadingSkeleton(),
              if (!_isLoading && _error == null) _buildEmptyState(),
            ],
          ),
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
      suffixIcon: _searchController.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
          : null,
      onChanged: (_) => setState(() {}),
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
