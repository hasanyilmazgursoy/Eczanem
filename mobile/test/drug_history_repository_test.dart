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
  });
}
