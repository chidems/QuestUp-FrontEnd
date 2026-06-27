import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/achievement_models.dart';

class AchievementsApi {
  final Dio _dio;

  AchievementsApi(this._dio);

  Future<List<Achievement>> getAchievements() async {
    if (AppConfig.useMockApi) return _mock();
    try {
      final response = await _dio.get('/achievements');
      final data = response.data;
      final list = data is List ? data : (data['achievements'] as List? ?? []);
      return list
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  /// Per-user unlock progress, merged onto the definitions by the repository.
  Future<List<AchievementProgress>> getProgress() async {
    if (AppConfig.useMockApi) return const [];
    try {
      final response = await _dio.get('/achievements/progress');
      final data = response.data;
      final list = data is List ? data : (data['progress'] as List? ?? []);
      return list
          .map((e) => AchievementProgress.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  List<Achievement> _mock() => [
        Achievement(
          id: 'a1',
          name: 'First Steps',
          description: 'Complete your first quest.',
          category: 'milestone',
          progress: 1,
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Achievement(
          id: 'a2',
          name: 'Social Butterfly',
          description: 'Complete 5 social quests.',
          category: 'social',
          progress: 1,
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        const Achievement(
          id: 'a3',
          name: 'Explorer',
          description: 'Visit 10 new locations.',
          category: 'exploration',
          progress: 0.4,
        ),
        const Achievement(
          id: 'a4',
          name: 'Streak Master',
          description: 'Reach a 14-day streak.',
          category: 'milestone',
          progress: 0.35,
        ),
        const Achievement(
          id: 'a5',
          name: 'Legendary Look',
          description: 'Equip a legendary item.',
          category: 'avatar',
          progress: 0,
        ),
      ];
}
