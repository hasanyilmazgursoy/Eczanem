import '../../../../imports/imports.dart';
import '../../data/family_repository.dart';
import '../../data/models/family_member.dart';

/// Belirli bir aile üyesinin ilaç listesini gösteren ve yönetim
/// işlemlerini başlatan detay ekranı.
class FamilyMemberDetailScreen extends StatefulWidget {
  const FamilyMemberDetailScreen({super.key, required this.member});

  final FamilyMember member;

  @override
  State<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen> {
  late FamilyMember _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _reload();
  }

  /// Hive'dan güncel veriyi çekip ekranı tazeler.
  void _reload() {
    final fresh = FamilyRepository.instance
        .getMembers()
        .where((m) => m.id == _member.id)
        .firstOrNull;
    if (fresh != null) setState(() => _member = fresh);
  }

  Future<void> _openAddDrugSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddDrugSheet(memberId: _member.id),
    );
    if (result ?? false) _reload();
  }

  Future<void> _removeDrug(FamilyMemberDrug drug) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('family.remove_drug_title'.tr()),
        content: Text(
          'family.remove_drug_message'.tr(args: [drug.drugName]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('family.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('family.delete'.tr(),
                style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FamilyRepository.instance.removeDrug(
      memberId: _member.id,
      drugId: drug.id,
    );
    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _reload();
        context.showTypedSnackBar(
          'family.drug_removed'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          _member.name,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: _MemberInfoCard(member: _member),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.medication_rounded, color: colorScheme.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'family.drugs_title'.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openAddDrugSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text('family.add_drug'.tr()),
                  ),
                ],
              ),
            ),
          ),
          if (_member.drugs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyDrugsState(onAdd: _openAddDrugSheet),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              sliver: SliverList.separated(
                itemCount: _member.drugs.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _DrugTile(
                  drug: _member.drugs[i],
                  onRemove: () => _removeDrug(_member.drugs[i]),
                  onSearch: () => context.push(
                    AppRoutes.drugSearch,
                    extra: _member.drugs[i].drugName,
                  ),
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl),
          ),
        ],
      ),
      floatingActionButton: _member.drugs.isNotEmpty
          ? FloatingActionButton(
              onPressed: _openAddDrugSheet,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Profil bilgi kartı
// ---------------------------------------------------------------------------

class _MemberInfoCard extends StatelessWidget {
  const _MemberInfoCard({required this.member});
  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.emoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (member.relationship.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      member.relationship,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                  if (member.age != null) ...[
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      'family.age_label'.tr(args: [member.age.toString()]),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// İlaç tile bileşeni
// ---------------------------------------------------------------------------

class _DrugTile extends StatelessWidget {
  const _DrugTile({
    required this.drug,
    required this.onRemove,
    required this.onSearch,
  });

  final FamilyMemberDrug drug;
  final VoidCallback onRemove;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.medication_rounded,
              color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          drug.drugName,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (drug.dosage.isNotEmpty)
              Text(drug.dosage,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            if (drug.frequency.isNotEmpty)
              Text(drug.frequency,
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'family.search_drug'.tr(),
              onPressed: onSearch,
            ),
            IconButton(
              icon:
                  Icon(Icons.delete_outline_rounded, color: colorScheme.error),
              tooltip: 'family.remove_drug_title'.tr(),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boş ilaç durumu
// ---------------------------------------------------------------------------

class _EmptyDrugsState extends StatelessWidget {
  const _EmptyDrugsState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 64,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'family.no_drugs_title'.tr(),
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'family.no_drugs_subtitle'.tr(),
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text('family.add_drug'.tr()),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// İlaç ekleme bottom sheet
// ---------------------------------------------------------------------------

class _AddDrugSheet extends StatefulWidget {
  const _AddDrugSheet({required this.memberId});
  final String memberId;

  @override
  State<_AddDrugSheet> createState() => _AddDrugSheetState();
}

class _AddDrugSheetState extends State<_AddDrugSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _freqCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _freqCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final result = await FamilyRepository.instance.addDrug(
      memberId: widget.memberId,
      drugName: _nameCtrl.text,
      dosage: _dosageCtrl.text,
      frequency: _freqCtrl.text,
      notes: _notesCtrl.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'family.add_drug'.tr(),
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'family.drug_name_label'.tr(),
                  prefixIcon: const Icon(Icons.medication_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'family.drug_name_required'.tr()
                    : null,
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _dosageCtrl,
                decoration: InputDecoration(
                  labelText: 'family.dosage_label'.tr(),
                  hintText: 'family.dosage_hint'.tr(),
                  prefixIcon: const Icon(Icons.straighten_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _freqCtrl,
                decoration: InputDecoration(
                  labelText: 'family.frequency_label'.tr(),
                  hintText: 'family.frequency_hint'.tr(),
                  prefixIcon: const Icon(Icons.repeat_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'family.notes_label'.tr(),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        'family.add_drug'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
