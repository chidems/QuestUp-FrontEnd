import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../quests/providers/quest_feed_provider.dart';
import '../data/local_photo_cache.dart';
import '../data/weekly_api.dart';
import '../data/weekly_repository.dart';
import '../models/weekly_models.dart';

final weeklyApiProvider =
    Provider<WeeklyApi>((ref) => WeeklyApi(ref.read(dioClientProvider)));

final weeklyRepositoryProvider = Provider<WeeklyRepository>(
  (ref) => WeeklyRepository(ref.read(weeklyApiProvider)),
);

final localPhotoCacheProvider = Provider<LocalPhotoCache>(
  (ref) => LocalPhotoCache(),
);

/// The local file [postId] was shared from, if this device made that post
/// and the file is still on disk. Null means: show the "pending" placeholder.
final localPhotoPathProvider = FutureProvider.family<String?, String>(
  (ref, postId) => ref.read(localPhotoCacheProvider).pathFor(postId),
);

class WeeklyNotifier extends AsyncNotifier<WeeklyData> {
  @override
  Future<WeeklyData> build() => _load();

  Future<WeeklyData> _load() async {
    final repo = ref.read(weeklyRepositoryProvider);
    // The community quest id is needed before posts can be fetched. No
    // active weekly quest (e.g. between weekly cycles) is a normal state.
    final status = await repo.getWeeklyQuest();
    if (status == null) return const WeeklyData(status: null, photos: []);

    final photos = await repo.getPosts(status.quest.id);
    // The backend's is_completed is never sent (see WeeklyQuestStatus.fromJson).
    // The real source of truth is the user's own copy of the quest, which
    // lives in the feed (this endpoint returns the *community* quest, not a
    // per-user one) — its status flips to 'completed' as soon as the user
    // completes it, regardless of whether they also shared a photo. A shared
    // post is kept as a fallback for the gap before the feed refetches.
    final userId = ref.read(authStateProvider).value?.id;
    // .future (not .value) so that when this runs right after completing the
    // quest — both providers get invalidated in the same breath — this waits
    // for the feed's in-flight refetch instead of reading the pre-completion
    // value AsyncValue keeps around while it's still loading.
    final userQuestStatus =
        (await ref.read(questFeedProvider.future)).weeklyQuest?.status;
    final isCompleted = userQuestStatus == 'completed' ||
        (userId != null && photos.any((photo) => photo.userId == userId));
    await scheduleDeadlineReminders(ref, [status.quest]);
    return WeeklyData(
      status: status.copyWith(isCompleted: isCompleted || status.isCompleted),
      photos: photos,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Submits the user's photo/entry to the current weekly community feed.
  /// [userQuestId] is the user's completed weekly quest, when available.
  /// Returns the created post so the caller can cache the local file it came
  /// from (see [LocalPhotoCache]) — the backend can't host it yet.
  Future<WeeklyPhotoPost> sharePhoto({
    required String photoUrl,
    String? userQuestId,
    String? caption,
  }) async {
    final repo = ref.read(weeklyRepositoryProvider);
    // Resolve the community quest id from current state, else fetch it.
    final weeklyQuestId = state.value?.status?.quest.id ??
        (await repo.getWeeklyQuest())?.quest.id;
    if (weeklyQuestId == null) {
      throw StateError('No active weekly community quest to share to.');
    }
    final post = await repo.submit(
      weeklyQuestId: weeklyQuestId,
      userQuestId: userQuestId,
      photoUrl: photoUrl,
      caption: caption,
    );
    await refresh();
    return post;
  }
}

final weeklyProvider =
    AsyncNotifierProvider<WeeklyNotifier, WeeklyData>(WeeklyNotifier.new);
