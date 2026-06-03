import '../models/weekly_models.dart';
import 'weekly_api.dart';

class WeeklyRepository {
  final WeeklyApi _api;

  WeeklyRepository(this._api);

  Future<WeeklyQuestStatus> getWeeklyQuest() => _api.getWeeklyQuest();

  Future<List<WeeklyPhotoPost>> getPhotos() => _api.getPhotos();

  Future<WeeklyPhotoPost> sharePhoto({
    required String photoUrl,
    required String questTitle,
    String? caption,
  }) =>
      _api.sharePhoto(
        photoUrl: photoUrl,
        questTitle: questTitle,
        caption: caption,
      );
}
