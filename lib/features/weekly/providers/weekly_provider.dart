import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/weekly_api.dart';
import '../data/weekly_repository.dart';
import '../models/weekly_models.dart';

final weeklyApiProvider =
    Provider<WeeklyApi>((ref) => WeeklyApi(ref.read(dioClientProvider)));

final weeklyRepositoryProvider = Provider<WeeklyRepository>(
  (ref) => WeeklyRepository(ref.read(weeklyApiProvider)),
);

class WeeklyNotifier extends AsyncNotifier<WeeklyData> {
  @override
  Future<WeeklyData> build() => _load();

  Future<WeeklyData> _load() async {
    final repo = ref.read(weeklyRepositoryProvider);
    // The community quest id is needed before posts can be fetched.
    final status = await repo.getWeeklyQuest();
    final photos = await repo.getPosts(status.quest.id);
    return WeeklyData(status: status, photos: photos);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Submits the user's photo/entry to the current weekly community feed.
  /// [userQuestId] is the user's completed weekly quest, when available.
  Future<void> sharePhoto({
    required String photoUrl,
    String? userQuestId,
    String? caption,
  }) async {
    final repo = ref.read(weeklyRepositoryProvider);
    // Resolve the community quest id from current state, else fetch it.
    final weeklyQuestId =
        state.value?.status.quest.id ?? (await repo.getWeeklyQuest()).quest.id;
    await repo.submit(
      weeklyQuestId: weeklyQuestId,
      userQuestId: userQuestId,
      photoUrl: photoUrl,
      caption: caption,
    );
    await refresh();
  }
}

final weeklyProvider =
    AsyncNotifierProvider<WeeklyNotifier, WeeklyData>(WeeklyNotifier.new);
