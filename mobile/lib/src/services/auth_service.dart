import 'dart:async';

import '../utils/utils.dart';
import '../config/app_config.dart';
import 'secure_storage_service.dart';
import 'package:dio/dio.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const String _accessTokenKey = 'auth_access_token';

  Dio get _dio => AppConfig.dio;
  SecureStorageService get _secureStorage => SecureStorageService.instance;

  // Custom Backend doesn't have a built-in auth state stream, so we manage our own
  final StreamController<Map<String, dynamic>?> _authStateController =
      StreamController<Map<String, dynamic>?>.broadcast();

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges =>
      _authStateController.stream;

  Future<String?> _readAccessToken() async {
    final result = await _secureStorage.read(_accessTokenKey);
    return result.fold(
        (failure) => throw Exception(failure.message), (token) => token);
  }

  Future<void> _persistAccessToken(String token) async {
    final result = await _secureStorage.write(_accessTokenKey, token);
    result.fold((failure) => throw Exception(failure.message), (_) {});
  }

  Future<void> _clearAccessToken() async {
    final result = await _secureStorage.delete(_accessTokenKey);
    result.fold((failure) => throw Exception(failure.message), (_) {});
  }

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final dynamic user = data['user'];
    if (user is Map<String, dynamic>) return user;
    return data;
  }

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _dio.post<dynamic>('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _persistAccessToken(token);
      }
      _authStateController.add(_extractUser(data));
      return data;
    }, requiresNetwork: true);
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return runTask(() async {
      final response = await _dio.post<dynamic>('/auth/signup', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _persistAccessToken(token);
      }
      _authStateController.add(_extractUser(data));
      return data;
    }, requiresNetwork: true);
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(() async {
      await _dio.post<dynamic>('/auth/forgot-password', data: {'email': email});
    }, requiresNetwork: true);
  }

  FutureEither<void> logout() async {
    return runTask(() async {
      final token = await _readAccessToken();
      try {
        if (token != null && token.isNotEmpty) {
          await _dio.post<dynamic>(
            '/auth/logout',
            options: Options(
              headers: {'Authorization': 'Bearer $token'},
            ),
          );
        }
      } catch (_) {
        // Kullanıcıyı cihazda çıkışa zorlamak backend hata verse de daha doğru.
      }
      await _clearAccessToken();
      _authStateController.add(null);
    }, requiresNetwork: true);
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(() async {
      final token = await _readAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _dio.get<dynamic>(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return response.data as Map<String, dynamic>;
    });
  }

  /// Mevcut şifreyi doğrulayarak yeni şifreyle değiştirir.
  FutureEither<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return runTask(() async {
      final token = await _readAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Oturumunuz sona ermiş. Lütfen tekrar giriş yapın.');
      }

      await _dio.put<dynamic>(
        '/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    }, requiresNetwork: true);
  }

  void dispose() {
    _authStateController.close();
  }
}
