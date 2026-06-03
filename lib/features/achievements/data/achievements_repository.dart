import '../models/achievement_models.dart';
import 'achievements_api.dart';

class AchievementsRepository {
  final AchievementsApi _api;

  AchievementsRepository(this._api);

  Future<List<Achievement>> getAchievements() => _api.getAchievements();
}
