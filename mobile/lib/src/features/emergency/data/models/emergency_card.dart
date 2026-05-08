import 'dart:convert';

/// Kullanıcının acil durum kartı verisi.
///
/// Hive'da tek bir JSON string olarak saklanır (singleton pattern).
/// Liste tutmaz; her kullanıcının yalnızca bir acil kart kaydı olur.
class EmergencyCard {
  const EmergencyCard({
    this.bloodType = '',
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.doctorName = '',
    this.doctorPhone = '',
    this.notes = '',
    required this.updatedAt,
  });

  /// Kan grubu (örn. "A Rh+", "0 Rh-").
  final String bloodType;

  /// Alerji listesi (ilaç, besin, madde).
  final List<String> allergies;

  /// Kronik hastalıklar (diyabet, hipertansiyon, vb.).
  final List<String> chronicConditions;

  /// Düzenli kullanılan ilaçlar — quick reference.
  final List<String> currentMedications;

  /// Acil iletişim kişisinin adı.
  final String emergencyContactName;

  /// Acil iletişim kişisinin telefonu.
  final String emergencyContactPhone;

  /// Doktor adı.
  final String doctorName;

  /// Doktor telefonu.
  final String doctorPhone;

  /// Ek notlar / özel bilgiler.
  final String notes;

  /// Son güncelleme zamanı.
  final DateTime updatedAt;

  EmergencyCard copyWith({
    String? bloodType,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? doctorName,
    String? doctorPhone,
    String? notes,
    DateTime? updatedAt,
  }) {
    return EmergencyCard(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      doctorName: doctorName ?? this.doctorName,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'blood_type': bloodType,
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
        'current_medications': currentMedications,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
        'doctor_name': doctorName,
        'doctor_phone': doctorPhone,
        'notes': notes,
        'updated_at': updatedAt.toIso8601String(),
      };

  factory EmergencyCard.fromJson(Map<String, dynamic> json) {
    // JSON dizisini string listesine güvenli dönüştürme
    List<String> toStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    return EmergencyCard(
      bloodType: json['blood_type'] as String? ?? '',
      allergies: toStringList(json['allergies']),
      chronicConditions: toStringList(json['chronic_conditions']),
      currentMedications: toStringList(json['current_medications']),
      emergencyContactName: json['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone:
          json['emergency_contact_phone'] as String? ?? '',
      doctorName: json['doctor_name'] as String? ?? '',
      doctorPhone: json['doctor_phone'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Hive string'inden güvenli parse — hata durumunda null döner.
  static EmergencyCard? tryParse(String raw) {
    try {
      return EmergencyCard.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  String toJsonString() => jsonEncode(toJson());

  /// Doluluk kontrolü — hiç veri girilmemiş mi?
  bool get isEmpty =>
      bloodType.isEmpty &&
      allergies.isEmpty &&
      chronicConditions.isEmpty &&
      currentMedications.isEmpty &&
      emergencyContactName.isEmpty &&
      notes.isEmpty;

  bool get isNotEmpty => !isEmpty;
}
