import '../../quests/models/quest_models.dart';

class WeeklyPhotoPost {
  final String id;
  final String? userId;
  final String userDisplayName;
  final String photoUrl;
  final String questTitle;
  final String? caption;
  final int? likesCount;
  final DateTime? createdAt;

  const WeeklyPhotoPost({
    required this.id,
    this.userId,
    required this.userDisplayName,
    required this.photoUrl,
    required this.questTitle,
    this.caption,
    this.likesCount,
    this.createdAt,
  });

  // Shaped from GET /community/weekly/{id}/posts. The backend exposes the
  // poster's user_id (no display name yet) and no timestamp.
  factory WeeklyPhotoPost.fromJson(Map<String, dynamic> json) => WeeklyPhotoPost(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString(),
        userDisplayName: json['user_display_name'] as String? ??
            json['user_id']?.toString() ??
            'Adventurer',
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

  // Shaped from GET /community/weekly/current (a community quest object). Force
  // the source to "weekly" so the quest renders with weekly styling.
  factory WeeklyQuestStatus.fromJson(Map<String, dynamic> json) {
    final questJson = json['quest'] as Map<String, dynamic>? ?? json;
    return WeeklyQuestStatus(
      quest: Quest.fromJson({'source': 'weekly', ...questJson}),
      // The backend doesn't send is_completed; the caller derives it from
      // the community post feed instead (see WeeklyNotifier._load).
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  WeeklyQuestStatus copyWith({bool? isCompleted}) => WeeklyQuestStatus(
        quest: quest,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

/// Combined payload for the weekly screen: the quest+status and the feed.
class WeeklyData {
  final WeeklyQuestStatus status;
  final List<WeeklyPhotoPost> photos;

  const WeeklyData({required this.status, required this.photos});
}
