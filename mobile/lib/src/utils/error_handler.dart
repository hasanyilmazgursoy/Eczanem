import 'package:dio/dio.dart';

class AppErrorHandler {
  static String format(dynamic error) {
    if (error is String) return error;

    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final detail = responseData['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail;
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          return 'Sunucuya ulaşılamadı. İnternet bağlantınızı kontrol edin.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode != null) {
            return 'İstek başarısız oldu (Hata kodu: $statusCode).';
          }
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
          break;
      }
    }

    try {
      if (error?.message != null) return error.message;
      if (error?.toString() != null) return error.toString();
    } catch (_) {}

    return 'Beklenmeyen bir hata oluştu.';
  }
}
