import '../../../../imports/imports.dart';
import '../../data/drug_history_repository.dart';

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
  List<String> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _history = DrugHistoryRepository.instance.getRecentSearches();
    });
  }

  Future<void> _deleteItem(int index) async {
    await DrugHistoryRepository.instance.removeSearchAt(index);
    if (!mounted) return;
    _load();
  }

  Future<void> _clearAll() async {
    await DrugHistoryRepository.instance.clearSearches();
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Scaffold(
      appBar: AppTopBar(
        title: 'drug_search_history.title'.tr(),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.drugInteraction),
            icon: const Icon(Icons.compare_arrows_rounded),
            tooltip: 'drug_interaction.title'.tr(),
          ),
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
      body: _history.isEmpty
          ? _EmptyState()
          : _HistoryList(
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
          // Sorguyu otomatik taşıyarak kullanıcının kaldığı yerden devam etmesini sağlar.
          onTap: () => context.push(AppRoutes.drugSearch, extra: query),
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
            Image.asset(
              'assets/images/search_empty.png',
              height: 160,
              fit: BoxFit.contain,
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
            AppButton(
              label: 'drug_search_history.go_search'.tr(),
              onPressed: () => context.push(AppRoutes.drugSearch),
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
