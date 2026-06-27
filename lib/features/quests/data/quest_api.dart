import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../models/quest_models.dart';
import '../models/completion_models.dart';

class QuestApi {
  final Dio _dio;

  QuestApi(this._dio);

  /// Opens an app session: tops up normal quests, returns the weekly quest and
  /// progression. `lat`/`lng` are both-or-neither per the backend contract.
  Future<QuestFeed> getFeed({
    required double latitude,
    required double longitude,
    required String timezone,
  }) async {
    if (AppConfig.useMockApi) return _mockFeed();
    try {
      final response = await _dio.post('/quests/session/open', data: {
        'lat': latitude,
        'lng': longitude,
        'timezone': timezone,
      });
      return QuestFeed.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<Quest> acceptQuest(String id) async {
    if (AppConfig.useMockApi) return _mockFeed().normalQuests.first;
    try {
      final response = await _dio.post('/quests/$id/accept');
      return Quest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<Quest> skipQuest(String id) async {
    if (AppConfig.useMockApi) return _mockFeed().normalQuests.first;
    try {
      final response = await _dio.post('/quests/$id/skip');
      return Quest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<Quest> getQuest(String id) async {
    if (AppConfig.useMockApi) {
      return _mockFeed().normalQuests.firstWhere(
            (q) => q.id == id,
            orElse: () => _mockFeed().weeklyQuest!,
          );
    }
    try {
      final response = await _dio.get('/quests/$id');
      return Quest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<QuestCompletionResult> completeQuest(
    String id, {
    String? photoUrl,
    String? caption,
    String? notes,
    int? rating,
    bool sharedToCommunity = false,
    double? completionLat,
    double? completionLng,
  }) async {
    if (AppConfig.useMockApi) return _mockCompletion(id);
    try {
      final response = await _dio.post('/quests/$id/complete', data: {
        if (photoUrl != null) 'photo_url': photoUrl,
        if (caption != null) 'caption': caption,
        if (notes != null) 'notes': notes,
        if (rating != null) 'rating': rating,
        'shared_to_community': sharedToCommunity,
        // completion_lat/lng are both-or-neither per the backend contract.
        if (completionLat != null && completionLng != null) ...{
          'completion_lat': completionLat,
          'completion_lng': completionLng,
        },
      });
      return QuestCompletionResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  // --- Mock helpers ---

  QuestCompletionResult _mockCompletion(String id) => QuestCompletionResult(
        questId: id,
        xpGained: 50,
        coinsGained: 20,
        levelBefore: 3,
        levelAfter: 3,
        didLevelUp: false,
        streakCount: 6,
        statChanges: const {'exploration': 1},
        message: 'Quest complete! Nice work.',
      );

  QuestFeed _mockFeed() => QuestFeed(
        generatedNewQuests: true,
        message: 'Quest feed loaded',
        normalQuests: const [
          Quest(
            id: '101',
            title: 'Explore a new neighborhood cafe',
            description:
                'Find a cafe you have never visited, order something new, '
                'and snap a photo of your drink.',
            questType: 'location',
            source: 'normal',
            difficulty: 1,
            xpReward: 50,
            coinReward: 20,
            status: 'active',
            targetLatitude: 49.2841,
            targetLongitude: -123.1182,
            targetPlaceName: 'Revolver Coffee',
            distanceMeters: 420,
            requiresPhoto: true,
          ),
          Quest(
            id: '102',
            title: 'Compliment 3 strangers today',
            description:
                'Brighten someone\'s day. Give a genuine compliment to three '
                'different people you meet.',
            questType: 'social',
            source: 'normal',
            difficulty: 2,
            xpReward: 80,
            coinReward: 35,
            status: 'active',
            // Demo coordinate ~0.45 km SW of the mock center, for the Map tab.
            targetLatitude: 49.2796,
            targetLongitude: -123.1248,
            requiresPhoto: false,
          ),
        ],
        weeklyQuest: const Quest(
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
          // Demo coordinate ~0.55 km NW of the mock center, for the Map tab.
          targetLatitude: 49.2858,
          targetLongitude: -123.1262,
          requiresPhoto: true,
          isWeekly: true,
        ),
      );
}
