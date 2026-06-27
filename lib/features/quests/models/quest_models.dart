class Quest {
  final String id;
  final String title;
  final String description;
  final String questType; // location / social / action
  final String source; // normal / weekly / npc
  final int difficulty;
  final int xpReward;
  final int coinReward;
  final String status; // active / completed / skipped / expired / failed
  final double? targetLatitude;
  final double? targetLongitude;
  final String? targetPlaceName;
  final double? distanceMeters;
  final DateTime? expiresAt;
  final bool requiresPhoto;
  final bool isWeekly;
  final String? npcId;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.questType,
    required this.source,
    required this.difficulty,
    required this.xpReward,
    required this.coinReward,
    required this.status,
    this.targetLatitude,
    this.targetLongitude,
    this.targetPlaceName,
    this.distanceMeters,
    this.expiresAt,
    this.requiresPhoto = false,
    this.isWeekly = false,
    this.npcId,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String? ?? 'normal';
    return Quest(
      id: json['id']?.toString() ?? '',
      // QuestOut uses generated_title/description; community quests use
      // plain title/description. Accept either.
      title: json['generated_title'] as String? ??
          json['title'] as String? ??
          '',
      description: json['generated_description'] as String? ??
          json['description'] as String? ??
          '',
      questType: json['quest_type'] as String? ?? 'action',
      source: source,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      coinReward: (json['coin_reward'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      targetLatitude: (json['target_latitude'] as num?)?.toDouble(),
      targetLongitude: (json['target_longitude'] as num?)?.toDouble(),
      targetPlaceName: json['target_place_name'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
          : null,
      requiresPhoto: json['requires_photo'] as bool? ?? false,
      // The backend doesn't send is_weekly; derive it from the source.
      isWeekly: json['is_weekly'] as bool? ?? (source == 'weekly'),
      npcId: json['npc_id']?.toString(),
    );
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Lv $difficulty';
    }
  }
}

class QuestFeed {
  final List<Quest> normalQuests;
  final Quest? weeklyQuest;
  final bool generatedNewQuests;
  final String? message;

  const QuestFeed({
    required this.normalQuests,
    this.weeklyQuest,
    this.generatedNewQuests = false,
    this.message,
  });

  // Shaped from POST /quests/session/open: { normal: [...], weekly: {...}, ... }.
  factory QuestFeed.fromJson(Map<String, dynamic> json) => QuestFeed(
        normalQuests: (json['normal'] as List<dynamic>? ?? [])
            .map((e) => Quest.fromJson(e as Map<String, dynamic>))
            .toList(),
        weeklyQuest: json['weekly'] != null
            ? Quest.fromJson(json['weekly'] as Map<String, dynamic>)
            : null,
      );
}
