import 'dart:convert';

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

    test('günde 1 doz için tek hatırlatma saati oluşur', () {
      final reminder = MedicationReminder.create(
        drugName: 'Vitamin D',
        reminderTime: const TimeOfDay(hour: 21, minute: 0),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 30,
      );

      expect(reminder.reminderTimes, hasLength(1));
      expect(
          reminder.reminderTimes.first, const TimeOfDay(hour: 21, minute: 0));
    });

    test('stockCount 0 ile oluşturulan hatırlatıcıda stok takibi olmaz', () {
      final reminder = MedicationReminder.create(
        drugName: 'Vitamin C',
        reminderTime: const TimeOfDay(hour: 8, minute: 0),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 0,
      );

      expect(reminder.hasStockTracking, isFalse);
      expect(reminder.isOutOfStock, isFalse);
      expect(reminder.remainingDays, isNull);
    });

    test('stok sıfıra düştüğünde isOutOfStock true döner', () {
      final full = MedicationReminder.create(
        drugName: 'Parol',
        reminderTime: const TimeOfDay(hour: 12, minute: 0),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 10,
      );

      // copyWith(stockCount:0) ile tüketilmiş durumu simüle et;
      // initialStockCount = max(10, 0) = 10 olarak korunur
      final depleted = full.copyWith(stockCount: 0);

      expect(depleted.hasStockTracking, isTrue);
      expect(depleted.isOutOfStock, isTrue);
    });

    test('stockProgress kalan stok oranını 0.0-1.0 aralığında döner', () {
      final full = MedicationReminder.create(
        drugName: 'Parol',
        reminderTime: const TimeOfDay(hour: 12, minute: 0),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 20,
      );

      expect(full.stockProgress, 1.0);

      // stockCount yarıya iner; initialStockCount = max(20, 10) = 20
      final half = full.copyWith(stockCount: 10);
      expect(half.stockProgress, 0.5);

      // stockCount sıfıra düşer; 0.0'a clamp edilmeli
      final empty = full.copyWith(stockCount: 0);
      expect(empty.stockProgress, 0.0);
    });

    test('tryParse bozuk veya boş JSON için null döner', () {
      expect(MedicationReminder.tryParse('{bozuk'), isNull);
      expect(MedicationReminder.tryParse(''), isNull);
      expect(MedicationReminder.tryParse('null'), isNull);
    });

    test('tryParse boş ilaç adı olan JSON için null döner', () {
      final raw = jsonEncode({
        'id': '1',
        'drug_name': '',
        'hour': 8,
        'minute': 0,
        'times_per_day': 1,
        'units_per_dose': 1,
        'stock_count': 0,
        'initial_stock_count': 0,
        'is_active': true,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      expect(MedicationReminder.tryParse(raw), isNull);
    });

    test('tryParse geçersiz hour/minute değerlerini geçerli aralığa sıkıştırır',
        () {
      final raw = jsonEncode({
        'id': '1',
        'drug_name': 'Test',
        'hour': 25, // clamp → 23
        'minute': 70, // clamp → 59
        'times_per_day': 1,
        'units_per_dose': 1,
        'stock_count': 5,
        'initial_stock_count': 5,
        'is_active': true,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });

      final reminder = MedicationReminder.tryParse(raw);

      expect(reminder, isNotNull);
      expect(reminder!.hour, 23);
      expect(reminder.minute, 59);
    });

    test('copyWith yalnızca belirtilen alanı günceller', () {
      final original = MedicationReminder.create(
        drugName: 'Aspirin',
        reminderTime: const TimeOfDay(hour: 8, minute: 30),
        timesPerDay: 1,
        unitsPerDose: 1,
        stockCount: 10,
        notes: 'Tok karnına',
      );

      final updated = original.copyWith(drugName: 'Coraspin');

      expect(updated.drugName, 'Coraspin');
      expect(updated.hour, original.hour);
      expect(updated.minute, original.minute);
      expect(updated.timesPerDay, original.timesPerDay);
      expect(updated.stockCount, original.stockCount);
      expect(updated.notes, original.notes); // diğer alanlar değişmemeli
    });
  });
}
