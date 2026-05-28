import 'package:eczanem/src/features/pharmacy/data/models/pharmacy_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PharmacyItem', () {
    test('fromJson tüm alanları doğru parse eder', () {
      final json = {
        'name': 'Eczane Merkez',
        'address': 'Atatürk Cad. No:1',
        'phone': '0312 123 45 67',
        'district': 'Çankaya',
        'lat': 39.9334,
        'lon': 32.8597,
        'distance_km': 1.2,
      };

      final item = PharmacyItem.fromJson(json);

      expect(item.name, 'Eczane Merkez');
      expect(item.address, 'Atatürk Cad. No:1');
      expect(item.phone, '0312 123 45 67');
      expect(item.district, 'Çankaya');
      expect(item.lat, 39.9334);
      expect(item.lon, 32.8597);
      expect(item.distanceKm, 1.2);
    });

    test('fromJson eksik nullable alanlar null döner', () {
      final json = {
        'name': 'Gece Eczanesi',
        'address': 'Sahil Cad.',
        'phone': '0232 111 22 33',
        'district': 'Konak',
      };

      final item = PharmacyItem.fromJson(json);

      expect(item.lat, isNull);
      expect(item.lon, isNull);
      expect(item.distanceKm, isNull);
    });

    test('fromJson boş map tüm zorunlu alanları boş string döner', () {
      final item = PharmacyItem.fromJson({});

      expect(item.name, '');
      expect(item.address, '');
      expect(item.phone, '');
      expect(item.district, '');
      expect(item.lat, isNull);
      expect(item.lon, isNull);
    });

    // num → double dönüşümünü doğrula (int JSON değerleri de kabul edilmeli)
    test('fromJson tam sayı lat/lon double olarak okunur', () {
      final json = {
        'name': '',
        'address': '',
        'phone': '',
        'district': '',
        'lat': 39,
        'lon': 32,
        'distance_km': 5,
      };

      final item = PharmacyItem.fromJson(json);

      expect(item.lat, isA<double>());
      expect(item.lon, isA<double>());
      expect(item.distanceKm, isA<double>());
    });
  });

  group('NearbyPharmaciesResponse', () {
    test('fromJson eczane listesini ve meta alanları doğru parse eder', () {
      final json = {
        'pharmacies': [
          {
            'name': 'A Eczane',
            'address': 'Adres 1',
            'phone': '111',
            'district': 'D1',
            'lat': 41.0,
            'lon': 28.0,
            'distance_km': 0.5,
          },
          {
            'name': 'B Eczane',
            'address': 'Adres 2',
            'phone': '222',
            'district': 'D2',
          },
        ],
        'count': 2,
        'api_available': true,
        'detected_il': 'istanbul',
        'detected_ilce': 'beşiktaş',
        'fallback_to_il': false,
      };

      final response = NearbyPharmaciesResponse.fromJson(json);

      expect(response.pharmacies, hasLength(2));
      expect(response.pharmacies.first.name, 'A Eczane');
      expect(response.count, 2);
      expect(response.apiAvailable, isTrue);
      expect(response.detectedIl, 'istanbul');
      expect(response.detectedIlce, 'beşiktaş');
      expect(response.fallbackToIl, isFalse);
    });

    test('fromJson boş eczane listesinde api_available false kalır', () {
      final json = {
        'pharmacies': <dynamic>[],
        'count': 0,
        'api_available': false,
      };

      final response = NearbyPharmaciesResponse.fromJson(json);

      expect(response.pharmacies, isEmpty);
      expect(response.count, 0);
      expect(response.apiAvailable, isFalse);
    });

    test('fromJson fallback_to_il true geldiğinde korunur', () {
      final json = {
        'pharmacies': [
          {'name': 'A', 'address': '', 'phone': '', 'district': ''},
        ],
        'count': 1,
        'api_available': true,
        'fallback_to_il': true,
      };

      final response = NearbyPharmaciesResponse.fromJson(json);

      expect(response.fallbackToIl, isTrue);
      expect(response.pharmacies, hasLength(1));
    });

    test('fromJson boş map tüm alanları varsayılan değerlere düşürür', () {
      final response = NearbyPharmaciesResponse.fromJson({});

      expect(response.pharmacies, isEmpty);
      expect(response.count, 0);
      expect(response.apiAvailable, isFalse);
      expect(response.detectedIl, '');
      expect(response.detectedIlce, '');
      expect(response.fallbackToIl, isFalse);
    });
  });
}
