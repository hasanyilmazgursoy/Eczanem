import 'dart:io';

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
  bool _isImageLoading = false;
  bool _hasSearched = false;
  String? _error;
  String? _imageError;
  File? _selectedImage;
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

  String _mapImageFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'drug_search.network_error'.tr();
    }

    final message = failure.message.toLowerCase();

    if (message.contains('camera permission denied') ||
        message.contains('photos permission denied') ||
        message.contains('permission denied')) {
      return 'drug_search.image_permission_error'.tr();
    }

    if (message.contains('yalnızca görsel') || message.contains('image/')) {
      return 'drug_search.image_invalid_error'.tr();
    }

    if (message.contains('boş olamaz') || message.contains('empty')) {
      return 'drug_search.image_empty_error'.tr();
    }

    if (message.contains('timed out') || message.contains('timeout')) {
      return 'drug_search.timeout_error'.tr();
    }

    if (message.contains('unable to reach the server') ||
        message.contains('connection') ||
        message.contains('socketexception')) {
      return 'drug_search.network_error'.tr();
    }

    if (failure.message.trim().isEmpty ||
        failure.message == 'An unexpected error occurred') {
      return 'drug_search.image_analysis_error'.tr();
    }

    return failure.message;
  }

  Future<void> _pickImage(ImageSource source) async {
    final result = await MediaService.instance.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        final message = _mapImageFailureToMessage(failure);
        setState(() => _imageError = message);
        context.showTypedSnackBar(message, type: SnackBarType.error);
      },
      (file) {
        if (file == null) {
          context.showTypedSnackBar(
            'drug_search.image_pick_cancelled'.tr(),
          );
          return;
        }

        setState(() {
          _selectedImage = file;
          _imageError = null;
        });
        context.showTypedSnackBar(
          'drug_search.image_ready'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  Future<void> _analyzeSelectedImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) {
      final message = 'drug_search.image_select_first'.tr();
      setState(() => _imageError = message);
      context.showTypedSnackBar(message, type: SnackBarType.warning);
      return;
    }

    setState(() {
      _isImageLoading = true;
      _imageError = null;
    });

    final result =
        await DrugRepository.instance.analyzeDrugImage(selectedImage);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _imageError = _mapImageFailureToMessage(failure);
          _isImageLoading = false;
        });
      },
      (data) {
        setState(() => _isImageLoading = false);
        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
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
            _buildImageAnalysisCard(),
            SizedBox(height: AppSpacing.md),
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

  Widget _buildImageAnalysisCard() {
    final hasSelection = _selectedImage != null;

    return AppCard(
      title: 'drug_search.image_card_title'.tr(),
      subtitle: 'drug_search.image_card_subtitle'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSelection)
            _buildSelectedImagePreview()
          else
            _buildImageEmptyState(),
          if (_imageError != null) ...[
            SizedBox(height: AppSpacing.md),
            _buildImageErrorBanner(),
          ],
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'drug_search.take_photo'.tr(),
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  variant: ButtonVariant.outline,
                  prefixIcon: const Icon(Icons.photo_camera_outlined),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: 'drug_search.pick_from_gallery'.tr(),
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  variant: ButtonVariant.secondary,
                  prefixIcon: const Icon(Icons.photo_library_outlined),
                ),
              ),
            ],
          ),
          if (hasSelection) ...[
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: _isImageLoading
                  ? 'drug_search.analyzing_image'.tr()
                  : 'drug_search.analyze_image'.tr(),
              onPressed: _isImageLoading ? null : _analyzeSelectedImage,
              isLoading: _isImageLoading,
              isFullWidth: true,
              prefixIcon: const Icon(Icons.auto_awesome_outlined),
            ),
            SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'drug_search.clear_selected_image'.tr(),
              onPressed: _isImageLoading ? null : _clearSelectedImage,
              variant: ButtonVariant.ghost,
              isFullWidth: true,
              prefixIcon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppBorders.card,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 40,
            color: context.colors.primary,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'drug_search.image_empty_title'.tr(),
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'drug_search.image_empty_subtitle'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    final selectedImage = _selectedImage;
    if (selectedImage == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'drug_search.image_preview_title'.tr(),
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppBorders.card,
          child: Image.file(
            selectedImage,
            height: 200.h,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildImageErrorBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: AppBorders.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color: context.colors.onErrorContainer,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _imageError!,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
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
