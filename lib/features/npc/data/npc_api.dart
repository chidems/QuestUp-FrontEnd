import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../quests/models/quest_models.dart';
import '../models/npc_models.dart';

class NpcApi {
  final Dio _dio;

  NpcApi(this._dio);

  // --- Walking sessions ---

  /// Starts a walking session and returns its id (null in mock mode).
  Future<String?> startWalkingSession({
    required double latitude,
    required double longitude,
  }) async {
    if (AppConfig.useMockApi) return 'mock_session';
    try {
      final response = await _dio.post('/walking/session/start', data: {
        'lat': latitude,
        'lng': longitude,
      });
      final data = response.data;
      return data is Map<String, dynamic> ? data['id']?.toString() : null;
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> updateWalkingSession({
    required String sessionId,
    required double latitude,
    required double longitude,
    double? speedMps,
  }) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/walking/session/update', data: {
        'session_id': sessionId,
        'lat': latitude,
        'lng': longitude,
        if (speedMps != null) 'speed_mps': speedMps,
      });
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> endWalkingSession(String sessionId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/walking/session/end',
          queryParameters: {'session_id': sessionId});
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  // --- NPC offers ---

  /// Asks the backend whether an NPC spawns. The backend owns the chance.
  /// Returns the offer as an encounter, or null when none.
  Future<NPCEncounter?> checkSpawn() async {
    if (AppConfig.useMockApi) return _mockEncounter();
    try {
      final response = await _dio.post('/npc/spawn/check');
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;
      if (data['npc_spawned'] != true) return null;
      final offer = data['offer'];
      if (offer is! Map<String, dynamic>) return null;
      return NPCEncounter.fromJson(offer);
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> accept(String offerId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/npc/offers/$offerId/accept');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> decline(String offerId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/npc/offers/$offerId/decline');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  NPCEncounter _mockEncounter() => NPCEncounter(
        id: 'npc1',
        npcName: 'Old Merchant Finn',
        message:
            'Ah, traveler! You look spry today. Fancy a little side quest?',
        encounterChanceUsed: 0.7,
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        questOffer: const Quest(
          id: 'npc-q1',
          title: 'Deliver a kind word',
          description: 'Tell a stranger something genuinely encouraging.',
          questType: 'social',
          source: 'npc',
          difficulty: 1,
          xpReward: 60,
          coinReward: 30,
          status: 'active',
          // Demo coordinate ~0.3 km NE of the mock center, for the Map tab.
          targetLatitude: 49.2849,
          targetLongitude: -123.1172,
          distanceMeters: 320,
          npcId: 'npc1',
        ),
      );
}
