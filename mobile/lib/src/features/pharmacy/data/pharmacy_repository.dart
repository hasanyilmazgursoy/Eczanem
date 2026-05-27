import '../../../imports/imports.dart';
import 'models/pharmacy_item.dart';

/// Nöbetçi eczane sorgularını backend API üzerinden yöneten repository.
class PharmacyRepository {
  PharmacyRepository._();
  static final PharmacyRepository instance = PharmacyRepository._();

  final _dio = DioService.instance;

  /// İl ve ilçe bilgisiyle nöbetçi eczaneleri sorgular.
  FutureEither<NearbyPharmaciesResponse> getNearbyPharmacies({
    double lat = 0,
    double lon = 0,
    String il = '',
    String ilce = '',
  }) async {
    final response = await _dio.get(
      '/api/pharmacy/nearby',
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'il': il,
        'ilce': ilce,
      },
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(
        NearbyPharmaciesResponse.fromJson(
          response.data as Map<String, dynamic>,
        ),
      ),
    );
  }

  /// Bir ilin eczaneler.gen.tr'deki gerçek ilçe listesini döndürür.
  ///
  /// İlçe dropdown'ını doldurmak için kullanılır.
  FutureEither<List<String>> getDistricts(String il) async {
    final response = await _dio.get(
      '/api/pharmacy/districts',
      queryParameters: {'il': il},
    );

    return response.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['districts'] as List).cast<String>();
        return right(list);
      },
    );
  }
}
