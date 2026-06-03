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
    final (status, photos) =
        await (repo.getWeeklyQuest(), repo.getPhotos()).wait;
    return WeeklyData(status: status, photos: photos);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> sharePhoto({
    required String photoUrl,
    required String questTitle,
    String? caption,
  }) async {
    await ref.read(weeklyRepositoryProvider).sharePhoto(
          photoUrl: photoUrl,
          questTitle: questTitle,
          caption: caption,
        );
    await refresh();
  }
}

final weeklyProvider =
    AsyncNotifierProvider<WeeklyNotifier, WeeklyData>(WeeklyNotifier.new);
