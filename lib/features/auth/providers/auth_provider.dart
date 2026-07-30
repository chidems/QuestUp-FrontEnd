import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../achievements/providers/achievements_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../quests/providers/accepted_npc_quests_provider.dart';
import '../../quests/providers/accepted_quests_provider.dart';
import '../../quests/providers/quest_detail_provider.dart';
import '../../quests/providers/quest_feed_provider.dart';
import '../../store/providers/store_provider.dart';
import '../../weekly/providers/weekly_provider.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    AuthApi(ref.read(dioClientProvider)),
    ref.read(tokenStorageProvider),
  );
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> register(
    String email,
    String displayName,
    String password,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(email, displayName, password),
    );
  }

  // Re-fetches the current user (e.g. after a quest completion changes
  // XP/coins). Keeps the previous value visible while refreshing.
  Future<void> refreshUser() async {
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).restoreSession(),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
    // These providers cache the outgoing account's data in memory (quests,
    // store, stats...) and are never otherwise invalidated. Without this, the
    // next account to log in on this device — e.g. a fresh registration —
    // would see the previous account's quests, achievements, etc. until
    // something happened to force a refetch. appearanceProvider and
    // onboardingPendingProvider aren't listed here: they key themselves off
    // the current user id and already reload correctly on their own.
    ref.invalidate(questFeedProvider);
    ref.invalidate(questDetailProvider);
    ref.invalidate(acceptedQuestIdsProvider);
    ref.invalidate(acceptedNpcQuestsProvider);
    ref.invalidate(weeklyProvider);
    ref.invalidate(storeProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(statsProvider);
    ref.invalidate(userProfileProvider);
    ref.invalidate(historyProvider);
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
