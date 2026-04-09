/// API bağlantı sabitleri
class ApiConstants {
  ApiConstants._();

  // Geliştirme ortamında Android emülatör 10.0.2.2, gerçek cihaz local IP kullanır
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Duration timeout = Duration(seconds: 30);
}
