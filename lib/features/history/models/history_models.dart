class QuestHistoryItem {
  final String id;
  final String title;
  final String questType;
  final int xpEarned;
  final int coinsEarned;
  final DateTime? completedAt;
  final String? photoUrl;

  const QuestHistoryItem({
    required this.id,
    required this.title,
    required this.questType,
    required this.xpEarned,
    required this.coinsEarned,
    this.completedAt,
    this.photoUrl,
  });

  factory QuestHistoryItem.fromJson(Map<String, dynamic> json) =>
      QuestHistoryItem(
        id: json['id']?.toString() ?? '',
        title: json['generated_title'] as String? ??
            json['title'] as String? ??
            '',
        questType: json['quest_type'] as String? ?? 'action',
        xpEarned: (json['xp_earned'] as num?)?.toInt() ??
            (json['xp_reward'] as num?)?.toInt() ??
            0,
        coinsEarned: (json['coins_earned'] as num?)?.toInt() ??
            (json['coin_reward'] as num?)?.toInt() ??
            0,
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'].toString())
            : null,
        photoUrl: json['photo_url'] as String?,
      );
}
