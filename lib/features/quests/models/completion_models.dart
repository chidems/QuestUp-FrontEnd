class PhotoUploadResult {
  final String id;
  final String url;

  const PhotoUploadResult({required this.id, required this.url});

  factory PhotoUploadResult.fromJson(Map<String, dynamic> json) =>
      PhotoUploadResult(
        id: json['id']?.toString() ?? '',
        url: json['url'] as String? ?? '',
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
        id: json['id']?.toString() ?? '',
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

  factory QuestCompletionResult.fromJson(Map<String, dynamic> json) {
    final levelBefore = (json['level_before'] as num?)?.toInt() ?? 0;
    final levelAfter = (json['level_after'] as num?)?.toInt() ?? levelBefore;
    return QuestCompletionResult(
      questId: json['quest_id']?.toString() ?? '',
      xpGained: (json['xp_gained'] as num?)?.toInt() ?? 0,
      coinsGained: (json['coins_gained'] as num?)?.toInt() ?? 0,
      levelBefore: levelBefore,
      levelAfter: levelAfter,
      didLevelUp: json['did_level_up'] as bool? ?? (levelAfter > levelBefore),
      streakCount: (json['streak_count'] as num?)?.toInt() ?? 0,
      statChanges: (json['stat_changes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      unlockedAchievements: (json['unlocked_achievements'] as List<dynamic>? ??
              [])
          .map((e) => RewardAchievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemRewards: (json['item_rewards'] as List<dynamic>? ?? [])
          .map((e) => RewardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      message: json['message'] as String?,
    );
  }
}
