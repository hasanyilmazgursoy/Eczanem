import 'dart:convert';
import 'dart:math' as math;

import '../../../imports/imports.dart';

/// Hatırlatıcı ve stok takibi verisini yerel depolamada yöneten katman.
class MedicationReminderRepository {
  MedicationReminderRepository._();
  static final MedicationReminderRepository instance =
      MedicationReminderRepository._();

  static const _storageKey = 'medication_reminders_v1';

  List<MedicationReminder> getReminders() {
    final rawItems =
        StorageService.instance.getStringList(_storageKey) ?? const [];
    final reminders = rawItems
        .map(MedicationReminder.tryParse)
        .whereType<MedicationReminder>()
        .toList();

    reminders.sort(_sortByPriority);
    return reminders;
  }

  FutureEither<void> saveReminder(MedicationReminder reminder) async {
    final updated = [
      reminder.copyWith(updatedAt: DateTime.now()),
      ...getReminders().where((item) => item.id != reminder.id),
    ];

    updated.sort(_sortByPriority);
    return _persist(updated);
  }

  FutureEither<void> removeReminder(String id) async {
    final updated = getReminders().where((item) => item.id != id).toList();
    return _persist(updated);
  }

  FutureEither<void> toggleReminder(String id, bool isActive) async {
    final updated = getReminders()
        .map(
          (item) => item.id == id
              ? item.copyWith(isActive: isActive, updatedAt: DateTime.now())
              : item,
        )
        .toList();

    updated.sort(_sortByPriority);
    return _persist(updated);
  }

