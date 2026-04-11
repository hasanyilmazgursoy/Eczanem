import '../../../imports/imports.dart';

/// İlaç arama API çağrıları
class DrugRepository {
  DrugRepository._();
  static final DrugRepository instance = DrugRepository._();

  final _dio = DioService.instance;

  /// İlaç adıyla backend'den bilgi sorgular
  FutureEither<Map<String, dynamic>> searchDrug(String query) async {
    final response = await _dio.post(
      '/api/drug/search',
      data: {'query': query},
    );
    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
    );
  }
}
