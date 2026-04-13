import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

class DrugNaturalAlternativesScreen extends StatefulWidget {
  const DrugNaturalAlternativesScreen({
    super.key,
    this.initialDrugName,
  });

  final String? initialDrugName;

  @override
  State<DrugNaturalAlternativesScreen> createState() =>
      _DrugNaturalAlternativesScreenState();
}

class _DrugNaturalAlternativesScreenState
    extends State<DrugNaturalAlternativesScreen> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDrugName ?? '');
    if ((widget.initialDrugName ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadAlternatives();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadAlternatives() async {
    final drugName = _controller.text.trim();
    if (drugName.isEmpty) {
      setState(() {
        _error = 'drug_natural_alternatives.empty_error'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await DrugRepository.instance.getNaturalAlternatives(drugName);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message.trim().isEmpty
              ? 'drug_natural_alternatives.generic_error'.tr()
              : failure.message;
        });
      },
      (data) {
        setState(() {
          _isLoading = false;
          _result = data;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alternatives = (_result?['alternatifler'] as List?) ?? const [];

    return Scaffold(
      appBar: AppTopBar(title: 'drug_natural_alternatives.title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
            showShadow: true,
            title: 'drug_natural_alternatives.input_title'.tr(),
            subtitle: 'drug_natural_alternatives.input_subtitle'.tr(),
            child: Column(
              children: [
                AppTextField(
                  controller: _controller,
                  hint: 'drug_natural_alternatives.input_hint'.tr(),
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (_) => _loadAlternatives(),
                ),
                SizedBox(height: AppSpacing.md),
                AppButton(
                  label: _isLoading
                      ? 'drug_natural_alternatives.loading'.tr()
                      : 'drug_natural_alternatives.button'.tr(),
                  onPressed: _isLoading ? null : _loadAlternatives,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  prefixIcon: const Icon(Icons.eco_outlined),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            SizedBox(height: AppSpacing.lg),
            AppErrorWidget(
              title: 'drug_natural_alternatives.error_title'.tr(),
              message: _error!,
              onRetry: _loadAlternatives,
              retryLabel: 'shared.try_again'.tr(),
            ),
          ],
          if (_result != null) ...[
            SizedBox(height: AppSpacing.lg),
            AppCard(
              showShadow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_result?['ilac_adi'] ?? '-').toString(),
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    (_result?['hedef'] ?? '-').toString(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),
            if (alternatives.isEmpty)
              AppCard(
                showShadow: true,
                child: Text('drug_natural_alternatives.empty_result'.tr()),
              )
            else
              ...alternatives.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AlternativeCard(
                    item: Map<String, dynamic>.from(item as Map),
                  ),
                ),
              ),
            AppCard(
              color: context.colors.tertiaryContainer,
              child: Text(
                (_result?['uyari'] ?? 'drug_detail.disclaimer'.tr()).toString(),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.eco_outlined, color: Colors.green),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['ad']?.toString() ?? '-',
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      item['tur']?.toString() ?? '-',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(item['aciklama']?.toString() ?? '-'),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item['dikkat']?.toString() ?? '-',
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
