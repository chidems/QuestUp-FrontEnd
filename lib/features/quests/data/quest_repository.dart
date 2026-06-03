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

  Future<QuestCompletionResult> completeQuest(String id, {String? photoUrl}) =>
      _api.completeQuest(id, photoUrl: photoUrl);
}