  FutureEither<void> takeDose(String id) async {
    final updated = getReminders().map((item) {
      if (item.id != id) return item;

      final nextStock = item.hasStockTracking
          ? math.max(item.stockCount - item.unitsPerDose, 0)
          : item.stockCount;

      return item.copyWith(
        isActive: nextStock > 0 || !item.hasStockTracking,
        stockCount: nextStock,
        lastTakenAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    updated.sort(_sortByPriority);
    return _persist(updated);
  }

  int getActiveCount() => getReminders().where((item) => item.isActive).length;

  int getLowStockCount() => getReminders()
      .where((item) => item.hasStockTracking && item.isLowStock)
      .length;

  FutureEither<void> _persist(List<MedicationReminder> reminders) async {
    if (reminders.isEmpty) {
      return StorageService.instance.remove(_storageKey);
    }

    return StorageService.instance.setStringList(
      _storageKey,
      reminders.map((item) => item.toJsonString()).toList(),
    );
  }

  int _sortByPriority(MedicationReminder a, MedicationReminder b) {
    if (a.isActive != b.isActive) {
      return a.isActive ? -1 : 1;
    }

    if (a.isLowStock != b.isLowStock) {
      return a.isLowStock ? -1 : 1;
    }

    final hourCompare = a.hour.compareTo(b.hour);
    if (hourCompare != 0) return hourCompare;

    final minuteCompare = a.minute.compareTo(b.minute);
    if (minuteCompare != 0) return minuteCompare;

    return a.drugName.toLowerCase().compareTo(b.drugName.toLowerCase());
  }
}

class MedicationReminder extends Equatable {
  const MedicationReminder({
    required this.id,
    required this.drugName,
    required this.hour,
    required this.minute,
    required this.timesPerDay,
    required this.unitsPerDose,
    required this.stockCount,
    required this.initialStockCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.lastTakenAt,
  });

  final String id;
  final String drugName;
  final int hour;
  final int minute;
  final int timesPerDay;
  final int unitsPerDose;
  final int stockCount;
  final int initialStockCount;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastTakenAt;

  factory MedicationReminder.create({
    required String drugName,
    required TimeOfDay reminderTime,
    required int timesPerDay,
    required int unitsPerDose,
    required int stockCount,
    String? notes,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return MedicationReminder(
      id: now.microsecondsSinceEpoch.toString(),
      drugName: drugName.trim(),
      hour: reminderTime.hour,
      minute: reminderTime.minute,
      timesPerDay: timesPerDay,
      unitsPerDose: unitsPerDose,
      stockCount: math.max(stockCount, 0),
      initialStockCount: math.max(stockCount, 0),
      isActive: isActive,
      notes: _normalizeNote(notes),
      createdAt: now,
      updatedAt: now,
    );
  }

  MedicationReminder copyWith({
    String? id,
    String? drugName,
    int? hour,
    int? minute,
    int? timesPerDay,
    int? unitsPerDose,
    int? stockCount,
    int? initialStockCount,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastTakenAt,
    bool keepPreviousLastTakenAt = true,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      drugName: (drugName ?? this.drugName).trim(),
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      timesPerDay: timesPerDay ?? this.timesPerDay,
      unitsPerDose: unitsPerDose ?? this.unitsPerDose,
      stockCount: math.max(stockCount ?? this.stockCount, 0),
      initialStockCount: math.max(
        initialStockCount ?? this.initialStockCount,
        stockCount ?? this.stockCount,
      ),
      isActive: isActive ?? this.isActive,
      notes: _normalizeNote(notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastTakenAt: keepPreviousLastTakenAt
          ? (lastTakenAt ?? this.lastTakenAt)
          : lastTakenAt,
    );
  }

  TimeOfDay get reminderTime => TimeOfDay(hour: hour, minute: minute);

  /// Tek bir saat seçimi üzerinden gün içine dengeli biçimde dağıtılmış doz saatleri.
  ///
  /// Örn. günde 2 kez için seçilen saat 09:00 ise ikinci hatırlatma 21:00 olur.
  List<TimeOfDay> get reminderTimes {
    final intervalInMinutes = (24 * 60) ~/ math.max(timesPerDay, 1);

    return List.generate(timesPerDay, (index) {
      final totalMinutes = (hour * 60) + minute + (intervalInMinutes * index);
      final normalizedMinutes = totalMinutes % (24 * 60);

      return TimeOfDay(
        hour: normalizedMinutes ~/ 60,
        minute: normalizedMinutes % 60,
      );
    });
  }

  int get dailyUsage => unitsPerDose * timesPerDay;

  bool get hasStockTracking => initialStockCount > 0;

  double? get remainingDays {
    if (!hasStockTracking || dailyUsage <= 0) return null;
    return stockCount / dailyUsage;
  }

  bool get isLowStock {
    final days = remainingDays;
    return days != null && days <= 3;
  }

  bool get isOutOfStock => hasStockTracking && stockCount <= 0;

  double get stockProgress {
    if (!hasStockTracking || initialStockCount <= 0) return 0;
    final rawValue = stockCount / initialStockCount;
    return rawValue.clamp(0, 1).toDouble();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'drug_name': drugName,
      'hour': hour,
      'minute': minute,
      'times_per_day': timesPerDay,
      'units_per_dose': unitsPerDose,
      'stock_count': stockCount,
      'initial_stock_count': initialStockCount,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_taken_at': lastTakenAt?.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static MedicationReminder? tryParse(String rawValue) {
    try {
      final json = jsonDecode(rawValue);
      if (json is! Map<String, dynamic>) return null;

      final drugName = (json['drug_name'] ?? '').toString().trim();
      if (drugName.isEmpty) return null;

      final hour = _readInt(json['hour']);
      final minute = _readInt(json['minute']);
      final timesPerDay =
          math.max(_readInt(json['times_per_day'], fallback: 1), 1);
      final unitsPerDose =
          math.max(_readInt(json['units_per_dose'], fallback: 1), 1);
      final stockCount = math.max(_readInt(json['stock_count']), 0);
      final initialStockCount = math.max(
        _readInt(json['initial_stock_count'], fallback: stockCount),
        stockCount,
      );

      return MedicationReminder(
        id: (json['id'] ?? '').toString(),
        drugName: drugName,
        hour: hour.clamp(0, 23),
        minute: minute.clamp(0, 59),
        timesPerDay: timesPerDay,
        unitsPerDose: unitsPerDose,
        stockCount: stockCount,
        initialStockCount: initialStockCount,
        isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
        notes: _normalizeNote(json['notes']?.toString()),
        createdAt: _readDateTime(json['created_at']) ?? DateTime.now(),
        updatedAt: _readDateTime(json['updated_at']) ?? DateTime.now(),
        lastTakenAt: _readDateTime(json['last_taken_at']),
      );
    } catch (_) {
      return null;
    }
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _readDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _normalizeNote(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
        id,
        drugName,
        hour,
        minute,
        timesPerDay,
        unitsPerDose,
        stockCount,
        initialStockCount,
        isActive,
        notes,
        createdAt,
        updatedAt,
        lastTakenAt,
      ];
}
