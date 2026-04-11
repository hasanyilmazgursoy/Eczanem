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

    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.candidates_title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(
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
      child: Row(
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
            child: Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              Icons.chevron_right,
              color: context.colors.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
