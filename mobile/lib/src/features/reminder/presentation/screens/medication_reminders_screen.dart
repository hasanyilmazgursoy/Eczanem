import 'dart:math' as math;

import '../../../../imports/imports.dart';
import '../../../drug/data/drug_history_repository.dart';
import '../../data/medication_reminder_repository.dart';

class MedicationRemindersScreen extends StatefulWidget {
  const MedicationRemindersScreen({super.key, this.initialDrugName});

  final String? initialDrugName;

  @override
  State<MedicationRemindersScreen> createState() =>
      _MedicationRemindersScreenState();
}

class _MedicationRemindersScreenState extends State<MedicationRemindersScreen> {
  List<MedicationReminder> _reminders = const [];
  bool _didHandleInitialDrug = false;
  bool _notificationPermissionGranted = true;

  @override
  void initState() {
    super.initState();
    _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleInitialDrug();
      _prepareNotifications();
    });
  }

  Future<void> _prepareNotifications() async {
    final result =
        await NotificationService.instance.requestReminderPermissions();

    if (!mounted) return;

    result.fold(
      (_) => setState(() => _notificationPermissionGranted = false),
      (granted) {
        setState(() => _notificationPermissionGranted = granted);

        if (granted) {
          _reloadAndSyncNotifications();
        }

        if (!granted) {
          context.showTypedSnackBar(
            'medication_reminder.notifications_disabled'.tr(),
            type: SnackBarType.info,
          );
        }
      },
    );
  }

  void _handleInitialDrug() {
    final initialDrugName = widget.initialDrugName?.trim();
    if (_didHandleInitialDrug ||
        initialDrugName == null ||
        initialDrugName.isEmpty) {
      return;
    }

    _didHandleInitialDrug = true;
    _openEditor(initialDrugName: initialDrugName);
  }

  void _load() {
    setState(() {
      _reminders = MedicationReminderRepository.instance.getReminders();
    });
  }

  Future<void> _reloadAndSyncNotifications() async {
    final latest = MedicationReminderRepository.instance.getReminders();
    setState(() => _reminders = latest);
    await NotificationService.instance.syncMedicationReminders(latest);
  }

  Future<void> _openNotificationSettings() async {
    final result = await PermissionService.instance.openSettings();
    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {},
    );
  }

  Future<void> _openEditor({
    MedicationReminder? existing,
    String? initialDrugName,
  }) async {
    final createdOrUpdated = await showModalBottomSheet<MedicationReminder>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ReminderEditorSheet(
        existing: existing,
        initialDrugName: initialDrugName,
      ),
    );

    if (createdOrUpdated == null || !mounted) return;

    final result = await MedicationReminderRepository.instance
        .saveReminder(createdOrUpdated);

    result.fold(
      (failure) {
        context.showTypedSnackBar(
          failure.message,
          type: SnackBarType.error,
        );
      },
      (_) {
        _reloadAndSyncNotifications().then((_) {
          if (!mounted) return;

          context.showTypedSnackBar(
            existing == null
                ? 'medication_reminder.saved_message'.tr()
                : 'medication_reminder.updated_message'.tr(),
            type: SnackBarType.success,
          );

          if (!_notificationPermissionGranted) {
            context.showTypedSnackBar(
              'medication_reminder.notifications_disabled'.tr(),
              type: SnackBarType.info,
            );
          }
        });
      },
    );
  }

  Future<void> _toggleReminder(MedicationReminder reminder, bool value) async {
    final result = await MedicationReminderRepository.instance
        .toggleReminder(reminder.id, value);

    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) => _reloadAndSyncNotifications(),
    );
  }

  Future<void> _takeDose(MedicationReminder reminder) async {
    final result =
        await MedicationReminderRepository.instance.takeDose(reminder.id);

    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _reloadAndSyncNotifications().then((_) {
          if (!mounted) return;

          context.showTypedSnackBar(
            'medication_reminder.taken_message'.tr(args: [reminder.drugName]),
            type: SnackBarType.success,
          );
        });
      },
    );
  }

  Future<void> _deleteReminder(MedicationReminder reminder) async {
    final result =
        await MedicationReminderRepository.instance.removeReminder(reminder.id);

    if (!mounted) return;

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _reloadAndSyncNotifications().then((_) {
          if (!mounted) return;

          context.showTypedSnackBar(
            'medication_reminder.deleted_message'.tr(),
            type: SnackBarType.success,
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppBorders.card,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.alarm_on_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'medication_reminder.hero_title'.tr(),
            style: context.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '\ tane aktif hatırlatıcınız var.',
            style: context.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({
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
    return AppCard(
      showShadow: true,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onTakeDose,
  });

  final MedicationReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTakeDose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final remainingDays = reminder.remainingDays;
    final stockColor = reminder.isOutOfStock
        ? colorScheme.error
        : reminder.isLowStock
            ? Colors.orange.shade700
            : Colors.teal;

    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (reminder.isActive
                          ? colorScheme.primary
                          : colorScheme.outline)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  reminder.isActive
                      ? Icons.alarm_on_rounded
                      : Icons.alarm_off_rounded,
                  color: reminder.isActive
                      ? colorScheme.primary
                      : colorScheme.outline,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.drugName,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      _buildSubtitle(context, reminder),
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: reminder.isActive,
                onChanged: onToggle,
              ),
            ],
          ),
          if (reminder.notes != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reminder.notes!,
                style: context.textTheme.bodySmall,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetaChip(
                icon: Icons.schedule_rounded,
                label: _formatTimes(context, reminder.reminderTimes),
              ),
              _MetaChip(
                icon: Icons.repeat_rounded,
                label: 'medication_reminder.times_per_day_value'
                    .tr(args: [reminder.timesPerDay.toString()]),
              ),
              _MetaChip(
                icon: Icons.medication_liquid_outlined,
                label: 'medication_reminder.units_per_dose_value'
                    .tr(args: [reminder.unitsPerDose.toString()]),
              ),
            ],
          ),
          if (reminder.hasStockTracking) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    reminder.isOutOfStock
                        ? 'medication_reminder.out_of_stock'.tr()
                        : 'medication_reminder.stock_remaining'.tr(
                            args: [reminder.stockCount.toString()],
                          ),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (remainingDays != null)
                  Text(
                    'medication_reminder.remaining_days'.tr(
                      args: [remainingDays.toStringAsFixed(1)],
                    ),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: stockColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: reminder.stockProgress,
                minHeight: 10,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(stockColor),
              ),
            ),
            if (reminder.lastTakenAt != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                'medication_reminder.last_taken'.tr(
                  args: [_formatDateTime(context, reminder.lastTakenAt!)],
                ),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
          SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text('medication_reminder.edit_button'.tr()),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'medication_reminder.take_now_button'.tr(),
                      onPressed: onTakeDose,
                      isFullWidth: true,
                      prefixIcon:
                          const Icon(Icons.check_circle_outline_rounded),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'medication_reminder.delete_tooltip'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _buildSubtitle(
    BuildContext context,
    MedicationReminder reminder,
  ) {
    final statusKey = reminder.isActive
        ? 'medication_reminder.status_active'
        : 'medication_reminder.status_paused';
    return '${statusKey.tr()} · ${'medication_reminder.times_per_day_value'.tr(args: [
          reminder.timesPerDay.toString()
        ])}';
  }

  static String _formatTime(BuildContext context, TimeOfDay time) {
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  static String _formatTimes(
    BuildContext context,
    List<TimeOfDay> times,
  ) {
    return times.map((time) => _formatTime(context, time)).join(' · ');
  }

  static String _formatDateTime(BuildContext context, DateTime value) {
    final localDate = value.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatShortDate(localDate)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localDate))}';
  }
}

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              color: Colors.orange,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'medication_reminder.notifications_title'.tr(),
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  'medication_reminder.notifications_disabled'.tr(),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(
                      'medication_reminder.notifications_settings'.tr(),
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

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.colors.onSurfaceVariant),
          SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      showShadow: true,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.alarm_add_rounded,
                size: 36,
                color: context.colors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'medication_reminder.empty_title'.tr(),
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'medication_reminder.empty_subtitle'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'medication_reminder.add_button'.tr(),
              onPressed: onAddPressed,
              prefixIcon: const Icon(Icons.add_alarm_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderEditorSheet extends StatefulWidget {
  const _ReminderEditorSheet({this.existing, this.initialDrugName});

  final MedicationReminder? existing;
  final String? initialDrugName;

  @override
  State<_ReminderEditorSheet> createState() => _ReminderEditorSheetState();
}

class _ReminderEditorSheetState extends State<_ReminderEditorSheet> {
  late final TextEditingController _drugController;
  late final TextEditingController _stockController;
  late final TextEditingController _notesController;

  late TimeOfDay _time;
  late int _timesPerDay;
  late int _unitsPerDose;
  late bool _isActive;
  String? _error;

  List<String> get _suggestions =>
      DrugHistoryRepository.instance.getSuggestedDrugNames().take(6).toList();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _drugController = TextEditingController(
      text: existing?.drugName ?? widget.initialDrugName ?? '',
    );
    _stockController = TextEditingController(
      text: existing?.stockCount.toString() ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _time = existing?.reminderTime ?? const TimeOfDay(hour: 9, minute: 0);
    _timesPerDay = existing?.timesPerDay ?? 1;
    _unitsPerDose = existing?.unitsPerDose ?? 1;
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _drugController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );

    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  void _submit() {
    final drugName = _drugController.text.trim();
    if (drugName.isEmpty) {
      setState(() => _error = 'medication_reminder.validation_drug_name'.tr());
      return;
    }

    final stockCount = int.tryParse(_stockController.text.trim()) ?? 0;
    final existing = widget.existing;

    final reminder = (existing ??
            MedicationReminder.create(
              drugName: drugName,
              reminderTime: _time,
              timesPerDay: _timesPerDay,
              unitsPerDose: _unitsPerDose,
              stockCount: stockCount,
              notes: _notesController.text,
              isActive: _isActive,
            ))
        .copyWith(
      drugName: drugName,
      hour: _time.hour,
      minute: _time.minute,
      timesPerDay: _timesPerDay,
      unitsPerDose: _unitsPerDose,
      stockCount: stockCount,
      initialStockCount: math.max(
        stockCount,
        existing?.initialStockCount ?? 0,
      ),
      notes: _notesController.text,
      isActive: _isActive,
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(reminder);
  }

  @override
  Widget build(BuildContext context) {
    final titleKey = widget.existing == null
        ? 'medication_reminder.add_title'
        : 'medication_reminder.edit_title';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titleKey.tr(),
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'medication_reminder.editor_subtitle'.tr(),
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _drugController,
              hint: 'medication_reminder.drug_name_hint'.tr(),
              textInputAction: TextInputAction.next,
            ),
            if (_suggestions.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _suggestions
                    .map(
                      (drug) => ActionChip(
                        label: Text(drug),
                        avatar: const Icon(Icons.history, size: 18),
                        onPressed: () {
                          _drugController.text = drug;
                          setState(() => _error = null);
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    title: 'medication_reminder.time_label'.tr(),
                    value: MaterialLocalizations.of(context)
                        .formatTimeOfDay(_time),
                    icon: Icons.schedule_rounded,
                    onTap: _pickTime,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _timesPerDay,
                    decoration: InputDecoration(
                      labelText: 'medication_reminder.times_per_day_label'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: List.generate(
                      6,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          'medication_reminder.times_per_day_value'
                              .tr(args: [(index + 1).toString()]),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _timesPerDay = value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'medication_reminder.schedule_preview'.tr(
                  args: [
                    _ReminderCard._formatTimes(
                      context,
                      MedicationReminder.create(
                        drugName: _drugController.text.isEmpty
                            ? 'preview'
                            : _drugController.text,
                        reminderTime: _time,
                        timesPerDay: _timesPerDay,
                        unitsPerDose: _unitsPerDose,
                        stockCount:
                            int.tryParse(_stockController.text.trim()) ?? 0,
                        isActive: _isActive,
                      ).reminderTimes,
                    ),
                  ],
                ),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _unitsPerDose,
                    decoration: InputDecoration(
                      labelText:
                          'medication_reminder.units_per_dose_label'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: List.generate(
                      4,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          'medication_reminder.units_per_dose_value'
                              .tr(args: [(index + 1).toString()]),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _unitsPerDose = value);
                    },
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'medication_reminder.stock_label'.tr(),
                      hintText: '30',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SwitchListTile.adaptive(
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              title: Text('medication_reminder.status_switch'.tr()),
              subtitle: Text('medication_reminder.status_switch_subtitle'.tr()),
              onChanged: (value) => setState(() => _isActive = value),
            ),
            SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'medication_reminder.notes_label'.tr(),
                hintText: 'medication_reminder.notes_hint'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (_error != null) ...[
              SizedBox(height: AppSpacing.md),
              AppErrorWidget(
                title: 'medication_reminder.error_title'.tr(),
                message: _error!,
              ),
            ],
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: titleKey.tr(),
              onPressed: _submit,
              isFullWidth: true,
              prefixIcon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: context.colors.primary),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
