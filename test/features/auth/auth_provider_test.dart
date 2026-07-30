import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/core/storage/token_storage.dart';
import 'package:quest_up/features/auth/data/auth_api.dart';
import 'package:quest_up/features/auth/data/auth_repository.dart';
import 'package:quest_up/features/auth/models/auth_models.dart';
import 'package:quest_up/features/auth/providers/auth_provider.dart';
import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/providers/accepted_quests_provider.dart';
import 'package:quest_up/features/quests/providers/quest_feed_provider.dart';

/// Never touches secure storage or the network — logout()/restoreSession()
/// are overridden below, and nothing else on this class gets called.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(AuthApi(Dio()), TokenStorage());

  int logoutCalls = 0;

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<void> logout() async {
    logoutCalls++;
  }
}

/// Counts real builds (not instance creations) so the test can tell whether
/// invalidate() actually forced a refetch versus serving a cached value.
class _CountingFeedNotifier extends QuestFeedNotifier {
  _CountingFeedNotifier(this.buildCount);
  final List<int> buildCount;

  @override
  Future<QuestFeed> build() async {
    buildCount[0]++;
    return const QuestFeed(normalQuests: []);
  }
}

void main() {
  test('logout invalidates the outgoing account\'s cached quest data, so '
      'the next account on this device gets a fresh fetch instead of stale '
      'data', () async {
    final buildCount = [0];
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      questFeedProvider.overrideWith(() => _CountingFeedNotifier(buildCount)),
    ]);
    addTearDown(container.dispose);

    await container.read(questFeedProvider.future);
    expect(buildCount[0], 1);
    // Re-reading without any invalidation must not refetch.
    await container.read(questFeedProvider.future);
    expect(buildCount[0], 1);

    await container.read(authStateProvider.notifier).logout();

    // The provider is dirty now; reading it again must trigger a real
    // rebuild — a stale cached feed would leave buildCount unchanged.
    await container.read(questFeedProvider.future);
    expect(buildCount[0], 2);
  });

  test('logout resets in-session accepted-quest state, so a quest the '
      'previous account accepted doesn\'t show as active for the next '
      'account', () async {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    ]);
    addTearDown(container.dispose);

    container.read(acceptedQuestIdsProvider.notifier).markAccepted('101');
    expect(container.read(acceptedQuestIdsProvider), {'101'});

    await container.read(authStateProvider.notifier).logout();

    expect(container.read(acceptedQuestIdsProvider), isEmpty);
  });
}
