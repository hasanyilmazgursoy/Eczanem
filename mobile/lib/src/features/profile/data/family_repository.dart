import '../../../imports/imports.dart';
import 'family_api_service.dart';
import 'models/family_member.dart';

/// Aile üyesi verisini yöneten veri katmanı.
///
/// **Strateji:** Local-first + cloud sync.
/// - Her CRUD önce Hive'a yazılır, sonra arka planda backend'e iletilir.
/// - `syncFromBackend()` login sonrası çağrılır; backend source-of-truth
///   olarak kabul edilip Hive tamamen güncellenir.
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

  /// Backend'den aile üyelerini çekip Hive'ı günceller.
  ///
  /// Login olmayan kullanıcılar için sessizce çıkar. Hata durumunda mevcut
  /// lokal veri korunur.
  Future<void> syncFromBackend() async {
    final result = await FamilyApiService.instance.getMembers();
    result.fold(
      (failure) => AppLogger.warning(
        'Backend aile profili sync başarısız: ${failure.message}',
      ),
      (members) async {
        if (members.isEmpty) {
          await StorageService.instance.remove(_storageKey);
        } else {
          await StorageService.instance.setStringList(
            _storageKey,
            members.map((m) => m.toJsonString()).toList(),
          );
        }
      },
    );
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
    if (result.isLeft()) return result.fold(left, (_) => right(member));

    // Arka planda backend'e gönder
    _syncAddMember(member);
    return right(member);
  }

  FutureEither<FamilyMember> updateMember(FamilyMember updated) async {
    final updatedWithTime = updated.copyWith(updatedAt: DateTime.now());
    final members = getMembers()
        .map((m) => m.id == updated.id ? updatedWithTime : m)
        .toList();

    final result = await _persist(members);
    if (result.isLeft()) {
      return result.fold(left, (_) => right(updatedWithTime));
    }

    // Arka planda backend'e gönder
    Future<void>.microtask(() async {
      final apiResult =
          await FamilyApiService.instance.updateMember(updatedWithTime);
      apiResult.fold(
        (f) =>
            AppLogger.warning('Backend üye güncelleme başarısız: ${f.message}'),
        (_) {},
      );
    });

    return right(updatedWithTime);
  }

  FutureEither<void> removeMember(String id) async {
    final updated = getMembers().where((m) => m.id != id).toList();
    final result = await _persist(updated);
    if (result.isLeft()) return result;

    // Arka planda backend'den sil
    Future<void>.microtask(() async {
      final apiResult = await FamilyApiService.instance.removeMember(id);
      apiResult.fold(
        (f) => AppLogger.warning('Backend üye silme başarısız: ${f.message}'),
        (_) {},
      );
    });

    return result;
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
    if (result.isLeft()) return result.fold(left, (_) => right(drug));

    // Arka planda backend'e gönder
    Future<void>.microtask(() async {
      final apiResult = await FamilyApiService.instance.addDrug(
        memberId: memberId,
        drugName: drugName.trim(),
        dosage: dosage.trim(),
        frequency: frequency.trim(),
        notes: notes.trim(),
      );
      apiResult.fold(
        (f) => AppLogger.warning('Backend ilaç ekleme başarısız: ${f.message}'),
        (backendDrug) async {
          if (backendDrug.id == drug.id) return;
          // Backend farklı ID atadı; lokal ilaç kaydını güncelle.
          // memberId _syncAddMember sonrası değişmiş olabilir;
          // drug.id üzerinden de arama yapılır.
          final members = getMembers();
          var idx = members.indexWhere((m) => m.id == memberId);
          if (idx == -1) {
            idx = members.indexWhere(
              (m) => m.drugs.any((d) => d.id == drug.id),
            );
          }
          if (idx == -1) return;
          final member = members[idx];
          final updatedDrugs = member.drugs
              .map((d) => d.id == drug.id ? backendDrug : d)
              .toList();
          final updatedMembers = List<FamilyMember>.from(members);
          updatedMembers[idx] = member.copyWith(drugs: updatedDrugs);
          await _persist(updatedMembers);
        },
      );
    });

    return right(drug);
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

    final result = await _persist(updated);
    if (result.isLeft()) return result;

    // Arka planda backend'den sil
    Future<void>.microtask(() async {
      final apiResult = await FamilyApiService.instance.removeDrug(
        memberId: memberId,
        drugId: drugId,
      );
      apiResult.fold(
        (f) => AppLogger.warning('Backend ilaç silme başarısız: ${f.message}'),
        (_) {},
      );
    });

    return result;
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

  /// Backend'e yeni üye eklemeyi arka planda dener.
  /// Başarılı olunca backend UUID'sini yerel kayda yazar;
  /// böylece aynı oturumdaki güncelleme/silme işlemleri doğru ID'yi kullanır.
  void _syncAddMember(FamilyMember localMember) {
    Future<void>.microtask(() async {
      final apiResult = await FamilyApiService.instance.addMember(
        name: localMember.name,
        relationship: localMember.relationship,
        emoji: localMember.emoji,
        age: localMember.age,
      );
      apiResult.fold(
        (f) => AppLogger.warning('Backend üye ekleme başarısız: ${f.message}'),
        (backendMember) async {
          if (backendMember.id == localMember.id) return;
          // Backend farklı bir UUID atadı; lokal kaydı güncelle (ilaçlar korunur).
          final members = getMembers();
          final updated = members.map((m) {
            if (m.id != localMember.id) return m;
            return backendMember.copyWith(drugs: m.drugs);
          }).toList();
          await _persist(updated);
        },
      );
    });
  }
}
