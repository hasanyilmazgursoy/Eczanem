import '../../../../imports/imports.dart';
import '../../data/family_repository.dart';
import '../../data/models/family_member.dart';

/// Aile üyelerini listeleyen ve yönetim işlemlerini başlatan ana ekran.
class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  List<FamilyMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _members = FamilyRepository.instance.getMembers();
    });
  }

  Future<void> _openAddMemberSheet({FamilyMember? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FamilyMemberEditorSheet(existing: existing),
    );
    if (result ?? false) _load();
  }

  Future<void> _deleteMember(FamilyMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('family.delete_confirm_title'.tr()),
        content: Text(
          'family.delete_confirm_message'.tr(args: [member.name]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('family.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'family.delete'.tr(),
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FamilyRepository.instance.removeMember(member.id);
    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _load();
        context.showTypedSnackBar(
          'family.deleted_success'.tr(),
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
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        title: Text(
          'family.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openAddMemberSheet,
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'family.add_member'.tr(),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _members.isEmpty
          ? _EmptyState(onAdd: _openAddMemberSheet)
          : _MemberGrid(
              members: _members,
              onTap: (member) => context.push(
                AppRoutes.familyMemberDetail,
                extra: member,
              ),
              onEdit: (member) => _openAddMemberSheet(existing: member),
              onDelete: _deleteMember,
            ),
      floatingActionButton: _members.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddMemberSheet,
              icon: const Icon(Icons.person_add_rounded),
              label: Text('family.add_member'.tr()),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Üye Grid bileşeni
// ---------------------------------------------------------------------------

class _MemberGrid extends StatelessWidget {
  const _MemberGrid({
    required this.members,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FamilyMember> members;
  final void Function(FamilyMember) onTap;
  final void Function(FamilyMember) onEdit;
  final void Function(FamilyMember) onDelete;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        // 0.9 → 0.85: kart içeriği küçük ekranlarda ~1 px taşıyordu
        childAspectRatio: 0.78,
      ),
      itemCount: members.length,
      itemBuilder: (context, i) => _MemberCard(
        member: members[i],
        onTap: () => onTap(members[i]),
        onEdit: () => onEdit(members[i]),
        onDelete: () => onDelete(members[i]),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final FamilyMember member;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        member.emoji,
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.edit_rounded),
                          title: Text('family.edit'.tr()),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_rounded,
                              color: colorScheme.error),
                          title: Text('family.delete'.tr(),
                              style: TextStyle(color: colorScheme.error)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                member.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.relationship.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  member.relationship,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (member.age != null) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'family.age_label'.tr(args: [member.age.toString()]),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.xs),
              if (member.drugs.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'family.drug_count'.tr(
                      args: [member.drugs.length.toString()],
                    ),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boş durum bileşeni
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
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
              Icons.family_restroom_rounded,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'family.empty_title'.tr(),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'family.empty_subtitle'.tr(),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'family.add_member'.tr(),
              onPressed: onAdd,
              isFullWidth: true,
              prefixIcon: const Icon(Icons.person_add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Üye ekleme / düzenleme bottom sheet
// ---------------------------------------------------------------------------

class FamilyMemberEditorSheet extends StatefulWidget {
  const FamilyMemberEditorSheet({super.key, this.existing});
  final FamilyMember? existing;

  @override
  State<FamilyMemberEditorSheet> createState() =>
      _FamilyMemberEditorSheetState();
}

class _FamilyMemberEditorSheetState extends State<FamilyMemberEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _relationshipCtrl;
  late final TextEditingController _ageCtrl;
  String _emoji = '\u{1F464}';
  bool _saving = false;

  static const _emojiOptions = [
    '\u{1F464}',
    '\u{1F468}',
    '\u{1F469}',
    '\u{1F466}',
    '\u{1F467}',
    '\u{1F474}',
    '\u{1F475}',
    '\u{1F9D1}',
    '\u{1F476}',
    '\u{1F9D2}',
    '\u{1F9D3}',
    '\u{1F9D1}\u200D\u{1F9B3}',
    '\u{1F9D1}\u200D\u{1F9B1}',
    '\u{1F9D1}\u200D\u{1F9B2}',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _relationshipCtrl = TextEditingController(text: m?.relationship ?? '');
    _ageCtrl = TextEditingController(
      text: m?.age != null ? m!.age.toString() : '',
    );
    _emoji = m?.emoji ?? '\u{1F464}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationshipCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final age = int.tryParse(_ageCtrl.text.trim());
    final repo = FamilyRepository.instance;

    late Either<Failure, dynamic> result;

    if (widget.existing == null) {
      result = await repo.addMember(
        name: _nameCtrl.text,
        relationship: _relationshipCtrl.text,
        emoji: _emoji,
        age: age,
      );
    } else {
      result = await repo.updateMember(
        widget.existing!.copyWith(
          name: _nameCtrl.text.trim(),
          relationship: _relationshipCtrl.text.trim(),
          emoji: _emoji,
          age: age,
        ),
      );
    }

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
    final colorScheme = context.colors;
    final textTheme = context.textTheme;
    final isEditing = widget.existing != null;

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
                isEditing
                    ? 'family.edit_member'.tr()
                    : 'family.add_member'.tr(),
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: AppSpacing.lg),
              // Emoji seçici
              Text('family.emoji_label'.tr(), style: textTheme.labelLarge),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _emojiOptions.map((e) {
                  final selected = _emoji == e;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'family.name_label'.tr(),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'family.name_required'.tr()
                    : null,
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _relationshipCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'family.relationship_label'.tr(),
                  hintText: 'family.relationship_hint'.tr(),
                  prefixIcon: const Icon(Icons.people_outline_rounded),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'family.age_field_label'.tr(),
                  prefixIcon: const Icon(Icons.cake_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final age = int.tryParse(v.trim());
                  if (age == null || age < 0 || age > 130) {
                    return 'family.age_invalid'.tr();
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isEditing
                    ? 'family.save_changes'.tr()
                    : 'family.add_member'.tr(),
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
