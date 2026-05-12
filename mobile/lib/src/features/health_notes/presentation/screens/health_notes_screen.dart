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
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedMood;
  AppStatus _status = AppStatus.initial;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _textCtrl = TextEditingController(text: existing?.text ?? '');
    _selectedDate = existing?.date ?? DateTime.now();
    _selectedCategory = existing?.category ?? HealthNoteCategory.genel;
    _selectedMood = existing?.mood ?? HealthNoteMood.iyi;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
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

    final Either<Failure, HealthNote> result;

    if (widget.existing != null) {
      final updated = widget.existing!.copyWith(
        date: _selectedDate,
        category: _selectedCategory,
        text: _textCtrl.text,
        mood: _selectedMood,
      );
      result = await HealthNotesRepository.instance.updateNote(updated);
    } else {
      result = await HealthNotesRepository.instance.addNote(
        date: _selectedDate,
        category: _selectedCategory,
        text: _textCtrl.text,
        mood: _selectedMood,
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

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
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
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                  '${HealthNoteCategory.iconFor(cat)} ${"health_notes.category_$cat".tr()}',
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor: const Color(0xFF1565C0),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          SizedBox(height: AppSpacing.md),
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
            label:
                isEdit ? 'health_notes.update'.tr() : 'health_notes.save'.tr(),
            color: const Color(0xFF1565C0),
            isFullWidth: true,
          ),
        ],
      ),
    );
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
            const Text('📋', style: TextStyle(fontSize: 72)),
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
