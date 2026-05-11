import '../../../imports/imports.dart';
import 'models/family_member.dart';

/// Aile üyesi verisini Hive'da yerel olarak yöneten katman.
///
/// Hatırlatıcı repository'si ile aynı stratejiyi izler: her üye JSON string
/// olarak `StorageService` üzerinden saklanır.
class FamilyRepository {
  FamilyRepository._();
  static final FamilyRepository instance = FamilyRepository._();

  static const _storageKey = 'family_members_v1';

  /// Benzersiz ID üretimi — reminder repository ile aynı strateji.
  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  List<FamilyMember> getMembers() {
    final rawItems =
        StorageService.instance.getStringList(_storageKey) ?? const [];
    return rawItems
        .map(FamilyMember.tryParse)
        .whereType<FamilyMember>()
        .toList();
  }

  FutureEither<FamilyMember> addMember({
    required String name,
    required String relationship,
    required String emoji,
    int? age,
  }) async {
    final now = DateTime.now();
    final member = FamilyMember(
      id: _newId(),
      name: name.trim(),
      relationship: relationship.trim(),
      emoji: emoji,
      age: age,
      createdAt: now,
      updatedAt: now,
    );

    final updated = [member, ...getMembers()];
    final result = await _persist(updated);
    return result.fold(left, (_) => right(member));
  }

  FutureEither<FamilyMember> updateMember(FamilyMember updated) async {
    final members = getMembers()
        .map((m) => m.id == updated.id
            ? updated.copyWith(updatedAt: DateTime.now())
            : m)
        .toList();

    final result = await _persist(members);
    return result.fold(
      left,
      (_) => right(members.firstWhere((m) => m.id == updated.id)),
    );
  }

  FutureEither<void> removeMember(String id) async {
    final updated = getMembers().where((m) => m.id != id).toList();
    return _persist(updated);
  }

  FutureEither<FamilyMemberDrug> addDrug({
    required String memberId,
    required String drugName,
    String dosage = '',
    String frequency = '',
    String notes = '',
  }) async {
    final members = getMembers();
    final idx = members.indexWhere((m) => m.id == memberId);
    if (idx == -1) {
      return left(const CacheFailure('Aile üyesi bulunamadı.'));
    }

    final drug = FamilyMemberDrug(
      id: _newId(),
      drugName: drugName.trim(),
      dosage: dosage.trim(),
      frequency: frequency.trim(),
      notes: notes.trim(),
      addedAt: DateTime.now(),
    );

    final updated = List<FamilyMember>.from(members);
    updated[idx] = updated[idx].copyWith(
      drugs: [...updated[idx].drugs, drug],
      updatedAt: DateTime.now(),
    );

    final result = await _persist(updated);
    return result.fold(left, (_) => right(drug));
  }

  FutureEither<void> removeDrug({
    required String memberId,
    required String drugId,
  }) async {
    final members = getMembers();
    final idx = members.indexWhere((m) => m.id == memberId);
    if (idx == -1) {
      return left(const CacheFailure('Aile üyesi bulunamadı.'));
    }

    final updated = List<FamilyMember>.from(members);
    updated[idx] = updated[idx].copyWith(
      drugs: updated[idx].drugs.where((d) => d.id != drugId).toList(),
      updatedAt: DateTime.now(),
    );

    return _persist(updated);
  }

  FutureEither<void> _persist(List<FamilyMember> members) async {
    if (members.isEmpty) {
      return StorageService.instance.remove(_storageKey);
    }
    return StorageService.instance.setStringList(
      _storageKey,
      members.map((m) => m.toJsonString()).toList(),
    );
  }
}
