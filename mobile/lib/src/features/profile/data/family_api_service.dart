import 'package:dio/dio.dart';

import '../../../config/app_config.dart';
import '../../../services/secure_storage_service.dart';
import '../../../utils/utils.dart';
import 'models/family_member.dart';

/// Backend `/api/profile/family/` endpoint'lerine erişen servis katmanı.
///
/// Token yoksa (kullanıcı login değilse) çağrılar `ServerFailure` döndürür;
/// bu durum `FamilyRepository`'de lokal işleme düşülme ile ele alınır.
class FamilyApiService {
  FamilyApiService._();
  static final FamilyApiService instance = FamilyApiService._();

  static const _tokenKey = 'auth_access_token';

  Dio get _dio => AppConfig.dio;

  /// Secure storage'dan JWT token okur. Token yoksa `null` döner.
  Future<String?> _readToken() async {
    final result = await SecureStorageService.instance.read(_tokenKey);
    return result.fold((_) => null, (t) => (t?.isNotEmpty ?? false) ? t : null);
  }

  Future<Options> _authOptions() async {
    final token = await _readToken();
    if (token == null) {
      throw Exception('auth_required');
    }
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  FutureEither<List<FamilyMember>> getMembers() async {
    return runTask(() async {
      final options = await _authOptions();
      final response = await _dio.get<dynamic>(
        '/api/profile/family/',
        options: options,
      );
      final list =
          (response.data as List<dynamic>).cast<Map<String, dynamic>>();
      return list.map(FamilyMember.fromJson).toList();
    });
  }

  FutureEither<FamilyMember> addMember({
    required String name,
    required String relationship,
    required String emoji,
    int? age,
  }) async {
    return runTask(() async {
      final options = await _authOptions();
      final response = await _dio.post<dynamic>(
        '/api/profile/family/',
        data: {
          'name': name,
          'relationship': relationship,
          'emoji': emoji,
          if (age != null) 'age': age,
        },
        options: options,
      );
      return FamilyMember.fromJson(response.data as Map<String, dynamic>);
    });
  }

  FutureEither<FamilyMember> updateMember(FamilyMember member) async {
    return runTask(() async {
      final options = await _authOptions();
      final response = await _dio.put<dynamic>(
        '/api/profile/family/${member.id}',
        data: {
          'name': member.name,
          'relationship': member.relationship,
          'emoji': member.emoji,
          'age': member.age,
        },
        options: options,
      );
      return FamilyMember.fromJson(response.data as Map<String, dynamic>);
    });
  }

  FutureEither<void> removeMember(String memberId) async {
    return runTask(() async {
      final options = await _authOptions();
      await _dio.delete<dynamic>(
        '/api/profile/family/$memberId',
        options: options,
      );
    });
  }

  FutureEither<FamilyMemberDrug> addDrug({
    required String memberId,
    required String drugName,
    String dosage = '',
    String frequency = '',
    String notes = '',
  }) async {
    return runTask(() async {
      final options = await _authOptions();
      final response = await _dio.post<dynamic>(
        '/api/profile/family/$memberId/drugs/',
        data: {
          'drug_name': drugName,
          'dosage': dosage,
          'frequency': frequency,
          'notes': notes,
        },
        options: options,
      );
      return FamilyMemberDrug.fromJson(response.data as Map<String, dynamic>);
    });
  }

  FutureEither<void> removeDrug({
    required String memberId,
    required String drugId,
  }) async {
    return runTask(() async {
      final options = await _authOptions();
      await _dio.delete<dynamic>(
        '/api/profile/family/$memberId/drugs/$drugId',
        options: options,
      );
    });
  }
}
