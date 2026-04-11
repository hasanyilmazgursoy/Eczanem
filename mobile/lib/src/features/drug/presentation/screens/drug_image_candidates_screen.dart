import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

class DrugImageCandidatesScreen extends StatefulWidget {
  const DrugImageCandidatesScreen({
    super.key,
    required this.analysisData,
  });

  final Map<String, dynamic> analysisData;

  @override
  State<DrugImageCandidatesScreen> createState() =>
      _DrugImageCandidatesScreenState();
}

class _DrugImageCandidatesScreenState extends State<DrugImageCandidatesScreen> {
  String? _loadingCandidate;

  Future<void> _openDrugDetail(String drugName) async {
    setState(() => _loadingCandidate = drugName);

    final result = await DrugRepository.instance.searchDrug(drugName);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _loadingCandidate = null);
        context.showTypedSnackBar(
          _mapFailureToMessage(failure),
          type: SnackBarType.error,
        );
      },
      (data) {
        setState(() => _loadingCandidate = null);
        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    final message = failure.message.toLowerCase();

    if (failure is NetworkFailure ||
        message.contains('connection') ||
        message.contains('socketexception')) {
      return 'drug_search.network_error'.tr();
    }

    if (message.contains('timed out') || message.contains('timeout')) {
      return 'drug_search.timeout_error'.tr();
    }

    return 'drug_search.image_analysis_error'.tr();
  }

  List<String> _buildAlternatives() {
    final primary = (widget.analysisData['ilac_adi'] ?? '').toString().trim();
    final rawCandidates = widget.analysisData['aday_ilaclar'];

    final alternatives = <String>{};
    if (rawCandidates is List) {
      for (final candidate in rawCandidates) {
        final candidateName = candidate.toString().trim();
        if (candidateName.isNotEmpty && candidateName != primary) {
          alternatives.add(candidateName);
        }
      }
    }

    return alternatives.toList();
  }

  @override
  Widget build(BuildContext context) {
    final primaryName =
        (widget.analysisData['ilac_adi'] ?? '').toString().trim();
    final alternatives = _buildAlternatives();
    final colorScheme = context.colors;

    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.candidates_title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primaryContainer,
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
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.medication_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'drug_search.candidates_best_guess'.tr(),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            primaryName,
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'drug_search.candidates_subtitle'.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.92),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _CandidateInfoPill(
                      icon: Icons.tips_and_updates_outlined,
                      label: 'drug_search.candidates_tip_primary'.tr(),
                    ),
                    if (alternatives.isNotEmpty)
                      _CandidateInfoPill(
                        icon: Icons.format_list_bulleted_rounded,
                        label: 'drug_search.candidates_tip_alternatives'
                            .tr(args: [alternatives.length.toString()]),
                      ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          AppCard(
            showShadow: true,
            color: context.colors.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'drug_search.candidates_best_guess'.tr(),
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  primaryName,
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: context.colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'drug_search.candidates_subtitle'.tr(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                AppButton(
                  label: _loadingCandidate == primaryName
                      ? 'drug_search.candidate_loading'.tr()
                      : 'drug_search.candidate_open_primary'.tr(),
                  onPressed: _loadingCandidate == null
                      ? () => _openDrugDetail(primaryName)
                      : null,
                  isLoading: _loadingCandidate == primaryName,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          if (alternatives.isNotEmpty)
            AppCard(
              showShadow: true,
              title: 'drug_search.candidate_alternatives_title'.tr(),
              subtitle: 'drug_search.candidate_alternatives_subtitle'.tr(),
              child: Column(
                children: [
                  for (final candidate in alternatives) ...[
                    _CandidateTile(
                      title: candidate,
                      isLoading: _loadingCandidate == candidate,
                      onTap: _loadingCandidate == null
                          ? () => _openDrugDetail(candidate)
                          : null,
                    ),
                    if (candidate != alternatives.last)
                      SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.title,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.medication_outlined,
              color: context.colors.onSecondaryContainer,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'drug_search.candidate_tile_subtitle'.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right,
                    color: context.colors.onSurfaceVariant,
                    size: 18,
                  ),
          ),
        ],
      ),
    );
  }
}

class _CandidateInfoPill extends StatelessWidget {
  const _CandidateInfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
