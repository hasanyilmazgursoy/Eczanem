import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../routing/app_routes.dart';
import '../routing/global_navigator.dart';
import '../utils/logger.dart';

class AppConfig {
  AppConfig._();
  static late final Dio dio;

  static String get baseUrl => _getBaseUrl();

  static Future<void> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _getBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          AppLogger.info(
              '🌐 [DIO] REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.info(
              '✅ [DIO] RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        // Token süresi dolmuş veya geçersizse oturumu kapat ve login'e yönlendir
        onError: (DioException e, handler) async {
          AppLogger.error(
              '❌ [DIO] ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');

          if (e.response?.statusCode == 401) {
            await const FlutterSecureStorage()
                .delete(key: 'auth_access_token');

            final ctx = rootContext;
            if (ctx != null && ctx.mounted) {
              GoRouter.of(ctx).go(AppRoutes.login);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  static String _getBaseUrl() {
    return dotenv.get('API_BASE_URL', fallback: 'http://10.0.2.2:8000');
  }
}
