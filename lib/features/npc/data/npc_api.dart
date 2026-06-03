import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../quests/models/quest_models.dart';
import '../models/npc_models.dart';

class NpcApi {
  final Dio _dio;

  NpcApi(this._dio);

  /// Reports walking/location context to the backend. Best-effort.
  Future<void> sessionTick({
    required double latitude,
    required double longitude,
    required int walkingSeconds,
  }) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/walking/session-tick', data: {
        'latitude': latitude,
        'longitude': longitude,
        'walking_seconds': walkingSeconds,
      });
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  /// Asks the backend whether an NPC appears. The backend owns the random
  /// chance; the frontend only reports context. Returns null when none.
  Future<NPCEncounter?> checkEncounter({
    required double latitude,
    required double longitude,
  }) async {
    if (AppConfig.useMockApi) return _mockEncounter();
    try {
      final response = await _dio.post('/npc/check-encounter', data: {
        'latitude': latitude,
        'longitude': longitude,
      });
      final data = response.data;
      if (data == null) return null;
      if (data is Map<String, dynamic>) {
        if (data.isEmpty) return null;
        final encounter = data['encounter'];
        if (encounter is Map<String, dynamic>) {
          return NPCEncounter.fromJson(encounter);
        }
        if (data.containsKey('encounter')) return null; // explicit null
        return NPCEncounter.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> accept(String encounterId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/npc/$encounterId/accept');
    } on DioException catch (e) {
      throw dioErrorToApiException(e);
    }
  }

  Future<void> decline(String encounterId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _dio.post('/npc/$encounterId/decline');
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
          npcId: 'npc1',
        ),
      );
}
