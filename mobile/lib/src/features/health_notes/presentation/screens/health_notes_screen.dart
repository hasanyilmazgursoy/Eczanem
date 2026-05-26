import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';

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
  String? _selectedCategory; // null = tümü
  bool _showCalendar = false; // liste / takvim toggle
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

  /// Belirli güne ait notları döner (takvim görünümü için).
  List<HealthNote> _getNotesForDay(DateTime day) {
    return _notes.where((n) {
      return n.date.year == day.year &&
          n.date.month == day.month &&
          n.date.day == day.day;
    }).toList();
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

  void _showReportSheet() {
    if (_notes.isEmpty) {
      context.showTypedSnackBar(
        'health_notes.report_no_notes'.tr(),
        type: SnackBarType.info,
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _HealthReportSheet(notes: _notes),
    );
  }

  void _showDoctorView() {
    if (_notes.isEmpty) {
      context.showTypedSnackBar(
        'health_notes.report_no_notes'.tr(),
        type: SnackBarType.info,
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _DoctorViewSheet(notes: _notes),
    );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: Text(
          'health_notes.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Klinik özet (Doktora Göster) butonu
          IconButton(
            onPressed: _showDoctorView,
            icon: const Icon(
              Icons.medical_information_rounded,
              color: Colors.white,
            ),
            tooltip: 'health_notes.doctor_view'.tr(),
          ),
          // Rapor oluşturma butonu
          IconButton(
            onPressed: _showReportSheet,
            icon: const Icon(Icons.summarize_outlined, color: Colors.white),
            tooltip: 'health_notes.report_button'.tr(),
          ),
          // Liste / Takvim toggle
          IconButton(
            onPressed: () => setState(() {
              _showCalendar = !_showCalendar;
              if (_showCalendar) _selectedDay = DateTime.now();
            }),
            icon: Icon(
              _showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            tooltip: _showCalendar
                ? 'health_notes.list_view'.tr()
                : 'health_notes.calendar_view'.tr(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('health_notes.add'.tr()),
      ),
      body: _showCalendar ? _buildCalendarView() : _buildListView(),
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

  /// Takvim görünümü — aylık takvim + seçili günün notları.
  Widget _buildCalendarView() {
    final selectedDay = _selectedDay ?? DateTime.now();
    final dayNotes = _getNotesForDay(selectedDay);

    return Column(
      children: [
        TableCalendar<HealthNote>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          eventLoader: _getNotesForDay,
          calendarFormat: CalendarFormat.month,
          // Sadece aylık görünüme izin ver
          availableCalendarFormats: const {CalendarFormat.month: ''},
          headerStyle: const HeaderStyle(formatButtonVisible: false),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              shape: BoxShape.circle,
            ),
            // Not olan günlerde küçük nokta göster
            markerDecoration: const BoxDecoration(
              color: Color(0xFF1565C0),
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) {
            _focusedDay = focused;
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: dayNotes.isEmpty
              ? _EmptyNotesState(
                  isFiltered: true,
                  onAdd: () => _openAddSheet(),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xxl + 56,
                  ),
                  itemCount: dayNotes.length,
                  separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final note = dayNotes[index];
                    return _NoteCard(
                      note: note,
                      onEdit: () => _openAddSheet(existing: note),
                      onDelete: () => _deleteNote(note),
                    );
                  },
                ),
        ),
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
            selectedColor: const Color(0xFF1565C0),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : colorScheme.onSurface,
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
              // Üst satır: kategori ikonu + tarih + mood + menü
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
                  if (note.mood.isNotEmpty) ...[
                    Text(note.mood, style: const TextStyle(fontSize: 18)),
                    SizedBox(width: AppSpacing.xs),
                  ],
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
              // Ölçüm değerleri (kategoriye göre)
              if (note.bloodPressureDisplay != null)
                _MeasurementBadge(
                  icon: Icons.favorite_rounded,
                  value: note.bloodPressureDisplay!,
                  color: Colors.red.shade600,
                ),
              if (note.glucoseValue != null)
                _MeasurementBadge(
                  icon: Icons.water_drop_rounded,
                  value: '${note.glucoseValue!.toStringAsFixed(1)} mg/dL',
                  color: Colors.amber.shade700,
                ),
              if (note.painLevel != null)
                _MeasurementBadge(
                  icon: Icons.thermostat_rounded,
                  value: 'Ağrı: ${note.painLevel}/10',
                  color: Colors.orange.shade700,
                ),
              // Semptom chip'leri — en fazla 3 göster
              if (note.symptoms.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    ...note.symptoms.take(3).map(
                          (s) => Chip(
                            label: Text(s),
                            labelStyle: const TextStyle(fontSize: 11),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    if (note.symptoms.length > 3)
                      Chip(
                        label: Text('+${note.symptoms.length - 3}'),
                        labelStyle: const TextStyle(fontSize: 11),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              // İlaç alınmadı uyarısı
              if (!note.medicationTaken) ...[
                SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 14,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'health_notes.medication_not_taken'.tr(),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: AppSpacing.sm),
              // Not metni — maksimum 4 satır
              Text(
                note.text,
                style: textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
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
  late String _selectedMood;
  late double _painLevel;
  late List<String> _selectedSymptoms;
  late bool _medicationTaken;
  AppStatus _status = AppStatus.initial;

  /// Hızlı semptom seçenekleri.
  static const _kSymptoms = [
    'Bulantı',
    'Baş dönmesi',
    'Yorgunluk',
    'Baş ağrısı',
    'Karın ağrısı',
    'Nefes darlığı',
    'Çarpıntı',
    'Şişkinlik',
    'İştahsızlık',
    'Uyku sorunu',
    'Titreme',
    'Ateş',
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
    _selectedMood = existing?.mood ?? HealthNoteMood.iyi;
    _painLevel = existing?.painLevel?.toDouble() ?? 5.0;
    _selectedSymptoms = List<String>.from(existing?.symptoms ?? const []);
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
        mood: _selectedMood,
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
        mood: _selectedMood,
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
                    selectedColor: const Color(0xFF1565C0),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
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

              // Mood seçimi
              Text(
                'health_notes.mood_label'.tr(),
                style: textTheme.labelLarge,
              ),
              SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: HealthNoteMood.all.map((mood) {
                  final isSelected = _selectedMood == mood;
                  return ChoiceChip(
                    label: Text(
                      mood,
                      style: const TextStyle(fontSize: 22),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedMood = mood),
                    selectedColor: colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.md),

              // ── Semptom hızlı seçimi ──
              Text(
                'health_notes.symptoms_label'.tr(),
                style: textTheme.labelLarge,
              ),
              SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _kSymptoms.map((s) {
                  final selected = _selectedSymptoms.contains(s);
                  return FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedSymptoms.add(s);
                      } else {
                        _selectedSymptoms.remove(s);
                      }
                    }),
                    selectedColor:
                        const Color(0xFF1565C0).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF1565C0),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.md),

              // ── İlaç alındı switch ──
              SwitchListTile.adaptive(
                value: _medicationTaken,
                onChanged: (v) => setState(() => _medicationTaken = v),
                title: Text('health_notes.medication_taken'.tr()),
                subtitle: Text('health_notes.medication_taken_subtitle'.tr()),
                activeTrackColor: const Color(0xFF1565C0),
                contentPadding: EdgeInsets.zero,
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
                color: const Color(0xFF1565C0),
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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/health_notes_empty.png',
              height: 160,
              fit: BoxFit.contain,
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
                color: const Color(0xFF1565C0),
                prefixIcon: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════ SAĞLIK RAPORU SAYFASI ════════════════

/// Tüm sağlık notlarından özet istatistik üreten bottom sheet.
///
/// Kategori dağılımı, mood trendi ve son 7 gün özetini gösterir.
/// Oluşturulan rapor share_plus ile paylaşılabilir.
class _HealthReportSheet extends StatelessWidget {
  const _HealthReportSheet({required this.notes});

  final List<HealthNote> notes;

  /// Notları kategoriye göre gruplar.
  Map<String, int> _categoryCounts() {
    final counts = <String, int>{};
    for (final n in notes) {
      counts[n.category] = (counts[n.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Notları mood'a göre gruplar.
  Map<String, int> _moodCounts() {
    final counts = <String, int>{};
    for (final n in notes) {
      if (n.mood.isNotEmpty) {
        counts[n.mood] = (counts[n.mood] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Son 7 günün notlarını döner, tarih azalan sırada.
  List<HealthNote> _last7DaysNotes() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return notes.where((n) => n.date.isAfter(cutoff)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Paylaşım için metin raporu oluşturur.
  String _buildShareText(BuildContext context) {
    final buf = StringBuffer();
    buf.writeln('health_notes.report_share_text'.tr());
    buf.writeln('─' * 30);
    buf.writeln('${'health_notes.report_total'.tr()}: ${notes.length}');
    buf.writeln();
    buf.writeln('${'health_notes.report_by_category'.tr()}:');
    for (final entry in _categoryCounts().entries) {
      final icon = HealthNoteCategory.iconFor(entry.key);
      final label = 'health_notes.category_${entry.key}'.tr();
      buf.writeln('  $icon $label: ${entry.value}');
    }
    buf.writeln();

    final last7 = _last7DaysNotes();
    buf.writeln('${'health_notes.report_last7'.tr()}:');
    if (last7.isEmpty) {
      buf.writeln('  ${'health_notes.report_last7_empty'.tr()}');
    } else {
      for (final n in last7.take(5)) {
        final dateStr =
            '${n.date.day.toString().padLeft(2, '0')}.${n.date.month.toString().padLeft(2, '0')}.${n.date.year}';
        buf.writeln(
            '  [$dateStr] ${n.mood.isNotEmpty ? '${n.mood} ' : ''}${n.text}');
      }
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;
    final catCounts = _categoryCounts();
    final moodCounts = _moodCounts();
    final last7 = _last7DaysNotes();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            // Tutma kolu
            Center(
              child: Container(
                margin: EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Başlık + paylaş butonu
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  const Icon(Icons.summarize_outlined, size: 28),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'health_notes.report_title'.tr(),
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: () => Share.share(_buildShareText(context)),
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'health_notes.report_share'.tr(),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                children: [
                  // Toplam not sayısı
                  _ReportStatCard(
                    icon: Icons.note_outlined,
                    label: 'health_notes.report_total'.tr(),
                    value: '${notes.length}',
                    color: const Color(0xFF1565C0),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Kategoriye göre dağılım
                  Text(
                    'health_notes.report_by_category'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  ...catCounts.entries.map((entry) {
                    final pct =
                        notes.isEmpty ? 0.0 : entry.value / notes.length;
                    return _CategoryProgressRow(
                      icon: HealthNoteCategory.iconFor(entry.key),
                      label: 'health_notes.category_${entry.key}'.tr(),
                      count: entry.value,
                      fraction: pct,
                    );
                  }),
                  SizedBox(height: AppSpacing.lg),

                  // Mood dağılımı
                  if (moodCounts.isNotEmpty) ...[
                    Text(
                      'health_notes.report_mood_title'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: moodCounts.entries
                          .map(
                            (e) => Chip(
                              label: Text('${e.key}  ×${e.value}'),
                              labelStyle: const TextStyle(fontSize: 16),
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],

                  // Son 7 gün özeti
                  Text(
                    'health_notes.report_last7'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  if (last7.isEmpty)
                    Text(
                      'health_notes.report_last7_empty'.tr(),
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...last7.take(5).map((n) {
                      final dateStr =
                          '${n.date.day.toString().padLeft(2, '0')}.${n.date.month.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.mood.isNotEmpty
                                  ? n.mood
                                  : HealthNoteCategory.iconFor(n.category),
                              style: const TextStyle(fontSize: 20),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateStr,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    n.text,
                                    style: textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tek satırlık istatistik kartı (toplam not vb.).
class _ReportStatCard extends StatelessWidget {
  const _ReportStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: context.textTheme.bodyLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: context.textTheme.headlineMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Kategori dağılım satırı — ikon + etiket + progress bar + sayı.
class _CategoryProgressRow extends StatelessWidget {
  const _CategoryProgressRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String icon;
  final String label;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: context.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: context.colors.onSurface.withValues(alpha: 0.1),
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(4),
              minHeight: 8,
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: context.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════ ÖLÇÜM ROZET WİDGET'İ ══════════════════

/// Renk kodlu ölçüm değerini pill şeklinde gösterir.
class _MeasurementBadge extends StatelessWidget {
  const _MeasurementBadge({
    required this.icon,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════ SAĞLIK TREND GRAFİĞİ ════════════════════

/// fl_chart ile tek veya çift çizgili trend grafiği.
///
/// Tansiyon için iki çizgi (sistolik/diastolik), tek ölçümler için bir çizgi.
class _HealthTrendChart extends StatelessWidget {
  const _HealthTrendChart({
    required this.spots,
    required this.color,
    required this.unit,
    this.spots2,
    this.color2,
  });

  final List<FlSpot> spots;
  final Color color;
  final String unit;

  /// Diastolik değerler için ikinci çizgi (isteğe bağlı).
  final List<FlSpot>? spots2;
  final Color? color2;

  @override
  Widget build(BuildContext context) {
    final allSpots = [...spots, if (spots2 != null) ...spots2!];
    if (allSpots.isEmpty) return const SizedBox.shrink();

    final minY = allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10;
    final maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10;

    LineChartBarData line(List<FlSpot> s, Color c) => LineChartBarData(
          spots: s,
          isCurved: true,
          color: c,
          barWidth: 2.5,
          dotData: FlDotData(
            getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
              radius: 3,
              color: c,
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: c.withValues(alpha: 0.08),
          ),
        );

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: minY < 0 ? 0 : minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) => Text(
                  '${v.toInt() + 1}.',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            line(spots, color),
            if (spots2 != null && color2 != null) line(spots2!, color2!),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots
                  .map(
                    (ts) => LineTooltipItem(
                      '${ts.y.toStringAsFixed(1)} $unit',
                      const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════ DOKTORA GÖSTER SAYFASI ══════════════════

/// Klinik özet — doktora göstermek için hazırlanmış yapılandırılmış rapor.
///
/// Vital bulgular, ağrı takibi, semptom sıklığı ve son notları listeler.
/// Metin tabanlı paylaşım desteği vardır.
class _DoctorViewSheet extends StatelessWidget {
  const _DoctorViewSheet({required this.notes});

  final List<HealthNote> notes;

  /// Kategoriye göre filtreli notlar.
  List<HealthNote> _byCategory(String cat) =>
      notes.where((n) => n.category == cat).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Semptom sıklık haritası, azalan sırayla.
  List<MapEntry<String, int>> _symptomFrequency() {
    final freq = <String, int>{};
    for (final n in notes) {
      for (final s in n.symptoms) {
        freq[s] = (freq[s] ?? 0) + 1;
      }
    }
    return freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  /// Klinik metin raporu — paylaşım için.
  String _buildClinicalText() {
    final buf = StringBuffer();
    buf.writeln('=== KLİNİK ÖZET ===');
    buf.writeln(
      'Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
    );
    buf.writeln('Toplam kayıt: ${notes.length}');
    buf.writeln();

    final tansiyon = _byCategory(HealthNoteCategory.tansiyon);
    if (tansiyon.isNotEmpty) {
      buf.writeln('TANSIYON:');
      for (final n in tansiyon.take(5)) {
        if (n.bloodPressureDisplay != null) {
          final d = '${n.date.day}.${n.date.month}.${n.date.year}';
          buf.writeln('  $d — ${n.bloodPressureDisplay}');
        }
      }
      buf.writeln();
    }

    final seker = _byCategory(HealthNoteCategory.seker);
    if (seker.isNotEmpty) {
      buf.writeln('KAN ŞEKERİ:');
      for (final n in seker.take(5)) {
        if (n.glucoseValue != null) {
          final d = '${n.date.day}.${n.date.month}.${n.date.year}';
          buf.writeln('  $d — ${n.glucoseValue!.toStringAsFixed(1)} mg/dL');
        }
      }
      buf.writeln();
    }

    final freq = _symptomFrequency();
    if (freq.isNotEmpty) {
      buf.writeln('SEMPTOMLAR:');
      for (final e in freq.take(8)) {
        buf.writeln('  ${e.key}: ${e.value}x');
      }
    }

    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    final colorScheme = context.colors;

    final tansiyon = _byCategory(HealthNoteCategory.tansiyon);
    final seker = _byCategory(HealthNoteCategory.seker);
    final agri = _byCategory(HealthNoteCategory.agri);
    final symptomFreq = _symptomFrequency();

    // fl_chart için nokta listeleri oluştur.
    final bpSysSpots = <FlSpot>[];
    final bpDiaSpots = <FlSpot>[];
    for (var i = 0; i < tansiyon.length; i++) {
      final n = tansiyon[i];
      if (n.systolic != null) {
        bpSysSpots.add(FlSpot(i.toDouble(), n.systolic!.toDouble()));
      }
      if (n.diastolic != null) {
        bpDiaSpots.add(FlSpot(i.toDouble(), n.diastolic!.toDouble()));
      }
    }

    final glucoseSpots = <FlSpot>[];
    for (var i = 0; i < seker.length; i++) {
      final n = seker[i];
      if (n.glucoseValue != null) {
        glucoseSpots.add(FlSpot(i.toDouble(), n.glucoseValue!));
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.98,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Column(
        children: [
          // Tutma kolu
          Center(
            child: Container(
              margin: EdgeInsets.only(top: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Başlık satırı
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.medical_information_rounded,
                  size: 28,
                  color: Color(0xFF1565C0),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'health_notes.doctor_view_title'.tr(),
                        style: textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'health_notes.doctor_view_subtitle'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () => Share.share(_buildClinicalText()),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'health_notes.report_share'.tr(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              children: [
                // ── Tansiyon trendi ──
                if (bpSysSpots.isNotEmpty) ...[
                  Text(
                    'health_notes.report_blood_pressure'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _LegendDot(color: Colors.red.shade600, label: 'Sistolik'),
                      SizedBox(width: AppSpacing.md),
                      _LegendDot(
                          color: Colors.blue.shade600, label: 'Diastolik'),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xs),
                  _HealthTrendChart(
                    spots: bpSysSpots,
                    color: Colors.red.shade600,
                    unit: 'mmHg',
                    spots2: bpDiaSpots.isNotEmpty ? bpDiaSpots : null,
                    color2: Colors.blue.shade600,
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],

                // ── Kan şekeri trendi ──
                if (glucoseSpots.isNotEmpty) ...[
                  Text(
                    'health_notes.report_glucose'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _HealthTrendChart(
                    spots: glucoseSpots,
                    color: Colors.amber.shade700,
                    unit: 'mg/dL',
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],

                // ── Ağrı takibi ──
                if (agri.isNotEmpty) ...[
                  Text(
                    'health_notes.pain_tracking'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  ...agri.take(5).map((n) {
                    final d =
                        '${n.date.day.toString().padLeft(2, '0')}.${n.date.month.toString().padLeft(2, '0')}';
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(d,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                )),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (n.painLevel ?? 0) / 10,
                              color: n.painLevel != null && n.painLevel! > 6
                                  ? Colors.red
                                  : n.painLevel != null && n.painLevel! > 3
                                      ? Colors.orange
                                      : Colors.green,
                              backgroundColor:
                                  colorScheme.onSurface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 8,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            '${n.painLevel ?? 0}/10',
                            style: textTheme.labelSmall,
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: AppSpacing.lg),
                ],

                // ── Semptom sıklığı ──
                if (symptomFreq.isNotEmpty) ...[
                  Text(
                    'health_notes.symptom_frequency'.tr(),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: symptomFreq
                        .map(
                          (e) => Chip(
                            label: Text('${e.key}  ×${e.value}'),
                            labelStyle: const TextStyle(fontSize: 13),
                          ),
                        )
                        .toList(),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],

                // Ölçüm yoksa bilgi mesajı
                if (bpSysSpots.isEmpty &&
                    glucoseSpots.isEmpty &&
                    agri.isEmpty &&
                    symptomFreq.isEmpty)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        'health_notes.no_measurements'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grafik lejant noktası.
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
