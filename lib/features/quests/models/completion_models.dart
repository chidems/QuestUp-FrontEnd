class PhotoUploadResult {
  final String id;
  final String url;

  const PhotoUploadResult({required this.id, required this.url});

  // POST /photos/upload-url returns { upload_url, method }.
  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) =>
      PhotoUploadResult(
        id: json['method'] as String? ?? json['id']?.toString() ?? '',
        url: json['upload_url'] as String? ?? json['url'] as String? ?? '',
      );
}

/// Lightweight reward-display models. Full Achievement / AvatarItem models
/// arrive in later phases; these only carry what the reward summary shows.
class RewardAchievement {
  final String id;
  final String name;
  final String? iconUrl;

  const RewardAchievement({required this.id, required this.name, this.iconUrl});

  factory RewardAchievement.fromJson(Map<String, dynamic> json) =>
      RewardAchievement(
        id: json['achievement_id']?.toString() ??
            json['id']?.toString() ??
            '',
        name: json['name'] as String? ?? '',
        iconUrl: json['icon_url'] as String?,
      );
}

class RewardItem {
  final String id;
  final String name;
  final String rarity;
  final String? imageUrl;

  const RewardItem({
    required this.id,
    required this.name,
    required this.rarity,
    this.imageUrl,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) => RewardItem(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        rarity: json['rarity'] as String? ?? 'common',
        imageUrl: json['image_url'] as String?,
      );
}

class QuestCompletionResult {
  final String questId;
  final int xpGained;
  final int coinsGained;
  final int levelBefore;
  final int levelAfter;
  final bool didLevelUp;
  final int streakCount;
  final Map<String, int> statChanges;
  final List<RewardAchievement> unlockedAchievements;
  final List<RewardItem> itemRewards;
  final String? message;

  const QuestCompletionResult({
    required this.questId,
    required this.xpGained,
    required this.coinsGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.didLevelUp,
    required this.streakCount,
    this.statChanges = const {},
    this.unlockedAchievements = const [],
    this.itemRewards = const [],
    this.message,
  });

  // Shaped from POST /quests/{id}/complete.
  factory QuestCompletionResult.fromJson(Map<String, dynamic> json) {
    final levelBefore = (json['previous_level'] as num?)?.toInt() ?? 0;
    final levelAfter = (json['level'] as num?)?.toInt() ?? levelBefore;
    return QuestCompletionResult(
      // The response carries the completion id, not the quest id.
      questId: json['id']?.toString() ?? '',
      xpGained: (json['xp_awarded'] as num?)?.toInt() ?? 0,
      coinsGained: (json['coins_awarded'] as num?)?.toInt() ?? 0,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      didLevelUp: json['leveled_up'] as bool? ?? (levelAfter > levelBefore),
      streakCount: (json['current_streak'] as num?)?.toInt() ?? 0,
      // The backend doesn't break rewards down per life-stat on completion.
      statChanges: const {},
      unlockedAchievements: (json['unlocked_achievements'] as List<dynamic>? ??
              [])
          .map((e) => RewardAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Items are returned as ids (item_awarded_id), not full objects, so no
      // name/rarity to render in the reward summary yet.
      itemRewards: const [],
    );
  }
}
