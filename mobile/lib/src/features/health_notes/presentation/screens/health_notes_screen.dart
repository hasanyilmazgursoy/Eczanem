import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../imports/imports.dart';
import '../../data/health_notes_repository.dart';
import '../../data/models/health_note.dart';

/// FAZ 7 — Sağlık Notları Ekranı.
///
/// - Liste görünümü: tüm notlar + kategori filtresi
/// - Alt sayfa (bottom sheet): not ekleme ve düzenleme formu
class HealthNotesScreen extends StatefulWidget {
  const HealthNotesScreen({super.key});

  @override
  State<HealthNotesScreen> createState() => _HealthNotesScreenState();
}

class _HealthNotesScreenState extends State<HealthNotesScreen> {
  List<HealthNote> _notes = const [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _notes = HealthNotesRepository.instance.getNotes();
    });
  }

  /// Seçili kategoriye göre filtreli liste.
  List<HealthNote> get _filteredNotes {
    if (_selectedCategory == null) return _notes;
    return _notes.where((n) => n.category == _selectedCategory).toList();
  }

  Future<void> _openAddSheet({HealthNote? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _NoteEditorSheet(existing: existing),
    );
    if (result ?? false) _load();
  }

  Future<void> _deleteNote(HealthNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('health_notes.delete_confirm_title'.tr()),
        content: Text('health_notes.delete_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('health_notes.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'health_notes.delete'.tr(),
              style: TextStyle(color: context.colors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await HealthNotesRepository.instance.removeNote(note.id);
    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _load();
        context.showTypedSnackBar(
          'health_notes.deleted_success'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  Future<void> _openReportSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _HealthReportSheet(notes: _notes),
    );
  }

  Future<void> _openDoctorViewSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DoctorViewSheet(notes: _notes),
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
          'health_notes.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_notes.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.summarize_outlined),
              tooltip: 'health_notes.report_button'.tr(),
              onPressed: _openReportSheet,
            ),
            IconButton(
              icon: const Icon(Icons.medical_services_outlined),
              tooltip: 'health_notes.doctor_view'.tr(),
              onPressed: _openDoctorViewSheet,
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: Text('health_notes.add'.tr()),
      ),
      body: _buildListView(),
    );
  }

  /// Liste görünümü — kategori filtresi + notlar.
  Widget _buildListView() {
    return Column(
      children: [
        _CategoryFilterBar(
          selected: _selectedCategory,
          onSelected: (cat) => setState(() => _selectedCategory = cat),
        ),
        Expanded(child: _buildNoteList()),
      ],
    );
  }

  Widget _buildNoteList() {
    final filtered = _filteredNotes;

    if (filtered.isEmpty) {
      return _EmptyNotesState(
        isFiltered: _selectedCategory != null,
        onAdd: () => _openAddSheet(),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        // FAB için boşluk
        AppSpacing.xxl + 56,
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final note = filtered[index];
        return _NoteCard(
          note: note,
          onEdit: () => _openAddSheet(existing: note),
          onDelete: () => _deleteNote(note),
        );
      },
    );
  }
}

