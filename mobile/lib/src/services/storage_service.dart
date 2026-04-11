import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/utils.dart';

/// Hive tabanlı basit key-value storage servisi.
///
/// Geriye dönük uyumluluk için mevcut SharedPreferences verilerini ilk açılışta
/// Hive kutusuna taşır.
class StorageService {
    static const _boxName = 'app_storage';
    static const _migrationDoneKey = '__shared_preferences_migrated__';

  StorageService._();
  static final StorageService instance = StorageService._();

    late final Box<dynamic> _box;

    /// Hive kutusunu hazırlar ve gerekiyorsa SharedPreferences'tan veriyi taşır.
  FutureEither<void> init() async {
    return runTask(() async {
            await Hive.initFlutter();
            _box = await Hive.openBox<dynamic>(_boxName);
            await _migrateSharedPreferencesIfNeeded();
            AppLogger.info('StorageService (Hive) initialized');
    });
  }

    Future<void> _migrateSharedPreferencesIfNeeded() async {
        if (_box.get(_migrationDoneKey, defaultValue: false) == true) {
            return;
        }

        final prefs = await SharedPreferences.getInstance();

        for (final key in prefs.getKeys()) {
            if (_box.containsKey(key)) continue;

            final value = prefs.get(key);
            if (value is String || value is bool || value is int || value is double) {
                await _box.put(key, value);
            } else if (value is List<String>) {
                await _box.put(key, value);
            }
        }

        await _box.put(_migrationDoneKey, true);
    }

  // --- SETTERS ---

    FutureEither<void> setString(String key, String value) async =>
            runTask(() => _box.put(key, value));

    FutureEither<void> setBool(String key, bool value) async =>
            runTask(() => _box.put(key, value));

    FutureEither<void> setInt(String key, int value) async =>
            runTask(() => _box.put(key, value));

    FutureEither<void> setDouble(String key, double value) async =>
            runTask(() => _box.put(key, value));

    FutureEither<void> setStringList(String key, List<String> value) async =>
            runTask(() => _box.put(key, value));

  // --- GETTERS ---

    String? getString(String key) => _box.get(key) as String?;
    bool? getBool(String key) => _box.get(key) as bool?;
    int? getInt(String key) => _box.get(key) as int?;
    double? getDouble(String key) => _box.get(key) as double?;
    List<String>? getStringList(String key) {
        final value = _box.get(key);
        if (value is List) {
            return value.map((item) => item.toString()).toList();
        }

        return null;
    }

  // --- COMMON ---

    bool containsKey(String key) => _box.containsKey(key);

    FutureEither<void> remove(String key) async => runTask(() => _box.delete(key));

    FutureEither<void> clear() async => runTask(() async {
                final keys = _box.keys.where((key) => key != _migrationDoneKey).toList();
                await _box.deleteAll(keys);
            });
}
