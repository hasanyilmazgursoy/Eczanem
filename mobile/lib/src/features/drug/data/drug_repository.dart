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
      data: FormData.fromMap(
        {
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.uri.pathSegments.isNotEmpty
                ? imageFile.uri.pathSegments.last
                : 'drug-image.jpg',
            contentType: _resolveMediaType(imageFile.path),
          ),
        },
      ),
    );

    return response.fold(
      (failure) => left(failure),
      (response) => right(response.data as Map<String, dynamic>),
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
