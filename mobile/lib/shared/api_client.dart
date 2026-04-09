import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';

/// Backend API ile iletişim kuran HTTP istemcisi
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.timeout,
    receiveTimeout: ApiConstants.timeout,
    headers: {'Content-Type': 'application/json'},
  ));

  // Geliştirme ortamında istekleri logla
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});

/// İlaç sorgulama API servisi
final drugApiProvider = Provider<DrugApiService>((ref) {
  return DrugApiService(ref.watch(dioProvider));
});

class DrugApiService {
  final Dio _dio;

  DrugApiService(this._dio);

  /// İlaç adıyla arama yapar
  Future<Map<String, dynamic>> searchDrug(String query) async {
    final response = await _dio.post(
      '/api/drug/search',
      data: {'query': query},
    );
    return response.data as Map<String, dynamic>;
  }
}
