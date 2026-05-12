/// Nöbetçi eczane veri modeli.
class PharmacyItem {
  const PharmacyItem({
    required this.name,
    required this.address,
    required this.phone,
    required this.district,
    this.lat,
    this.lon,
    this.distanceKm,
  });

  final String name;
  final String address;
  final String phone;
  final String district;
  final double? lat;
  final double? lon;
  final double? distanceKm;

  factory PharmacyItem.fromJson(Map<String, dynamic> json) {
    return PharmacyItem(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      district: json['district'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}

/// Backend `/api/pharmacy/nearby` yanıt modeli.
class NearbyPharmaciesResponse {
  const NearbyPharmaciesResponse({
    required this.pharmacies,
    required this.count,
    required this.apiAvailable,
    this.detectedIl = '',
    this.detectedIlce = '',
  });

  final List<PharmacyItem> pharmacies;
  final int count;
  final bool apiAvailable;

  /// Nominatim ile tespit edilen il (konum butonu kullanıldığında dolu olur)
  final String detectedIl;

  /// Nominatim ile tespit edilen ilçe
  final String detectedIlce;

  factory NearbyPharmaciesResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['pharmacies'] as List<dynamic>? ?? [];
    return NearbyPharmaciesResponse(
      pharmacies: rawList
          .whereType<Map<String, dynamic>>()
          .map(PharmacyItem.fromJson)
          .toList(),
      count: json['count'] as int? ?? 0,
      apiAvailable: json['api_available'] as bool? ?? false,
      detectedIl: json['detected_il'] as String? ?? '',
      detectedIlce: json['detected_ilce'] as String? ?? '',
    );
  }
}
