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
    if (result == true) _load();
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

// ════════════════════════ KATEGORİ FİLTRE ÇUBUĞU ═══════════════════════

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

// ═════════════════════════════ NOT KARTI ════════════════════════════

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

// ════════════════════════ NOT EDİTÖR BOTTOM SHEET ══════════════════════════

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

// ══════════════════════════════ BOŞ DURUM ════════════════════════════════

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
