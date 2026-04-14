import 'package:eczanem/src/features/reminder/data/medication_reminder_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MedicationReminder', () {
    test('json roundtrip stock ve zaman bilgisini korur', () {
      final reminder = MedicationReminder.create(
        drugName: 'Aspirin',
        reminderTime: const TimeOfDay(hour: 8, minute: 30),
        timesPerDay: 2,
        unitsPerDose: 1,
        stockCount: 20,
        notes: 'Tok karnına',
      );

      final restored = MedicationReminder.tryParse(reminder.toJsonString());

      expect(restored, isNotNull);
      expect(restored!.drugName, 'Aspirin');
      expect(restored.hour, 8);
      expect(restored.minute, 30);
      expect(restored.timesPerDay, 2);
      expect(restored.unitsPerDose, 1);
      expect(restored.stockCount, 20);
      expect(restored.notes, 'Tok karnına');
    });

    test('remainingDays günlük tüketime göre hesaplanır', () {
      final reminder = MedicationReminder.create(
        drugName: 'Majezik',
        reminderTime: const TimeOfDay(hour: 9, minute: 0),
        timesPerDay: 2,
        unitsPerDose: 2,
        stockCount: 16,
      );

      expect(reminder.dailyUsage, 4);
      expect(reminder.remainingDays, 4);
      expect(reminder.isLowStock, isFalse);
    });

    test('düşük stok eşiği üç gün ve altıdır', () {
      final reminder = MedicationReminder.create(
        drugName: 'Coraspin',
        reminderTime: const TimeOfDay(hour: 21, minute: 0),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 3,
      );

      expect(reminder.remainingDays, 3);
      expect(reminder.isLowStock, isTrue);
      expect(reminder.isOutOfStock, isFalse);
    });

    test('günlük tekrar saatleri seçilen saate göre dengeli dağılır', () {
      final reminder = MedicationReminder.create(
        drugName: 'Augmentin',
        reminderTime: const TimeOfDay(hour: 9, minute: 15),
        timesPerDay: 3,
        unitsPerDose: 1,
        stockCount: 12,
      );

      expect(
        reminder.reminderTimes,
        const [
          TimeOfDay(hour: 9, minute: 15),
          TimeOfDay(hour: 17, minute: 15),
          TimeOfDay(hour: 1, minute: 15),
        ],
      );
    });
  });
}
