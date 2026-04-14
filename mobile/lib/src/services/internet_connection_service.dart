import '../imports/imports.dart';

class InternetConnectionService {
  InternetConnectionService();

  final InternetConnection internetConnection = InternetConnection();

  Future<bool> hasConnection() async {
    // Bu uygulamada asıl önemli olan şeyin "genel internet" değil,
    // yapılandırılmış backend'e erişim olmasıdır. Özellikle aynı Wi‑Fi
    // üzerindeki yerel backend kullanımında dış internet olmasa bile uygulama
    // çalışabilmelidir.
    final backendReachable = await _canReachBackend();
    if (backendReachable) return true;

    return internetConnection.hasInternetAccess;
  }

  Future<bool> _canReachBackend() async {
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      final response = await dio.get<dynamic>('/health');
      return response.statusCode != null && response.statusCode! < 500;
    } catch (_) {
      return false;
    }
  }
}
