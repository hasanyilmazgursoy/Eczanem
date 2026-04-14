import 'dart:convert';

import '../../../imports/imports.dart';

/// Arama ve tarama geçmişini yerel depolamada tek yerden yöneten katman.
class DrugHistoryRepository {
  DrugHistoryRepository._();
  static final DrugHistoryRepository instance = DrugHistoryRepository._();

  static const _recentSearchesKey = 'drug_recent_searches';
  static const _recentScansKey = 'drug_recent_scans';
  static const _maxSearchItems = 8;
  static const _maxScanItems = 12;

  List<String> getRecentSearches() {
    return StorageService.instance.getStringList(_recentSearchesKey) ??
        const [];
  }

  FutureEither<void> saveRecentSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return right(null);
    }

    final updated = [
      normalizedQuery,
      ...getRecentSearches().where(
        (item) => item.toLowerCase() != normalizedQuery.toLowerCase(),
      ),
    ].take(_maxSearchItems).toList();

    return StorageService.instance.setStringList(_recentSearchesKey, updated);
  }

  FutureEither<void> removeSearchAt(int index) async {
    final items = List<String>.from(getRecentSearches());
    if (index < 0 || index >= items.length) {
      return right(null);
    }

    items.removeAt(index);
    if (items.isEmpty) {
      return StorageService.instance.remove(_recentSearchesKey);
    }

    return StorageService.instance.setStringList(_recentSearchesKey, items);
  }

  FutureEither<void> clearSearches() async {
    return StorageService.instance.remove(_recentSearchesKey);
  }

  List<DrugScanHistoryEntry> getRecentScans() {
    final rawItems =
        StorageService.instance.getStringList(_recentScansKey) ?? const [];

    return rawItems
        .map(DrugScanHistoryEntry.tryParse)
        .whereType<DrugScanHistoryEntry>()
        .toList();
  }

  FutureEither<void> saveScanResult({
    required DrugScanHistoryMode mode,
    required Map<String, dynamic> payload,
  }) async {
    final entry = DrugScanHistoryEntry.fromPayload(
      mode: mode,
      payload: payload,
    );

    final updated = [
      entry,
      ...getRecentScans().where(
        (item) => !(item.mode == entry.mode &&
            item.title.toLowerCase() == entry.title.toLowerCase()),
      ),
    ].take(_maxScanItems).map((item) => item.toJsonString()).toList();

    return StorageService.instance.setStringList(_recentScansKey, updated);
  }

  FutureEither<void> removeScanAt(int index) async {
    final items = List<DrugScanHistoryEntry>.from(getRecentScans());
    if (index < 0 || index >= items.length) {
      return right(null);
    }

    items.removeAt(index);
    if (items.isEmpty) {
      return StorageService.instance.remove(_recentScansKey);
    }

    return StorageService.instance.setStringList(
      _recentScansKey,
      items.map((item) => item.toJsonString()).toList(),
    );
  }

  FutureEither<void> clearScans() async {
    return StorageService.instance.remove(_recentScansKey);
  }

  List<String> getSuggestedDrugNames() {
    final suggestions = <String>[];

    for (final query in getRecentSearches()) {
      final normalized = query.trim();
      if (normalized.isEmpty) continue;
      if (!suggestions
          .any((item) => item.toLowerCase() == normalized.toLowerCase())) {
        suggestions.add(normalized);
      }
    }

    for (final entry in getRecentScans()) {
      final normalized = entry.title.trim();
      if (normalized.isEmpty) continue;
      if (!suggestions
          .any((item) => item.toLowerCase() == normalized.toLowerCase())) {
        suggestions.add(normalized);
      }
    }

    return suggestions;
  }
}

enum DrugScanHistoryMode { medicine, prospectus }

class DrugScanHistoryEntry {
  const DrugScanHistoryEntry({
    required this.id,
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.payload,
  });

  final String id;
  final DrugScanHistoryMode mode;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final Map<String, dynamic> payload;

  bool get hasCandidates {
    if (mode == DrugScanHistoryMode.prospectus) {
      return false;
    }

    final rawCandidates = payload['aday_ilaclar'];
    if (rawCandidates is! List) {
      return false;
    }

    final primaryName =
        (payload['ilac_adi'] ?? '').toString().trim().toLowerCase();
    return rawCandidates
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .any((item) => item.toLowerCase() != primaryName);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mode': mode.name,
      'title': title,
      'subtitle': subtitle,
      'createdAt': createdAt.toIso8601String(),
      'payload': payload,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static DrugScanHistoryEntry fromPayload({
    required DrugScanHistoryMode mode,
    required Map<String, dynamic> payload,
  }) {
    final title = (payload['ilac_adi'] ?? '').toString().trim();
    final resolvedTitle = title.isEmpty
        ? mode == DrugScanHistoryMode.prospectus
            ? 'Prospektüs Özeti'
            : 'Bilinmeyen İlaç'
        : title;

    final subtitle = mode == DrugScanHistoryMode.prospectus
        ? (payload['prospektus_turu'] ?? '').toString().trim()
        : (payload['etken_madde'] ?? '').toString().trim();

    return DrugScanHistoryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      mode: mode,
      title: resolvedTitle,
      subtitle: subtitle,
      createdAt: DateTime.now(),
      payload: payload,
    );
  }

  static DrugScanHistoryEntry? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final modeName = decoded['mode']?.toString();
      final mode = DrugScanHistoryMode.values.firstWhere(
        (value) => value.name == modeName,
        orElse: () => DrugScanHistoryMode.medicine,
      );

      final payload = decoded['payload'];
      return DrugScanHistoryEntry(
        id: decoded['id']?.toString() ?? '',
        mode: mode,
        title: decoded['title']?.toString() ?? '',
        subtitle: decoded['subtitle']?.toString() ?? '',
        createdAt: DateTime.tryParse(decoded['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        payload: payload is Map<String, dynamic>
            ? payload
            : Map<String, dynamic>.from(payload as Map? ?? const {}),
      );
    } catch (_) {
      return null;
    }
  }
}
