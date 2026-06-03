import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../quests/models/quest_models.dart';
import '../models/weekly_models.dart';

class WeeklyApi {
  final Dio _dio;

  WeeklyApi(this._dio);

  Future<WeeklyQuestStatus> getWeeklyQuest() async {
    if (AppConfig.useMockApi) return _mockStatus();
    try {
      final response = await _dio.get('/community/weekly-quest');
      return WeeklyQuestStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<List<WeeklyPhotoPost>> getPhotos() async {
    if (AppConfig.useMockApi) return _mockPhotos();
    try {
      final response = await _dio.get('/community/weekly-quest/photos');
      final data = response.data;
      final list = data is List ? data : (data['photos'] as List? ?? []);
      return list
          .map((e) => WeeklyPhotoPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<WeeklyPhotoPost> sharePhoto({
    required String photoUrl,
    required String questTitle,
    String? caption,
  }) async {
    if (AppConfig.useMockApi) {
      return WeeklyPhotoPost(
        id: 'mock_share',
        userDisplayName: 'Hero',
        photoUrl: photoUrl,
        questTitle: questTitle,
        caption: caption,
        likesCount: 0,
        createdAt: DateTime.now(),
      );
    }
    try {
      final response = await _dio.post(
        '/community/weekly-quest/share-photo',
        data: {
          'photo_url': photoUrl,
          'quest_title': questTitle,
          if (caption != null) 'caption': caption,
        },
      );
      return WeeklyPhotoPost.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  // --- Mock helpers ---

  WeeklyQuestStatus _mockStatus() => const WeeklyQuestStatus(
        isCompleted: false,
        quest: Quest(
          id: '900',
          title: 'Sketch the view from a rooftop',
          description:
              'This week\'s community quest: head somewhere high and sketch '
              'what you see. Share it with the community if you like!',
          questType: 'action',
          source: 'weekly',
          difficulty: 3,
          xpReward: 150,
          coinReward: 100,
          status: 'active',
          requiresPhoto: true,
          isWeekly: true,
        ),
      );

  List<WeeklyPhotoPost> _mockPhotos() => [
        WeeklyPhotoPost(
          id: '1',
          userDisplayName: 'PixelWanderer',
          photoUrl: 'https://placehold.co/600x400/png',
          questTitle: 'Sketch the view from a rooftop',
          caption: 'Caught the sunset from the parkade roof 🌇',
          likesCount: 24,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        WeeklyPhotoPost(
          id: '2',
          userDisplayName: 'QuestKnight',
          photoUrl: 'https://placehold.co/600x400/png',
          questTitle: 'Sketch the view from a rooftop',
          caption: 'My first sketch in years!',
          likesCount: 11,
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
      ];
}
