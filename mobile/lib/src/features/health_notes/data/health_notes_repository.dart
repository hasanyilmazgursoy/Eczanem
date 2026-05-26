import '../../../imports/imports.dart';
import 'models/health_note.dart';

/// Sağlık notlarını Hive üzerinde liste olarak yöneten repository.
///
/// FamilyRepository ile birebir aynı strateji: her not JSON string olarak
/// `StorageService.getStringList / setStringList` ile saklanır.
class HealthNotesRepository {
  HealthNotesRepository._();
  static final HealthNotesRepository instance = HealthNotesRepository._();

  static const _storageKey = 'health_notes_v1';

  /// Tüm notları döner — en yeni önce sıralı.
  List<HealthNote> getNotes() {
    final rawItems =
        StorageService.instance.getStringList(_storageKey) ?? const [];
    return rawItems.map(HealthNote.tryParse).whereType<HealthNote>().toList();
  }

  /// Belirli kategorideki notları döner.
  List<HealthNote> getNotesByCategory(String category) {
    return getNotes().where((n) => n.category == category).toList();
  }

  /// Yeni not ekler — listeye baş tarafa eklenir (en yeni önce).
  FutureEither<HealthNote> addNote({
    required DateTime date,
    required String category,
    required String text,
    String mood = '',
    int? systolic,
    int? diastolic,
    double? glucoseValue,
    int? painLevel,
    List<String> symptoms = const [],
    bool medicationTaken = false,
  }) async {
    return runTask(() async {
      final now = DateTime.now();
      final note = HealthNote(
        id: now.microsecondsSinceEpoch.toString(),
        date: date,
        category: category,
        text: text.trim(),
        mood: mood,
        createdAt: now,
        systolic: systolic,
        diastolic: diastolic,
        glucoseValue: glucoseValue,
        painLevel: painLevel,
        symptoms: symptoms,
        medicationTaken: medicationTaken,
      );

      final updated = [note, ...getNotes()];
      await _persist(updated);
      return note;
    });
  }

  /// Mevcut notu günceller.
  FutureEither<HealthNote> updateNote(HealthNote updated) async {
    return runTask(() async {
      final notes =
          getNotes().map((n) => n.id == updated.id ? updated : n).toList();
      await _persist(notes);
      return updated;
    });
  }

  /// Notu siler.
  FutureEither<void> removeNote(String id) async {
    return runTask(() async {
      final notes = getNotes().where((n) => n.id != id).toList();
      await _persist(notes);
    });
  }

  /// Tüm notları siler.
  FutureEither<void> clearAll() async {
    return runTask(() async {
      await StorageService.instance.remove(_storageKey);
    });
  }

  Future<void> _persist(List<HealthNote> notes) async {
    await StorageService.instance.setStringList(
      _storageKey,
      notes.map((n) => n.toJsonString()).toList(),
    );
  }
}
