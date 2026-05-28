import 'package:eczanem/src/features/drug/data/drug_history_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DrugScanHistoryEntry', () {
    test('medicine payload adaylardan candidate bilgisini çıkarır', () {
      final entry = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.medicine,
        payload: {
          'ilac_adi': 'Aspirin',
          'etken_madde': 'Asetilsalisilik asit',
          'aday_ilaclar': ['Aspirin', 'Coraspin'],
        },
      );

      expect(entry.title, 'Aspirin');
      expect(entry.subtitle, 'Asetilsalisilik asit');
      expect(entry.hasCandidates, isTrue);
    });

    test('json roundtrip entry bilgisini korur', () {
      final original = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.prospectus,
        payload: {
          'ilac_adi': 'Majezik',
          'prospektus_turu': 'Kullanma talimatı',
        },
      );

      final restored = DrugScanHistoryEntry.tryParse(original.toJsonString());

      expect(restored, isNotNull);
      expect(restored!.mode, DrugScanHistoryMode.prospectus);
      expect(restored.title, 'Majezik');
      expect(restored.subtitle, 'Kullanma talimatı');
      expect(restored.hasCandidates, isFalse);
    });

    test('fromPayload ilac_adi boşsa medicine için bilinmeyen ilaç fallback kullanır', () {
      final entry = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.medicine,
        payload: {'etken_madde': 'bilinmiyor'},
      );

      expect(entry.title, 'Bilinmeyen İlaç');
      expect(entry.subtitle, 'bilinmiyor');
    });

    test('fromPayload ilac_adi boşsa prospektüs için varsayılan başlık kullanır', () {
      final entry = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.prospectus,
        payload: {'prospektus_turu': 'Kullanma talimatı'},
      );

      expect(entry.title, 'Prospektüs Özeti');
      expect(entry.subtitle, 'Kullanma talimatı');
    });

    // Adaylar birincil ilaçla aynıysa (case-insensitive) hasCandidates false olmalı
    test('hasCandidates adaylar yalnızca birincil ilaçla eşleşiyorsa false döner', () {
      final entry = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.medicine,
        payload: {
          'ilac_adi': 'Aspirin',
          'aday_ilaclar': ['Aspirin', 'ASPIRIN'],
        },
      );

      expect(entry.hasCandidates, isFalse);
    });

    test('hasCandidates prospektüs modunda her zaman false döner', () {
      final entry = DrugScanHistoryEntry.fromPayload(
        mode: DrugScanHistoryMode.prospectus,
        payload: {
          'ilac_adi': 'Augmentin',
          'aday_ilaclar': ['Augmentin', 'Amoksisilin'],
        },
      );

      expect(entry.hasCandidates, isFalse);
    });

    test('tryParse bozuk veya boş JSON için null döner', () {
      expect(DrugScanHistoryEntry.tryParse('{bozuk'), isNull);
      expect(DrugScanHistoryEntry.tryParse(''), isNull);
      expect(DrugScanHistoryEntry.tryParse('null'), isNull);
    });
  });
}
