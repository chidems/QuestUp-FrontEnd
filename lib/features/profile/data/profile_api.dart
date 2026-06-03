import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/profile_models.dart';

class ProfileApi {
  final Dio _dio;

  ProfileApi(this._dio);

  Future<LifeStats> getStats() async {
    if (AppConfig.useMockApi) {
      return const LifeStats({
        'social': 8,
        'creativity': 5,
        'exploration': 12,
        'knowledge': 3,
        'fitness': 6,
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
