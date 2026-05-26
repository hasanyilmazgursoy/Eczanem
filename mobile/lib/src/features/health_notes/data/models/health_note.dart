import 'dart:convert';

/// Tek bir sağlık notu kaydı.
///
/// Tarihsel sağlık bilgilerini, mood durumunu, kategorisini ve
/// klinik ölçüm verilerini tutar. Hive'da JSON string olarak saklanır.
class HealthNote {
  const HealthNote({
    required this.id,
    required this.date,
    required this.category,
    required this.text,
    this.mood = '',
    required this.createdAt,
    this.systolic,
    this.diastolic,
    this.glucoseValue,
    this.painLevel,
    this.symptoms = const [],
    this.medicationTaken = false,
  });

  /// Benzersiz tanımlayıcı — microsecondsSinceEpoch.
  final String id;

  /// Notun tarih damgası (kullanıcı seçer veya bugün).
  final DateTime date;

  /// Not kategorisi (genel, tansiyon, seker, agri, psikoloji, diger).
  final String category;

  /// Not metni.
  final String text;

  /// Emoji olarak ruh hali — isteğe bağlı.
  final String mood;

  /// Kaydın oluşturulma zamanı.
  final DateTime createdAt;

  /// Tansiyon üst (sistolik) değer mmHg — tansiyon kategorisi.
  final int? systolic;

  /// Tansiyon alt (diastolik) değer mmHg — tansiyon kategorisi.
  final int? diastolic;

  /// Kan şekeri mg/dL — seker kategorisi.
  final double? glucoseValue;

  /// Ağrı seviyesi 0–10 — agri kategorisi.
  final int? painLevel;

  /// Hızlı semptom etiketleri (bulantı, baş dönmesi vb.).
  final List<String> symptoms;

  /// İlaç alındı mı?
  final bool medicationTaken;

  /// Tansiyon değerini "120/80 mmHg" formatında döner.
  String? get bloodPressureDisplay {
    if (systolic != null && diastolic != null) {
      return '$systolic/$diastolic mmHg';
    }
    return null;
  }

  HealthNote copyWith({
    String? id,
    DateTime? date,
    String? category,
    String? text,
    String? mood,
    DateTime? createdAt,
    int? systolic,
    int? diastolic,
    double? glucoseValue,
    int? painLevel,
    List<String>? symptoms,
    bool? medicationTaken,
  }) {
    return HealthNote(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      text: text ?? this.text,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      glucoseValue: glucoseValue ?? this.glucoseValue,
      painLevel: painLevel ?? this.painLevel,
      symptoms: symptoms ?? this.symptoms,
      medicationTaken: medicationTaken ?? this.medicationTaken,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'category': category,
        'text': text,
        'mood': mood,
        'created_at': createdAt.toIso8601String(),
        if (systolic != null) 'systolic': systolic,
        if (diastolic != null) 'diastolic': diastolic,
        if (glucoseValue != null) 'glucose_value': glucoseValue,
        if (painLevel != null) 'pain_level': painLevel,
        if (symptoms.isNotEmpty) 'symptoms': symptoms,
        if (medicationTaken) 'medication_taken': true,
      };

  factory HealthNote.fromJson(Map<String, dynamic> json) {
    return HealthNote(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String? ?? 'genel',
      text: json['text'] as String? ?? '',
      mood: json['mood'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      systolic: json['systolic'] as int?,
      diastolic: json['diastolic'] as int?,
      glucoseValue: (json['glucose_value'] as num?)?.toDouble(),
      painLevel: json['pain_level'] as int?,
      symptoms:
          (json['symptoms'] as List<dynamic>?)?.cast<String>() ?? const [],
      medicationTaken: json['medication_taken'] as bool? ?? false,
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
