import '../models/quest_models.dart';
import '../models/completion_models.dart';
import 'quest_api.dart';

class QuestRepository {
  final QuestApi _api;

  QuestRepository(this._api);

  Future<QuestFeed> getFeed({
    required double latitude,
    required double longitude,
    required String timezone,
  }) =>
      _api.getFeed(
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
      );

  Future<Quest> getQuest(String id) => _api.getQuest(id);

  Future<Quest> acceptQuest(String id) => _api.acceptQuest(id);

  Future<Quest> skipQuest(String id) => _api.skipQuest(id);

  Future<QuestCompletionResult> completeQuest(
    String id, {
    String? photoUrl,
    String? caption,
    String? notes,
    int? rating,
    bool sharedToCommunity = false,
    double? completionLat,
    double? completionLng,
  }) =>
      _api.completeQuest(
        id,
        photoUrl: photoUrl,
        caption: caption,
        notes: notes,
        rating: rating,
        sharedToCommunity: sharedToCommunity,
        completionLat: completionLat,
        completionLng: completionLng,
      );
}
