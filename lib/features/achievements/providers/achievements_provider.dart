import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/achievements_api.dart';
import '../data/achievements_repository.dart';
import '../models/achievement_models.dart';

final achievementsApiProvider = Provider<AchievementsApi>(
  (ref) => AchievementsApi(ref.read(dioClientProvider)),
);

final achievementsRepositoryProvider = Provider<AchievementsRepository>(
  (ref) => AchievementsRepository(ref.read(achievementsApiProvider)),
);

final achievementsProvider = FutureProvider<List<Achievement>>(
  (ref) => ref.read(achievementsRepositoryProvider).getAchievements(),
);
