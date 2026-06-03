import '../../quests/models/quest_models.dart';

class WeeklyPhotoPost {
  final String id;
  final String userDisplayName;
  final String photoUrl;
  final String questTitle;
  final String? caption;
  final int? likesCount;
  final DateTime? createdAt;

  const WeeklyPhotoPost({
    required this.id,
    required this.userDisplayName,
    required this.photoUrl,
    required this.questTitle,
    this.caption,
    this.likesCount,
    this.createdAt,
  });

  factory WeeklyPhotoPost.fromJson(Map<String, dynamic> json) => WeeklyPhotoPost(
        id: json['id']?.toString() ?? '',
        userDisplayName: json['user_display_name'] as String? ?? 'Adventurer',
        photoUrl: json['photo_url'] as String? ?? '',
        questTitle: json['quest_title'] as String? ?? '',
        caption: json['caption'] as String?,
        likesCount: (json['likes_count'] as num?)?.toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

class WeeklyQuestStatus {
  final Quest quest;
  final bool isCompleted;

  const WeeklyQuestStatus({required this.quest, required this.isCompleted});

  factory WeeklyQuestStatus.fromJson(Map<String, dynamic> json) {
    // Backend may nest the quest under "quest" or return its fields inline.
    final questJson = json['quest'] as Map<String, dynamic>? ?? json;
    return WeeklyQuestStatus(
      quest: Quest.fromJson(questJson),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

/// Combined payload for the weekly screen: the quest+status and the feed.
class WeeklyData {
  final WeeklyQuestStatus status;
  final List<WeeklyPhotoPost> photos;

  const WeeklyData({required this.status, required this.photos});
}
