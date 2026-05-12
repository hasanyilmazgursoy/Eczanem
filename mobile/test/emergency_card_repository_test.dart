import 'package:eczanem/src/features/emergency/data/models/emergency_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmergencyCard', () {
    test('json roundtrip tüm alanları korur', () {
      final card = EmergencyCard(
        bloodType: 'A Rh+',
        allergies: ['Penisilin', 'Aspirin'],
        chronicConditions: ['Diyabet Tip 2', 'Hipertansiyon'],
        currentMedications: ['Metformin 500mg', 'Lisinopril 10mg'],
        emergencyContactName: 'Ayşe Yılmaz',
        emergencyContactPhone: '+905551234567',
        doctorName: 'Dr. Mehmet Kaya',
        doctorPhone: '+905559876543',
        notes: 'İnsülin taşıyorum.',
        updatedAt: DateTime(2026, 5, 12, 9, 0),
      );

      final restored = EmergencyCard.tryParse(card.toJsonString());

      expect(restored, isNotNull);
      expect(restored!.bloodType, 'A Rh+');
      expect(restored.allergies, ['Penisilin', 'Aspirin']);
      expect(restored.chronicConditions, ['Diyabet Tip 2', 'Hipertansiyon']);
      expect(restored.currentMedications,
          ['Metformin 500mg', 'Lisinopril 10mg']);
      expect(restored.emergencyContactName, 'Ayşe Yılmaz');
      expect(restored.emergencyContactPhone, '+905551234567');
      expect(restored.doctorName, 'Dr. Mehmet Kaya');
      expect(restored.notes, 'İnsülin taşıyorum.');
      expect(restored.updatedAt.year, 2026);
    });

    test('tryParse bozuk JSON için null döner', () {
      expect(EmergencyCard.tryParse('{bozuk'), isNull);
      expect(EmergencyCard.tryParse(''), isNull);
    });

    test('liste alanları eksik JSON boş liste ile parse edilir', () {
      const raw =
          '{"blood_type":"B Rh-","updated_at":"2026-01-01T00:00:00.000"}';

      final card = EmergencyCard.tryParse(raw);

      expect(card, isNotNull);
      expect(card!.allergies, isEmpty);
      expect(card.chronicConditions, isEmpty);
      expect(card.currentMedications, isEmpty);
    });

    test('isEmpty hiç veri girilmemişse true döner', () {
      final empty = EmergencyCard(updatedAt: DateTime.now());
      expect(empty.isEmpty, isTrue);
    });

    test('isEmpty herhangi bir alan doluysa false döner', () {
      final card = EmergencyCard(
        bloodType: '0 Rh+',
        updatedAt: DateTime.now(),
      );
      expect(card.isEmpty, isFalse);
    });

    test('copyWith yalnızca belirtilen alanı günceller', () {
      final original = EmergencyCard(
        bloodType: 'AB Rh+',
        allergies: ['Polen'],
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(bloodType: '0 Rh-');

      expect(updated.bloodType, '0 Rh-');
      expect(updated.allergies, ['Polen']); // diğer alanlar değişmemeli
    });
  });
}
