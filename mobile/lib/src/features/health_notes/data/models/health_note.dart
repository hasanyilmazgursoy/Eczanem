import 'dart:convert';

/// Tek bir sağlık notu kaydı.
///
/// Tarihsel sağlık bilgilerini, mood durumunu ve kategorisini tutar.
/// Hive'da JSON string olarak saklanır — FamilyMember ile aynı strateji.
class HealthNote {
  const HealthNote({
    required this.id,
    required this.date,
    required this.category,
    required this.text,
    this.mood = '',
    required this.createdAt,
  });

  /// Benzersiz tanımlayıcı — microsecondsSinceEpoch.
  final String id;

  /// Notun tarih damgası (kullanıcı seçer veya bugün).
  final DateTime date;

  /// Not kategorisi (genel, tansiyon, şeker, ağrı, psikoloji, diğer).
  final String category;

  /// Not metni.
  final String text;

  /// Emoji olarak ruh hali (😊 😐 😢 😫 🤒) — isteğe bağlı.
  final String mood;

  /// Kaydın oluşturulma zamanı.
  final DateTime createdAt;

  HealthNote copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? text,
    String? mood,
    DateTime? createdAt,
  }) {
    return HealthNote(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': category,
        'text': text,
        'mood': mood,
        'created_at': createdAt.toIso8601String(),
      };

  factory HealthNote.fromJson(Map<String, dynamic> json) {
    return HealthNote(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'genel',
      text: json['text'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Hive string'inden güvenli parse — hata durumunda null döner.
  static HealthNote? tryParse(String raw) {
    try {
      return HealthNote.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Sağlık notu kategorileri — sabit liste, ID ve görüntü adı içerir.
abstract final class HealthNoteCategory {
  static const genel = 'genel';
  static const tansiyon = 'tansiyon';
  static const seker = 'seker';
  static const agri = 'agri';
  static const psikoloji = 'psikoloji';
  static const diger = 'diger';

  static const all = [genel, tansiyon, seker, agri, psikoloji, diger];

  /// Kategori adına karşılık gelen ikon unicode.
  static String iconFor(String category) {
    return switch (category) {
      tansiyon => '🩺',
      seker => '🍬',
      agri => '🤕',
      psikoloji => '🧠',
      diger => '📋',
      _ => '📝', // genel
    };
  }
}

/// Mood seçenekleri — emoji + label çiftleri.
abstract final class HealthNoteMood {
  static const harika = '😊';
  static const iyi = '🙂';
  static const orta = '😐';
  static const kotu = '😢';
  static const berbat = '😫';
  static const hasta = '🤒';

  static const all = [harika, iyi, orta, kotu, berbat, hasta];
}
