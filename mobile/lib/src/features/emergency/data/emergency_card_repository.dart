import '../../../imports/imports.dart';
import 'models/emergency_card.dart';

/// Acil durum kartını Hive üzerinde singleton olarak yöneten repository.
///
/// `FamilyRepository` ile aynı stratejiyi izler: JSON string olarak saklar.
/// Tek fark: liste değil, tek nesne — `getCard()` / `saveCard()` yeterli.
class EmergencyCardRepository {
  EmergencyCardRepository._();
  static final EmergencyCardRepository instance = EmergencyCardRepository._();

  static const _storageKey = 'emergency_card_v1';

  /// Kayıtlı acil kart varsa döner; yoksa null döner.
  EmergencyCard? getCard() {
    final raw = StorageService.instance.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    return EmergencyCard.tryParse(raw);
  }

  /// Acil kartı kaydeder veya üzerine yazar.
  FutureEither<EmergencyCard> saveCard(EmergencyCard card) async {
    return runTask(() async {
      final updated = card.copyWith(updatedAt: DateTime.now());
      await StorageService.instance.setString(
        _storageKey,
        updated.toJsonString(),
      );
      return updated;
    });
  }

  /// Acil kartını tamamen siler (fabrika ayarlarına sıfırla).
  FutureEither<void> clearCard() async {
    return runTask(() async {
      await StorageService.instance.remove(_storageKey);
    });
  }
}
