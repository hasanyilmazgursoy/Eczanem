import '../../../../imports/imports.dart';
import '../../data/drug_history_repository.dart';

/// Fotoğrafla analiz edilen ilaç ve prospektüs sonuçlarını listeler.
class DrugScanHistoryScreen extends StatefulWidget {
  const DrugScanHistoryScreen({super.key});

  @override
  State<DrugScanHistoryScreen> createState() => _DrugScanHistoryScreenState();
}

class _DrugScanHistoryScreenState extends State<DrugScanHistoryScreen> {
  List<DrugScanHistoryEntry> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _history = DrugHistoryRepository.instance.getRecentScans();
    });
  }

  Future<void> _deleteItem(int index) async {
    await DrugHistoryRepository.instance.removeScanAt(index);
    if (!mounted) return;
    _load();
  }

  Future<void> _clearAll() async {
    await DrugHistoryRepository.instance.clearScans();
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Scaffold(
      appBar: AppTopBar(
        title: 'drug_scan_history.title'.tr(),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'drug_scan_history.clear_all'.tr(),
                style: TextStyle(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: _history.isEmpty
          ? _EmptyState()
          : _HistoryList(history: _history, onDeleteItem: _deleteItem),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.history,
    required this.onDeleteItem,
  });

  final List<DrugScanHistoryEntry> history;
  final void Function(int index) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final entry = history[index];
        final colorScheme = context.colors;
        final dateLabel = _formatEntryDate(context, entry.createdAt);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.mode == DrugScanHistoryMode.prospectus
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.7)
                  : colorScheme.primaryContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              entry.mode == DrugScanHistoryMode.prospectus
                  ? Icons.description_outlined
                  : Icons.document_scanner_outlined,
              color: entry.mode == DrugScanHistoryMode.prospectus
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.primary,
            ),
          ),
          title: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xxs),
              Text(
                entry.subtitle.isEmpty
                    ? entry.mode == DrugScanHistoryMode.prospectus
                        ? 'drug_scan_history.prospectus_fallback'.tr()
                        : 'drug_scan_history.medicine_fallback'.tr()
                    : entry.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xxs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ModeBadge(entry: entry),
                  Text(
                    dateLabel,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'drug_scan_history.delete_tooltip'.tr(),
            onPressed: () => onDeleteItem(index),
          ),
          onTap: () => _openEntry(context, entry),
        );
      },
    );
  }

  String _formatEntryDate(BuildContext context, DateTime createdAt) {
    final localizations = MaterialLocalizations.of(context);
    final localDate = createdAt.toLocal();
    final timeOfDay = TimeOfDay.fromDateTime(localDate);
    return '${localizations.formatShortDate(localDate)} · ${localizations.formatTimeOfDay(timeOfDay)}';
  }

  void _openEntry(BuildContext context, DrugScanHistoryEntry entry) {
    if (entry.mode == DrugScanHistoryMode.prospectus) {
      context.push(AppRoutes.drugProspectusSummary, extra: entry.payload);
      return;
    }

    if (entry.hasCandidates) {
      context.push(AppRoutes.drugImageCandidates, extra: entry.payload);
      return;
    }

    context.push(AppRoutes.drugDetail, extra: entry.payload);
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.entry});

  final DrugScanHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final isProspectus = entry.mode == DrugScanHistoryMode.prospectus;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isProspectus
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isProspectus
            ? 'drug_scan_history.mode_prospectus'.tr()
            : 'drug_scan_history.mode_medicine'.tr(),
        style: context.textTheme.labelSmall?.copyWith(
          color: isProspectus
              ? colorScheme.onSecondaryContainer
              : colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 36,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'drug_scan_history.empty_title'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'drug_scan_history.empty_subtitle'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.drugPhotoScan),
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text('drug_scan_history.go_scan'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
