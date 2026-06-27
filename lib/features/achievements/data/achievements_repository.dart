import '../models/achievement_models.dart';
import 'achievements_api.dart';

class AchievementsRepository {
  final AchievementsApi _api;

  AchievementsRepository(this._api);

  /// Merges the achievement catalog with the user's unlock progress so the UI
  /// gets a single list with `progress`, `isUnlocked`, and `unlockedAt` filled.
  Future<List<Achievement>> getAchievements() async {
    final (defs, progress) =
        await (_api.getAchievements(), _api.getProgress()).wait;
    if (progress.isEmpty) return defs;

    final byId = {for (final p in progress) p.achievementId: p};
    return defs.map((a) {
      final p = byId[a.id];
      if (p == null) return a;
      return a.copyWith(
        progress: p.progress,
        isUnlocked: p.unlockedAt != null || p.progress >= 1.0,
        unlockedAt: p.unlockedAt,
      );
    }).toList();
  }
}
