import 'package:eczanem/src/features/health_notes/data/models/health_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthNote', () {
    test('json roundtrip tüm alanları korur', () {
      final now = DateTime(2026, 5, 12, 10, 30);
      final note = HealthNote(
        id: '123456',
        date: now,
        category: HealthNoteCategory.tansiyon,
        text: 'Sabah tansiyonum 140/90 ölçüldü.',
        mood: HealthNoteMood.orta,
        createdAt: now,
      );

      final restored = HealthNote.tryParse(note.toJsonString());

      expect(restored, isNotNull);
      expect(restored!.id, '123456');
      expect(restored.category, HealthNoteCategory.tansiyon);
      expect(restored.text, 'Sabah tansiyonum 140/90 ölçüldü.');
      expect(restored.mood, HealthNoteMood.orta);
      expect(restored.date.year, 2026);
      expect(restored.date.month, 5);
      expect(restored.date.day, 12);
    });

    test('tryParse bozuk JSON için null döner', () {
      expect(HealthNote.tryParse('{geçersiz json'), isNull);
      expect(HealthNote.tryParse(''), isNull);
      expect(HealthNote.tryParse('null'), isNull);
    });

    test('mood alanı eksik JSON varsayılan boş string ile parse edilir', () {
      const rawNoMood = '{"id":"1","date":"2026-01-01T00:00:00.000",'
          '"category":"genel","text":"test","created_at":"2026-01-01T00:00:00.000"}';

      final note = HealthNote.tryParse(rawNoMood);

      expect(note, isNotNull);
      expect(note!.mood, isEmpty);
    });

    test('category eksik JSON varsayılan genel ile parse edilir', () {
      const rawNoCategory =
          '{"id":"2","date":"2026-01-01T00:00:00.000","text":"test",'
          '"mood":"","created_at":"2026-01-01T00:00:00.000"}';

      final note = HealthNote.tryParse(rawNoCategory);

      expect(note, isNotNull);
      expect(note!.category, HealthNoteCategory.genel);
    });

    test('copyWith yalnızca belirtilen alanı günceller', () {
      final original = HealthNote(
        id: 'abc',
        date: DateTime(2026, 1, 1),
        category: HealthNoteCategory.agri,
        text: 'Başım ağrıyor.',
        createdAt: DateTime(2026, 1, 1),
      );

      final updated = original.copyWith(text: 'Başağrısı geçti.');

      expect(updated.id, original.id);
      expect(updated.category, original.category);
      expect(updated.text, 'Başağrısı geçti.');
    });
  });

  group('HealthNoteCategory', () {
    test('iconFor bilinen kategoriler için doğru emoji döner', () {
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.tansiyon), '🩺');
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.seker), '🍬');
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.agri), '🤕');
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.psikoloji), '🧠');
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.diger), '📋');
    });

    test('iconFor bilinmeyen kategori için genel emoji döner', () {
      expect(HealthNoteCategory.iconFor('bilinmeyen'), '📝');
      expect(HealthNoteCategory.iconFor(HealthNoteCategory.genel), '📝');
    });

    test('all listesi tüm kategorileri içerir', () {
      expect(HealthNoteCategory.all, hasLength(6));
      expect(HealthNoteCategory.all, contains(HealthNoteCategory.genel));
      expect(HealthNoteCategory.all, contains(HealthNoteCategory.tansiyon));
    });
  });

  group('HealthNoteMood', () {
    test('all listesi tüm mood seçeneklerini içerir', () {
      expect(HealthNoteMood.all, hasLength(6));
      expect(HealthNoteMood.all, contains(HealthNoteMood.iyi));
      expect(HealthNoteMood.all, contains(HealthNoteMood.hasta));
    });
  });
}
