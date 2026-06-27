import '../models/weekly_models.dart';
import 'weekly_api.dart';

class WeeklyRepository {
  final WeeklyApi _api;

  WeeklyRepository(this._api);

  Future<WeeklyQuestStatus> getWeeklyQuest() => _api.getWeeklyQuest();

  Future<List<WeeklyPhotoPost>> getPosts(String weeklyQuestId) =>
      _api.getPosts(weeklyQuestId);

  Future<WeeklyPhotoPost> submit({
    required String weeklyQuestId,
    String? userQuestId,
    String? photoUrl,
    String? caption,
  }) =>
      _api.submit(
        weeklyQuestId: weeklyQuestId,
        userQuestId: userQuestId,
        photoUrl: photoUrl,
        caption: caption,
      );
}
