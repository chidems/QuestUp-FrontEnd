class Achievement {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String? category;
  final double progress; // 0.0 .. 1.0
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.category,
    this.progress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  // GET /achievements returns definitions only; per-user progress is merged in
  // from GET /achievements/progress (see AchievementsRepository).
  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlocked = json['is_unlocked'] as bool? ?? false;
    return Achievement(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? json['icon_key'] as String?,
      category: json['category'] as String?,
      progress: ((json['progress'] as num?)?.toDouble() ?? (unlocked ? 1.0 : 0.0))
          .clamp(0.0, 1.0),
      isUnlocked: unlocked,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString())
          : null,
    );
  }

  Achievement copyWith({
    double? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) =>
      Achievement(
        id: id,
        name: name,
        description: description,
        iconUrl: iconUrl,
        category: category,
        progress: progress ?? this.progress,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );
}

/// Per-user row from GET /achievements/progress.
class AchievementProgress {
  final String achievementId;
  final double progress; // 0.0 .. 1.0
  final DateTime? unlockedAt;

  const AchievementProgress({
    required this.achievementId,
    required this.progress,
    this.unlockedAt,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievement_id']?.toString() ?? '',
        progress: ((json['progress'] as num?)?.toDouble() ?? 0.0)
            .clamp(0.0, 1.0),
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.tryParse(json['unlocked_at'].toString())
            : null,
      );
}
