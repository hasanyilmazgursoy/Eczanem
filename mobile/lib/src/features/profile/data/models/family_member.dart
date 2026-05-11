import 'dart:convert';

/// Aile üyesi veri modeli.
///
/// Hive'da JSON string olarak saklanır (reminder modeli ile aynı strateji).
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    required this.emoji,
    this.age,
    this.drugs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String relationship;
  final String emoji;
  final int? age;
  final List<FamilyMemberDrug> drugs;
  final DateTime createdAt;
  final DateTime updatedAt;

  FamilyMember copyWith({
    String? id,
    String? name,
    String? relationship,
    String? emoji,
    int? age,
    List<FamilyMemberDrug>? drugs,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      emoji: emoji ?? this.emoji,
      age: age ?? this.age,
      drugs: drugs ?? this.drugs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relationship': relationship,
        'emoji': emoji,
        'age': age,
        'drugs': drugs.map((d) => d.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final rawDrugs = json['drugs'] as List<dynamic>? ?? [];
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '\u{1F464}',
      age: json['age'] as int?,
      drugs: rawDrugs
          .whereType<Map<String, dynamic>>()
          .map(FamilyMemberDrug.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static FamilyMember? tryParse(String raw) {
    try {
      return FamilyMember.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

/// Aile üyesine ait ilaç kaydı.
class FamilyMemberDrug {
  const FamilyMemberDrug({
    required this.id,
    required this.drugName,
    this.dosage = '',
    this.frequency = '',
    this.notes = '',
    required this.addedAt,
  });

  final String id;
  final String drugName;
  final String dosage;
  final String frequency;
  final String notes;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'drug_name': drugName,
        'dosage': dosage,
        'frequency': frequency,
        'notes': notes,
        'added_at': addedAt.toIso8601String(),
      };

  factory FamilyMemberDrug.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDrug(
      id: json['id'] as String,
      drugName: json['drug_name'] as String,
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      addedAt: DateTime.parse(json['added_at'] as String),
    );
  }
}
