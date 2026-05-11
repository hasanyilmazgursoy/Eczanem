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
}
