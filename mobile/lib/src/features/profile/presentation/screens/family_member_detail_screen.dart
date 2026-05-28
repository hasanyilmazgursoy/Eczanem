import '../../../../imports/imports.dart';
import '../../../drug/data/drug_repository.dart';
import '../../data/family_repository.dart';
import '../../data/models/family_member.dart';
import 'family_screen.dart';

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

  Future<void> _openEditSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => FamilyMemberEditorSheet(existing: _member),
    );
    if (result ?? false) _reload();
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

  /// ≥2 ilaç varsa AI etkileşim analizini bottom sheet olarak gösterir.
  Future<void> _checkInteractions() async {
    if (_member.drugs.length < 2) return;
    final drugNames = _member.drugs.map((d) => d.drugName).toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _InteractionCheckSheet(drugNames: drugNames),
    );
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
        actions: [
          IconButton(
            onPressed: _openEditSheet,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'family.edit'.tr(),
          ),
          SizedBox(width: AppSpacing.xs),
        ],
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
                  // Etkileşim kontrolü butonu — en az 2 ilaç varsa göster
                  if (_member.drugs.length >= 2)
                    IconButton(
                      icon: const Icon(Icons.smart_toy_rounded),
                      color: const Color(0xFF6750A4),
                      tooltip: 'family.check_interactions'.tr(),
                      onPressed: _checkInteractions,
                    ),
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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // İlaç ikonu
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medication_rounded,
                  color: colorScheme.onPrimaryContainer),
            ),
            SizedBox(width: AppSpacing.md),
            // İsim + chip'ler
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.drugName,
                    style:
                        textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (drug.dosage.isNotEmpty || drug.frequency.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (drug.dosage.isNotEmpty)
                          _DrugInfoChip(
                            icon: Icons.straighten_rounded,
                            label: drug.dosage,
                          ),
                        if (drug.frequency.isNotEmpty)
                          _DrugInfoChip(
                            icon: Icons.repeat_rounded,
                            label: drug.frequency,
                          ),
                      ],
                    ),
                  ],
                  if (drug.notes.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      drug.notes,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Aksiyon butonları
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'family.search_drug'.tr(),
                  onPressed: onSearch,
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error),
                  tooltip: 'family.remove_drug_title'.tr(),
                  onPressed: onRemove,
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );  
  }
}

/// Doz ve sıklık gibi ilaç bilgilerini gösteren küçük etiket chip'i.
class _DrugInfoChip extends StatelessWidget {
  const _DrugInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
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
            AppButton(
              label: 'family.add_drug'.tr(),
              onPressed: onAdd,
              isFullWidth: true,
              variant: ButtonVariant.outline,
              prefixIcon: const Icon(Icons.add_rounded),
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
              AppButton(
                label: 'family.add_drug'.tr(),
                onPressed: _saving ? null : _save,
                isFullWidth: true,
                isLoading: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Etkileşim Kontrolü bottom sheet
// ---------------------------------------------------------------------------

/// Aile üyesinin ilaçlarını Gemini AI'a göndererek etkileşim analizi yapar.
/// risk_seviyesi değerine göre kırmızı / sarı / yeşil renk kodu gösterir.
class _InteractionCheckSheet extends StatefulWidget {
  const _InteractionCheckSheet({required this.drugNames});
  final List<String> drugNames;

  @override
  State<_InteractionCheckSheet> createState() => _InteractionCheckSheetState();
}

class _InteractionCheckSheetState extends State<_InteractionCheckSheet> {
  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final result =
        await DrugRepository.instance.analyzeDrugInteraction(widget.drugNames);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _errorMessage = failure.message;
      }),
      (data) => setState(() {
        _loading = false;
        _result = data;
      }),
    );
  }

  /// risk_seviyesi metnine göre renk döndürür (yüksek=kırmızı, orta=turuncu, düşük=yeşil).
  Color _riskColor(String? risk) {
    final r = risk?.toLowerCase() ?? '';
    if (r.contains('yüksek') || r.contains('high') || r.contains('ciddi')) {
      return const Color(0xFFD32F2F);
    } else if (r.contains('orta') ||
        r.contains('moderate') ||
        r.contains('medium')) {
      return const Color(0xFFF57C00);
    }
    return const Color(0xFF388E3C);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sürükleme çubuğu
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Başlık satırı
            Row(
              children: [
                const Icon(Icons.smart_toy_rounded,
                    color: Color(0xFF6750A4), size: 24),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'family.interaction_title'.tr(),
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            // Analiz edilen ilaç adları
            Text(
              widget.drugNames.join(' · '),
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: AppSpacing.md),
                          Text('family.interaction_loading'.tr()),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _buildResult(scrollCtrl, textTheme, colorScheme),
            ),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(
    ScrollController scrollCtrl,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    if (_result == null) return const SizedBox.shrink();

    final risk = _result!['risk_seviyesi']?.toString() ??
        _result!['risk_level']?.toString() ??
        '';
    final riskColor = _riskColor(risk);
    final summary =
        _result!['ozet']?.toString() ?? _result!['summary']?.toString() ?? '';
    final interactions = _result!['etkilesimler'] as List<dynamic>? ??
        _result!['interactions'] as List<dynamic>? ??
        [];
    final recommendations = _result!['tavsiyeler'] as List<dynamic>? ??
        _result!['recommendations'] as List<dynamic>? ??
        [];

    return ListView(
      controller: scrollCtrl,
      children: [
        // Risk seviyesi kartı
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: riskColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: riskColor, size: 28),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'family.risk_level'.tr(),
                      style: textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    Text(
                      risk,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (summary.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            'family.interaction_summary'.tr(),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(summary, style: textTheme.bodyMedium),
        ],
        if (interactions.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            'family.interactions_title'.tr(),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.xs),
          ...interactions.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item.toString())),
                ],
              ),
            ),
          ),
        ],
        if (recommendations.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md),
          Text(
            'family.recommendations_title'.tr(),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: AppSpacing.xs),
          ...recommendations.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item.toString())),
                ],
              ),
            ),
          ),
        ],
        SizedBox(height: AppSpacing.md),
        // Sorumluluk reddi
        Text(
          'family.interaction_disclaimer'.tr(),
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