// ════════════════════════ KATEGÖRİ FİLTRE ÇUBUĞU ═══════════════════════

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final void Function(String? category) onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    // "Tümü" + tüm kategoriler
    final allCategories = [null, ...HealthNoteCategory.all];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.sm,
        ),
        itemCount: allCategories.length,
        separatorBuilder: (_, __) => SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isSelected = selected == cat;

          final label = cat == null
              ? 'health_notes.filter_all'.tr()
              : 'health_notes.category_$cat'.tr();

          return ChoiceChip(
            label: Text(
              cat == null ? label : '${HealthNoteCategory.iconFor(cat)} $label',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(cat),
            selectedColor: colorScheme.primary,
            labelStyle: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════ NOT KARTI ════════════════════════

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final HealthNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;
    final appColors = context.appColors;

    final dateStr =
        '${note.date.day.toString().padLeft(2, '0')}.${note.date.month.toString().padLeft(2, '0')}.${note.date.year}';

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst satır: kategori ikonu + kategori adı + tarih + menü
              Row(
                children: [
                  Text(
                    HealthNoteCategory.iconFor(note.category),
                    style: const TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'health_notes.category_${note.category}'.tr(),
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('health_notes.edit'.tr()),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'health_notes.delete'.tr(),
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              // Not metni — maksimum 4 satır
              Text(
                note.text,
                style: textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              // Klinik ölçüm badge'leri
              if (note.bloodPressureDisplay != null ||
                  note.glucoseValue != null ||
                  note.painLevel != null ||
                  note.symptoms.isNotEmpty ||
                  note.medicationTaken) ...[
                SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (note.bloodPressureDisplay != null)
                      _MeasurementBadge(
                        label: '🩺 ${note.bloodPressureDisplay!}',
                        backgroundColor: colorScheme.errorContainer,
                        foregroundColor: colorScheme.onErrorContainer,
                      ),
                    if (note.glucoseValue != null)
                      _MeasurementBadge(
                        label:
                            '🩸 ${note.glucoseValue!.toStringAsFixed(0)} mg/dL',
                        backgroundColor: appColors.warningContainer ??
                            colorScheme.tertiaryContainer,
                        foregroundColor: appColors.onWarningContainer ??
                            colorScheme.onTertiaryContainer,
                      ),
                    if (note.painLevel != null)
                      _MeasurementBadge(
                        label: '😣 ${'health_notes.pain_level'.tr(namedArgs: {
                              'level': note.painLevel.toString()
                            })}',
                        backgroundColor: _painBadgeColor(
                            note.painLevel!, appColors, colorScheme),
                        foregroundColor: _painBadgeTextColor(
                            note.painLevel!, appColors, colorScheme),
                      ),
                    if (note.medicationTaken)
                      _MeasurementBadge(
                        label: '💊 ${'health_notes.medication_taken'.tr()}',
                        backgroundColor: appColors.successContainer ??
                            colorScheme.primaryContainer,
                        foregroundColor: appColors.onSuccessContainer ??
                            colorScheme.onPrimaryContainer,
                      ),
                    ...note.symptoms.take(3).map(
                          (s) => _MeasurementBadge(
                            label: s,
                            backgroundColor: appColors.infoContainer ??
                                colorScheme.secondaryContainer,
                            foregroundColor: appColors.onInfoContainer ??
                                colorScheme.onSecondaryContainer,
                          ),
                        ),
                    if (note.symptoms.length > 3)
                      _MeasurementBadge(
                        label: '+${note.symptoms.length - 3}',
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        foregroundColor: colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════ NOT EDİTÖR BOTTOM SHEET ══════════════════════

class _NoteEditorSheet extends StatefulWidget {
  const _NoteEditorSheet({this.existing});

  /// Null ise yeni not ekleme, dolu ise düzenleme modu.
  final HealthNote? existing;

  @override
  State<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<_NoteEditorSheet> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _systolicCtrl;
  late final TextEditingController _diastolicCtrl;
  late final TextEditingController _glucoseCtrl;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late double _painLevel;
  List<String> _selectedSymptoms = [];
  bool _medicationTaken = false;
  AppStatus _status = AppStatus.initial;

  /// Yaygın semptom seçenekleri — hızlı seçim için.
  static const _kCommonSymptoms = [
    'Baş ağrısı',
    'Halsizlik',
    'Bulantı',
    'Ateş',
    'Öksürük',
    'Nefes darlığı',
    'Baş dönmesi',
    'Uykusuzluk',
    'İştahsızlık',
    'Eklem ağrısı',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _textCtrl = TextEditingController(text: existing?.text ?? '');
    _systolicCtrl = TextEditingController(
      text: existing?.systolic?.toString() ?? '',
    );
    _diastolicCtrl = TextEditingController(
      text: existing?.diastolic?.toString() ?? '',
    );
    _glucoseCtrl = TextEditingController(
      text: existing?.glucoseValue?.toString() ?? '',
    );
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedCategory = existing?.category ?? HealthNoteCategory.genel;
    _painLevel = existing?.painLevel?.toDouble() ?? 5.0;
    _selectedSymptoms = existing?.symptoms.toList() ?? [];
    _medicationTaken = existing?.medicationTaken ?? false;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _glucoseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (_textCtrl.text.trim().isEmpty) {
      context.showTypedSnackBar(
        'health_notes.text_required'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() => _status = AppStatus.loading);

    // Kategoriye göre ölçüm değerlerini parse et.
    final int? systolic = _selectedCategory == HealthNoteCategory.tansiyon
        ? int.tryParse(_systolicCtrl.text)
        : null;
    final int? diastolic = _selectedCategory == HealthNoteCategory.tansiyon
        ? int.tryParse(_diastolicCtrl.text)
        : null;
    final double? glucose = _selectedCategory == HealthNoteCategory.seker
        ? double.tryParse(_glucoseCtrl.text)
        : null;
    final int? pain = _selectedCategory == HealthNoteCategory.agri
        ? _painLevel.round()
        : null;

    final Either<Failure, HealthNote> result;

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        date: _selectedDate,
        category: _selectedCategory,
        text: _textCtrl.text,
        systolic: systolic,
        diastolic: diastolic,
        glucoseValue: glucose,
        painLevel: pain,
        symptoms: _selectedSymptoms,
        medicationTaken: _medicationTaken,
      );
      result = await HealthNotesRepository.instance.updateNote(updated);
    } else {
      result = await HealthNotesRepository.instance.addNote(
        date: _selectedDate,
        category: _selectedCategory,
        text: _textCtrl.text,
        systolic: systolic,
        diastolic: diastolic,
        glucoseValue: glucose,
        painLevel: pain,
        symptoms: _selectedSymptoms,
        medicationTaken: _medicationTaken,
      );
    }

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _status = AppStatus.failure);
        context.showTypedSnackBar(failure.message, type: SnackBarType.error);
      },
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;
    final isEdit = widget.existing != null;

    // Bug fix: SafeArea + dış Padding klavye yüksekliğini yönetir;
    // iç scroll sabit padding kullanır.
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Başlık
              Text(
                isEdit
                    ? 'health_notes.edit_title'.tr()
                    : 'health_notes.add_title'.tr(),
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSpacing.xl),
              // Tarih seçici
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 20, color: colorScheme.primary),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        '${_selectedDate.day.toString().padLeft(2, '0')}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.year}',
                        style: textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              // Kategori seçimi
              Text(
                'health_notes.category_label'.tr(),
                style: textTheme.labelLarge,
              ),
              SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: HealthNoteCategory.all.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(
                      '${HealthNoteCategory.iconFor(cat)} ${'health_notes.category_$cat'.tr()}',
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.md),

              // ── Tansiyon alanları ──
              if (_selectedCategory == HealthNoteCategory.tansiyon) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _systolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'health_notes.systolic'.tr(),
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _diastolicCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'health_notes.diastolic'.tr(),
                          suffixText: 'mmHg',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // ── Kan şekeri alanı ──
              if (_selectedCategory == HealthNoteCategory.seker) ...[
                TextField(
                  controller: _glucoseCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'health_notes.glucose_value'.tr(),
                    suffixText: 'mg/dL',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // ── Ağrı seviyesi slider'ı ──
              if (_selectedCategory == HealthNoteCategory.agri) ...[
                Row(
                  children: [
                    Text(
                      'health_notes.pain_level'.tr(),
                      style: textTheme.labelLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${_painLevel.round()}/10',
                      style: textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'health_notes.pain_none'.tr(),
                      style: textTheme.bodySmall,
                    ),
                    Expanded(
                      child: Slider(
                        value: _painLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        activeColor: _painColor(_painLevel),
                        onChanged: (v) => setState(() => _painLevel = v),
                      ),
                    ),
                    Text(
                      'health_notes.pain_severe'.tr(),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
              ],

              // Semptom hızlı seçimi
              Text(
                'health_notes.symptoms_label'.tr(),
                style: textTheme.labelLarge,
              ),
              SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: _kCommonSymptoms.map((s) {
                  final selected = _selectedSymptoms.contains(s);
                  return FilterChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    visualDensity: VisualDensity.compact,
                    selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                    checkmarkColor: colorScheme.primary,
                    onSelected: (_) => setState(() {
                      if (selected) {
                        _selectedSymptoms.remove(s);
                      } else {
                        _selectedSymptoms.add(s);
                      }
                    }),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.sm),
              // İlaç alındı toggle
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text('health_notes.medication_taken'.tr()),
                subtitle: Text('health_notes.medication_taken_subtitle'.tr()),
                value: _medicationTaken,
                onChanged: (v) => setState(() => _medicationTaken = v),
              ),
              SizedBox(height: AppSpacing.md),
              // Not metni
              AppTextField(
                controller: _textCtrl,
                label: 'health_notes.text_label'.tr(),
                hint: 'health_notes.text_hint'.tr(),
                maxLines: 5,
                autofocus: !isEdit,
              ),
              SizedBox(height: AppSpacing.xl),
              // Kaydet butonu
              AppButton(
                onPressed: _status.isLoading ? null : _save,
                isLoading: _status.isLoading,
                label: isEdit
                    ? 'health_notes.update'.tr()
                    : 'health_notes.save'.tr(),
                isFullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ağrı seviyesine göre renk — 0–3 yeşil, 4–6 turuncu, 7+ kırmızı.
  Color _painColor(double level) {
    if (level <= 3) return Colors.green;
    if (level <= 6) return Colors.orange;
    return Colors.red;
  }
}

// ═══════════════════════════ BOŞ DURUM ════════════════════════

class _EmptyNotesState extends StatelessWidget {
  const _EmptyNotesState({
    required this.isFiltered,
    required this.onAdd,
  });

  final bool isFiltered;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Koyu temada beyaz arka plan sorununu gidermek için köşe yuvarla
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/health_notes_empty.png',
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              isFiltered
                  ? 'health_notes.empty_filtered_title'.tr()
                  : 'health_notes.empty_title'.tr(),
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered
                  ? 'health_notes.empty_filtered_subtitle'.tr()
                  : 'health_notes.empty_subtitle'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              SizedBox(height: AppSpacing.xxl),
              AppButton(
                onPressed: onAdd,
                label: 'health_notes.add_first'.tr(),
                prefixIcon: const Icon(Icons.add_rounded),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════ YARDIMCI FONKSİYONLAR ══════════════════════

/// Ağrı seviyesine göre badge arka plan rengi.
Color _painBadgeColor(
    int level, AppColorsExtension appColors, ColorScheme colorScheme) {
  if (level <= 3)
    return appColors.successContainer ?? colorScheme.primaryContainer;
  if (level <= 6)
    return appColors.warningContainer ?? colorScheme.tertiaryContainer;
  return colorScheme.errorContainer;
}

/// Ağrı seviyesine göre badge yazı rengi.
Color _painBadgeTextColor(
    int level, AppColorsExtension appColors, ColorScheme colorScheme) {
  if (level <= 3)
    return appColors.onSuccessContainer ?? colorScheme.onPrimaryContainer;
  if (level <= 6)
    return appColors.onWarningContainer ?? colorScheme.onTertiaryContainer;
  return colorScheme.onErrorContainer;
}

// ═══════════════════════ ÖLÇÜM BADGE ═══════════════════════

/// Kart üzerinde küçük renkli etiket widget'ı.
class _MeasurementBadge extends StatelessWidget {
  const _MeasurementBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }
}

// ═══════════════════════ SAĞLIK RAPORU SAYFASI ═══════════════════════

class _HealthReportSheet extends StatelessWidget {
  const _HealthReportSheet({required this.notes});

  final List<HealthNote> notes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    if (notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(
            'health_notes.report_no_notes'.tr(),
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final last7Days =
        notes.where((n) => now.difference(n.date).inDays < 7).toList();

    final byCategory = <String, int>{};
    for (final n in notes) {
      byCategory[n.category] = (byCategory[n.category] ?? 0) + 1;
    }

    // Tarih bazlı sıralanmış ölçüm notları
    final bpNotes = notes
        .where((n) =>
            n.category == HealthNoteCategory.tansiyon && n.systolic != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final glucoseNotes = notes
        .where((n) =>
            n.category == HealthNoteCategory.seker && n.glucoseValue != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'health_notes.report_title'.tr(),
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    // Özet istatistik kartları
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'health_notes.report_total'.tr(),
                            value: '${notes.length}',
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'health_notes.report_last7'.tr(),
                            value: '${last7Days.length}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Kategoriye göre dağılım
                    Text(
                      'health_notes.report_by_category'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...byCategory.entries.map(
                      (e) => _CategoryBar(
                        category: e.key,
                        count: e.value,
                        total: notes.length,
                      ),
                    ),
                    // Tansiyon trend grafiği (en az 2 ölçüm gerekli)
                    if (bpNotes.length >= 2) ...[
                      const SizedBox(height: 24),
                      Text(
                        'health_notes.report_blood_pressure'.tr(),
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _TrendChart(
                          spots: bpNotes
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.systolic!.toDouble(),
                                  ))
                              .toList(),
                          color: Colors.red,
                          minY: 60,
                          maxY: 200,
                        ),
                      ),
                    ],
                    // Kan şekeri trend grafiği
                    if (glucoseNotes.length >= 2) ...[
                      const SizedBox(height: 24),
                      Text(
                        'health_notes.report_glucose'.tr(),
                        style: textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _TrendChart(
                          spots: glucoseNotes
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    e.key.toDouble(),
                                    e.value.glucoseValue!,
                                  ))
                              .toList(),
                          color: Colors.orange,
                          minY: 50,
                          maxY: 400,
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════ DOKTORA GÖSTER SAYFASI ═══════════════════════

class _DoctorViewSheet extends StatelessWidget {
  const _DoctorViewSheet({required this.notes});

  final List<HealthNote> notes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    final bpNotes = notes.where((n) => n.bloodPressureDisplay != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final glucoseNotes = notes.where((n) => n.glucoseValue != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final painNotes = notes.where((n) => n.painLevel != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Semptom sıklığı haritası
    final freq = <String, int>{};
    for (final n in notes) {
      for (final s in n.symptoms) {
        freq[s] = (freq[s] ?? 0) + 1;
      }
    }
    final sortedSymptoms = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasData = bpNotes.isNotEmpty ||
        glucoseNotes.isNotEmpty ||
        painNotes.isNotEmpty ||
        sortedSymptoms.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'health_notes.doctor_view_title'.tr(),
                          style: textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_rounded),
                          tooltip: 'health_notes.report_share'.tr(),
                          onPressed: _share,
                        ),
                      ],
                    ),
                    Text(
                      'health_notes.doctor_view_subtitle'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!hasData)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: Text(
                            'health_notes.no_measurements'.tr(),
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    // Vital bulgular
                    if (bpNotes.isNotEmpty || glucoseNotes.isNotEmpty) ...[
                      _SectionHeader(title: 'health_notes.vital_findings'.tr()),
                      const SizedBox(height: 8),
                      if (bpNotes.isNotEmpty)
                        _DoctorDataRow(
                          icon: Icons.favorite_rounded,
                          color: Colors.red,
                          label: 'health_notes.report_blood_pressure'.tr(),
                          value: bpNotes.first.bloodPressureDisplay!,
                          date: bpNotes.first.date,
                        ),
                      if (glucoseNotes.isNotEmpty)
                        _DoctorDataRow(
                          icon: Icons.water_drop_rounded,
                          color: Colors.orange,
                          label: 'health_notes.report_glucose'.tr(),
                          value:
                              '${glucoseNotes.first.glucoseValue!.toStringAsFixed(0)} mg/dL',
                          date: glucoseNotes.first.date,
                        ),
                      const SizedBox(height: 20),
                    ],
                    // Ağrı takibi
                    if (painNotes.isNotEmpty) ...[
                      _SectionHeader(title: 'health_notes.pain_tracking'.tr()),
                      const SizedBox(height: 8),
                      ...painNotes.take(5).map(
                            (n) => _DoctorDataRow(
                              icon: Icons.warning_amber_rounded,
                              color: _painBadgeTextColor(n.painLevel!,
                                  context.appColors, context.colors),
                              label: 'Ağrı ${n.painLevel}/10',
                              value: n.text.length > 50
                                  ? '${n.text.substring(0, 50)}…'
                                  : n.text,
                              date: n.date,
                            ),
                          ),
                      const SizedBox(height: 20),
                    ],
                    // Semptom sıklığı
                    if (sortedSymptoms.isNotEmpty) ...[
                      _SectionHeader(
                          title: 'health_notes.symptom_frequency'.tr()),
                      const SizedBox(height: 8),
                      ...sortedSymptoms.take(8).map(
                            (e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(e.key,
                                        style: textTheme.bodyMedium),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: e.value /
                                                  sortedSymptoms.first.value,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              minHeight: 6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${e.value}x',
                                          style: textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Klinik özeti metin olarak paylaş.
  void _share() {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    final bpNotes = notes.where((n) => n.bloodPressureDisplay != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final glucoseNotes = notes.where((n) => n.glucoseValue != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final sb = StringBuffer()
      ..writeln('=== KLİNİK ÖZET ($dateStr) ===')
      ..writeln();

    if (bpNotes.isNotEmpty) {
      sb.writeln('TANSIYON:');
      for (final n in bpNotes.take(5)) {
        final d =
            '${n.date.day.toString().padLeft(2, '0')}.${n.date.month.toString().padLeft(2, '0')}';
        sb.writeln('  $d: ${n.bloodPressureDisplay}');
      }
      sb.writeln();
    }

    if (glucoseNotes.isNotEmpty) {
      sb.writeln('KAN ŞEKERİ (mg/dL):');
      for (final n in glucoseNotes.take(5)) {
        final d =
            '${n.date.day.toString().padLeft(2, '0')}.${n.date.month.toString().padLeft(2, '0')}';
        sb.writeln('  $d: ${n.glucoseValue!.toStringAsFixed(0)} mg/dL');
      }
      sb.writeln();
    }

    sb.writeln('Eczanem uygulaması ile oluşturuldu.');
    Share.share(sb.toString());
  }
}

// ══════════════════════ YARDIMCI WİDGET'LAR ══════════════════════

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.count,
    required this.total,
  });

  final String category;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    final label =
        '${HealthNoteCategory.iconFor(category)} ${'health_notes.category_$category'.tr()}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: context.textTheme.bodySmall),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                color: context.colors.primary,
                backgroundColor: context.colors.surfaceContainerHighest,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: context.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// fl_chart ile basit çizgi grafik — kan basıncı / kan şekeri trendi için.
class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
  });

  final List<FlSpot> spots;
  final Color color;
  final double minY;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.withValues(alpha: 0.2),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (v, _) => Text(
                '${v.toInt() + 1}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: context.colors.primary,
      ),
    );
  }
}

class _DoctorDataRow extends StatelessWidget {
  const _DoctorDataRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.date,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: context.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Text(
            dateStr,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
