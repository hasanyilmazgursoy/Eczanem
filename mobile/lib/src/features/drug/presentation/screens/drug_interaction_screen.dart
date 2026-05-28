import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../imports/imports.dart';
import '../../data/drug_history_repository.dart';
import '../../data/drug_repository.dart';

class DrugInteractionScreen extends StatefulWidget {
  const DrugInteractionScreen({super.key, this.initialDrugs = const []});

  final List<String> initialDrugs;

  @override
  State<DrugInteractionScreen> createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen> {
  final _drugController = TextEditingController();

  List<String> _selectedDrugs = const [];
  List<String> _suggestedDrugs = const [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    final initialDrugs = widget.initialDrugs
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    _selectedDrugs = initialDrugs;
    _suggestedDrugs = DrugHistoryRepository.instance.getSuggestedDrugNames();
  }

  @override
  void dispose() {
    _drugController.dispose();
    super.dispose();
  }

  void _addDrug([String? value]) {
    final rawValue = (value ?? _drugController.text).trim();
    if (rawValue.isEmpty) return;

    final alreadyExists = _selectedDrugs
        .any((item) => item.toLowerCase() == rawValue.toLowerCase());
    if (alreadyExists) {
      _drugController.clear();
      return;
    }

    setState(() {
      _selectedDrugs = [..._selectedDrugs, rawValue];
      _error = null;
    });
    _drugController.clear();
  }

  void _removeDrug(String drug) {
    setState(() {
      _selectedDrugs = _selectedDrugs.where((item) => item != drug).toList();
    });
  }

  Future<void> _analyzeInteractions() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedDrugs.length < 2) {
      setState(() {
        _error = 'drug_interaction.min_two_drugs'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result =
        await DrugRepository.instance.analyzeDrugInteraction(_selectedDrugs);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message.trim().isEmpty
              ? 'drug_interaction.generic_error'.tr()
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
    return Scaffold(
      appBar: AppTopBar(title: 'drug_interaction.title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          _HeroCard(selectedCount: _selectedDrugs.length),
          SizedBox(height: AppSpacing.lg),
          AppCard(
            showShadow: true,
            title: 'drug_interaction.selected_title'.tr(),
            subtitle: 'drug_interaction.selected_subtitle'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _drugController,
                  hint: 'drug_interaction.input_hint'.tr(),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: _addDrug,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _addDrug(),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                if (_selectedDrugs.isEmpty)
                  Text(
                    'drug_interaction.empty_selection'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _selectedDrugs
                        .map(
                          (drug) => InputChip(
                            label: Text(drug),
                            avatar:
                                const Icon(Icons.medication_outlined, size: 18),
                            onDeleted: () => _removeDrug(drug),
                          ),
                        )
                        .toList(),
                  ),
                SizedBox(height: AppSpacing.md),
                AppButton(
                  label: _isLoading
                      ? 'drug_interaction.analyzing'.tr()
                      : 'drug_interaction.analyze_button'.tr(),
                  onPressed: _isLoading ? null : _analyzeInteractions,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  prefixIcon: const Icon(Icons.compare_arrows_rounded),
                ),
                if (_error != null) ...[
                  SizedBox(height: AppSpacing.md),
                  AppErrorWidget(
                    title: 'drug_interaction.error_title'.tr(),
                    message: _error!,
                    onRetry: _analyzeInteractions,
                    retryLabel: 'shared.try_again'.tr(),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppCard(
            showShadow: true,
            title: 'drug_interaction.suggestions_title'.tr(),
            subtitle: 'drug_interaction.suggestions_subtitle'.tr(),
            child: _suggestedDrugs.isEmpty
                ? Text(
                    'drug_interaction.suggestions_empty'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _suggestedDrugs
                        .map(
                          (drug) => ActionChip(
                            label: Text(drug),
                            avatar: const Icon(Icons.history, size: 18),
                            onPressed: () => _addDrug(drug),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (_result != null) ...[
            SizedBox(height: AppSpacing.lg),
            _InteractionResultCard(
                result: _result!, selectedDrugs: _selectedDrugs),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5C6BC0),
            colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorders.card,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'drug_interaction.hero_title'.tr(),
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'drug_interaction.hero_subtitle'
                .tr(args: [selectedCount.toString()]),
            style: context.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractionResultCard extends StatelessWidget {
  const _InteractionResultCard({
    required this.result,
    required this.selectedDrugs,
  });

  final Map<String, dynamic> result;
  final List<String> selectedDrugs;

  @override
  Widget build(BuildContext context) {
    final riskLevel = (result['genel_risk_seviyesi'] ?? 'orta').toString();
    final riskColor = _resolveRiskColor(riskLevel);
    final interactions = (result['etkilesimler'] as List?) ?? const [];
    final precautions =
        (result['dikkat_edilmesi_gerekenler'] as List?) ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          showShadow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _riskLabel(riskLevel).tr(),
                      style: context.textTheme.labelLarge?.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selectedDrugs.join(' • '),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              MarkdownBody(
                data: result['ozet']?.toString() ??
                    'drug_interaction.no_summary'.tr(),
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(p: context.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
        if (precautions.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          _SectionCard(
            title: 'drug_interaction.precautions_title'.tr(),
            icon: Icons.health_and_safety_outlined,
            color: Colors.orange,
            items: precautions.map((item) => item.toString()).toList(),
          ),
        ],
        SizedBox(height: AppSpacing.md),
        if (interactions.isEmpty)
          AppCard(
            showShadow: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_outlined, color: Colors.green.shade600),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'drug_interaction.no_interaction_items'.tr(),
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...interactions.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: _InteractionItemCard(
                  item: Map<String, dynamic>.from(item as Map)),
            ),
          ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          color: context.colors.tertiaryContainer,
          child: Text(
            result['disclaimer']?.toString() ?? 'drug_detail.disclaimer'.tr(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onTertiaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Color _resolveRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'dusuk':
      case 'düşük':
      case 'low':
        return Colors.green.shade700;
      case 'yuksek':
      case 'yüksek':
      case 'high':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade700;
    }
  }

  String _riskLabel(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'dusuk':
      case 'düşük':
      case 'low':
        return 'drug_interaction.risk_low';
      case 'yuksek':
      case 'yüksek':
      case 'high':
        return 'drug_interaction.risk_high';
      default:
        return 'drug_interaction.risk_medium';
    }
  }
}

class _InteractionItemCard extends StatelessWidget {
  const _InteractionItemCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final risk = item['risk_seviyesi']?.toString() ?? 'orta';
    final color = switch (risk.toLowerCase()) {
      'dusuk' || 'düşük' || 'low' => Colors.green.shade700,
      'yuksek' || 'yüksek' || 'high' => Colors.red.shade700,
      _ => Colors.orange.shade700,
    };
    final drugs = ((item['ilaclar'] as List?) ?? const [])
        .map((drug) => drug.toString())
        .join(' + ');

    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            drugs,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          MarkdownBody(
            data: item['neden']?.toString() ?? '-',
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(p: context.textTheme.bodyMedium),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MarkdownBody(
              data: item['oneri']?.toString() ?? '-',
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: context.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          MarkdownBody(
            data: items.map((item) => '\u2022 $item').join('  \n'),
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(p: context.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
