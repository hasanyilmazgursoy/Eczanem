import '../../../../imports/imports.dart';

/// Arama geçmişi ekranı.
///
/// `DrugSearchContent` tarafından Hive'a yazılan son aramaları listeler.
/// Her öğe silinebilir; "Tümünü Temizle" ile geçmiş toplu temizlenebilir.
/// Bir öğeye dokunmak ilaç arama ekranını açar.
class DrugSearchHistoryScreen extends StatefulWidget {
  const DrugSearchHistoryScreen({super.key});

  @override
  State<DrugSearchHistoryScreen> createState() =>
      _DrugSearchHistoryScreenState();
}

class _DrugSearchHistoryScreenState extends State<DrugSearchHistoryScreen> {
  // DrugSearchContent içindeki _recentSearchesKey ile eşleşmeli.
  static const _storageKey = 'drug_recent_searches';

  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final saved =
        StorageService.instance.getStringList(_storageKey) ?? const [];
    setState(() => _history = saved);
  }

  Future<void> _deleteItem(int index) async {
    final updated = List<String>.from(_history)..removeAt(index);
    await StorageService.instance.setStringList(_storageKey, updated);
    if (!mounted) return;
    setState(() => _history = updated);
  }

  Future<void> _clearAll() async {
    await StorageService.instance.remove(_storageKey);
    if (!mounted) return;
    setState(() => _history = const []);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Scaffold(
      appBar: AppTopBar(
        title: 'drug_search_history.title'.tr(),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: Text(
                'drug_search_history.clear_all'.tr(),
                style: TextStyle(color: colorScheme.error),
              ),
            ),
        ],
      ),
      body: _history.isEmpty ? _EmptyState() : _HistoryList(
        history: _history,
        onDeleteItem: _deleteItem,
      ),
    );
  }
}

// ── Geçmiş Listesi ──────────────────────────────────────────────────────────

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.history,
    required this.onDeleteItem,
  });

  final List<String> history;
  final void Function(int index) onDeleteItem;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return ListView.separated(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: history.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
      itemBuilder: (context, index) {
        final query = history[index];

        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            query,
            style: context.textTheme.bodyLarge,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: 'drug_search_history.delete_tooltip'.tr(),
            onPressed: () => onDeleteItem(index),
          ),
          // İlaca git: arama ekranı zaten son aramaları gösteriyor.
          onTap: () => context.push(AppRoutes.drugSearch),
        );
      },
    );
  }
}

// ── Boş Durum ────────────────────────────────────────────────────────────────

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
                Icons.history_rounded,
                size: 36,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'drug_search_history.empty_title'.tr(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'drug_search_history.empty_subtitle'.tr(),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.drugSearch),
              icon: const Icon(Icons.search_rounded),
              label: Text('drug_search_history.go_search'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
