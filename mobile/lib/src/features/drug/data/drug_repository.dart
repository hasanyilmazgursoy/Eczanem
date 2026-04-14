import 'dart:io';

import 'package:http_parser/http_parser.dart';

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

  /// Seçilen ilaç görselini backend'e gönderip analiz sonucunu döndürür.
  FutureEither<Map<String, dynamic>> analyzeDrugImage(File imageFile) async {
    final response = await _dio.post(
      '/api/drug/analyze-image',
      data: await _buildImageUploadFormData(imageFile),
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
    );
  }

  /// Prospektüs veya kutu görselini backend'e gönderip özet döndürür.
  FutureEither<Map<String, dynamic>> summarizeProspectus(File imageFile) async {
    final response = await _dio.post(
      '/api/drug/prospectus',
      data: await _buildImageUploadFormData(imageFile),
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
    );
  }

  /// Seçilen ilaç listesi için etkileşim analizi yapar.
  FutureEither<Map<String, dynamic>> analyzeDrugInteraction(
    List<String> drugs,
  ) async {
    final response = await _dio.post(
      '/api/drug/interaction',
      data: {'drugs': drugs},
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
    );
  }

  /// Bir ilacın kullanım amacına destek olabilecek doğal alternatifleri listeler.
  FutureEither<Map<String, dynamic>> getNaturalAlternatives(
      String drugName) async {
    final response = await _dio.post(
      '/api/drug/natural-alternatives',
      data: {'drug_name': drugName},
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
    );
  }

  Future<FormData> _buildImageUploadFormData(File imageFile) async {
    return FormData.fromMap(
      {
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.uri.pathSegments.isNotEmpty
              ? imageFile.uri.pathSegments.last
              : 'drug-image.jpg',
          contentType: _resolveMediaType(imageFile.path),
        ),
      },
    );
  }

  /// Backend'in `image/*` doğrulamasını stabil geçirmek için MIME türünü uzantıdan türetir.
  MediaType _resolveMediaType(String path) {
    final extension = path.split('.').last.toLowerCase();

    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      'bmp' => MediaType('image', 'bmp'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
