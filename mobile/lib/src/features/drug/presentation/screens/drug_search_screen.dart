import 'package:speech_to_text/speech_to_text.dart';

import '../../../../imports/imports.dart';
import '../../data/drug_history_repository.dart';
import '../../data/drug_repository.dart';

class DrugSearchScreen extends StatelessWidget {
  const DrugSearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.text_search_page_title'.tr()),
      body: DrugSearchContent(initialQuery: initialQuery),
    );
  }
}

class DrugSearchContent extends ConsumerStatefulWidget {
  final bool showHeader;
  final String? initialQuery;

  const DrugSearchContent({
    super.key,
    this.showHeader = true,
    this.initialQuery,
  });

  @override
  ConsumerState<DrugSearchContent> createState() => _DrugSearchContentState();
}

class _DrugSearchContentState extends ConsumerState<DrugSearchContent> {
  final _searchController = TextEditingController();
  // FocusNode state'de tutulmazsa her build'de yenisi yaratılır;
  // bu uzun basma (long-press backspace) bozulmasına yol açar.
  final _focusNode = FocusNode();
  final _debouncer = Debouncer();
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  List<String> _recentSearches = const [];

  // Sesli arama
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialQuery?.trim();
    if (initialQuery != null && initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchDrug();
      });
    }
    _loadRecentSearches();
    _initSpeech();
  }

  Future<void> _loadRecentSearches() async {
    final recentSearches = DrugHistoryRepository.instance.getRecentSearches();
    if (!mounted) return;
    setState(() => _recentSearches = recentSearches);
  }

  /// speech_to_text başlatılır; kullanılamazsa _speechAvailable false kalır.
  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (!mounted) return;
        // Dinleme bitince (done / notListening) aramayı otomatik başlat.
        if (status == 'done' || status == 'notListening') {
          final hadText = _searchController.text.trim().isNotEmpty;
          setState(() => _isListening = false);
          if (hadText) _searchDrug();
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  /// Mikrofon butonuna basıldığında: dinliyorsa durdur, değilse başlat.
  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    if (!_speechAvailable) {
      context.showTypedSnackBar(
        'drug_search.voice_unavailable'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isListening = true;
      _searchController.clear();
      _hasSearched = false;
      _error = null;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _searchController.text = result.recognizedWords);
      },
      localeId: 'tr_TR',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> _saveRecentSearch(String query) async {
    await DrugHistoryRepository.instance.saveRecentSearch(query);
    if (!mounted) return;
    setState(() {
      _recentSearches = DrugHistoryRepository.instance.getRecentSearches();
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _searchDrug() async {
    FocusManager.instance.primaryFocus?.unfocus();
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
        message.contains('Ã\u00a7ok fazla') ||
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

  Future<void> _clearRecentSearches() async {
    await DrugHistoryRepository.instance.clearSearches();
    if (!mounted) return;
    setState(() => _recentSearches = const []);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          widget.showHeader ? AppSpacing.xl + AppSpacing.lg : AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: [
          if (widget.showHeader) ...[
            _buildHeader(),
            SizedBox(height: AppSpacing.xl),
          ],
          _buildSearchField(),
          SizedBox(height: AppSpacing.md),
          _buildSearchButton(),
          SizedBox(height: AppSpacing.xl),
          if (_recentSearches.isNotEmpty) ...[
            _buildRecentSearches(),
            SizedBox(height: AppSpacing.md),
          ],
          SizedBox(height: AppSpacing.md),
          _buildBodyState(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const SizedBox.shrink();
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        style: context.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        decoration: InputDecoration(
          hintText: _isListening
              ? 'drug_search.voice_listening'.tr()
              : 'drug_search.search_hint'.tr(),
          hintStyle: context.textTheme.headlineMedium?.copyWith(
            color: context.colors.onSurface.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Icon(
              Icons.search_rounded,
              size: 40,
              color: context.colors.primary,
            ),
          ),
          suffixIcon: _isListening
              ? IconButton(
                  icon: Icon(
                    Icons.stop_circle_outlined,
                    size: 30,
                    color: context.colors.error,
                  ),
                  tooltip: 'drug_search.voice_stop'.tr(),
                  onPressed: _toggleVoiceSearch,
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 30),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : _speechAvailable
                      ? IconButton(
                          icon: Icon(
                            Icons.mic_rounded,
                            size: 30,
                            color: context.colors.primary,
                          ),
                          tooltip: 'drug_search.voice_search'.tr(),
                          onPressed: _toggleVoiceSearch,
                        )
                      : null,
          filled: true,
          fillColor:
              context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
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
        },
        onSubmitted: (_) => _searchDrug(),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'drug_search.recent_title'.tr(),
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text('drug_search.clear_recent'.tr()),
            ),
          ],
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

  Widget _buildBodyHintCard({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 40, color: context.colors.primary),
          SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: actionLabel,
              onPressed: onAction,
              variant: ButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyState() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    final currentQuery = _searchController.text.trim();
    final hasTypedQuery = currentQuery.isNotEmpty;

    // Metin yazılmış ama henüz arama yapılmamış → kutu gösterme
    if (hasTypedQuery && !_hasSearched) return const SizedBox.shrink();

    final shouldSuggestRecent =
        !_hasSearched && !hasTypedQuery && _recentSearches.isNotEmpty;

    return _buildBodyHintCard(
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
}
