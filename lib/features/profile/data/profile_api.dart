import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/profile_models.dart';

class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  Future<UserProfile> getProfile() async {
    if (AppConfig.useMockApi) {
      return const UserProfile(
        preferredRadiusKm: 2.0,
        preferredDifficulty: null,
        preferredQuestTypes: ['location', 'social', 'action'],
      );
    }
    try {
      final response = await _dio.get('/profile');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    if (AppConfig.useMockApi) return profile;
    try {
      final response =
          await _dio.put('/profile', data: profile.toUpdateJson());
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<LifeStats> getStats() async {
    if (AppConfig.useMockApi) {
      return const LifeStats({
        'social': 8,
        'creativity': 5,
        'exploration': 12,
        'knowledge': 3,
      });
    }
    try {
      final response = await _dio.get('/profile/stats');
      return LifeStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }
}
