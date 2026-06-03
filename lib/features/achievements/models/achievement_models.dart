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

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final unlocked = json['is_unlocked'] as bool? ?? false;
    return Achievement(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      category: json['category'] as String?,
      progress: ((json['progress'] as num?)?.toDouble() ?? (unlocked ? 1.0 : 0.0))
          .clamp(0.0, 1.0),
      isUnlocked: unlocked,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.tryParse(json['unlocked_at'].toString())
          : null,
    );
  }
}
