import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/features/auth/models/auth_models.dart';
import 'package:quest_up/features/auth/providers/auth_provider.dart';
import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/providers/quest_feed_provider.dart';
import 'package:quest_up/features/weekly/data/weekly_api.dart';
import 'package:quest_up/features/weekly/data/weekly_repository.dart';
import 'package:quest_up/features/weekly/models/weekly_models.dart';
import 'package:quest_up/features/weekly/providers/weekly_provider.dart';

Quest _weeklyQuest({required String status}) => Quest(
      id: '900',
      title: 'Sketch the view',
      description: '',
      questType: 'action',
      source: 'weekly',
      difficulty: 3,
      xpReward: 150,
      coinReward: 100,
      status: status,
      isWeekly: true,
    );

const _me = User(
  id: 'me',
  email: 'me@example.com',
  displayName: 'Me',
  level: 1,
  totalXp: 0,
  coins: 0,
  currentStreak: 0,
  longestStreak: 0,
);

/// Serves a fixed community quest + post list, standing in for the two
/// endpoints WeeklyNotifier stitches together.
class _FakeWeeklyApi extends WeeklyApi {
  _FakeWeeklyApi({required this.status, this.photos = const []})
      : super(Dio());

  final WeeklyQuestStatus status;
  final List<WeeklyPhotoPost> photos;

  @override
  Future<WeeklyQuestStatus?> getWeeklyQuest() async => status;

  @override
  Future<List<WeeklyPhotoPost>> getPosts(String weeklyQuestId) async =>
      photos;
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async => _me;
}

class _FakeFeedNotifier extends QuestFeedNotifier {
  _FakeFeedNotifier(this.feed);
  final QuestFeed feed;

  @override
  Future<QuestFeed> build() async => feed;
}

/// Mimics the feed still being in flight (e.g. right after a quest
/// completion invalidates it) rather than already resolved.
class _SlowFeedNotifier extends QuestFeedNotifier {
  _SlowFeedNotifier(this.feed);
  final QuestFeed feed;

  @override
  Future<QuestFeed> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return feed;
  }
}

Future<ProviderContainer> _containerFor({
  required String userQuestStatus,
  List<WeeklyPhotoPost> photos = const [],
}) async {
  final container = ProviderContainer(overrides: [
    weeklyRepositoryProvider.overrideWithValue(
      WeeklyRepository(
        _FakeWeeklyApi(
          // The community endpoint's own status is never trusted (see
          // WeeklyQuestStatus.fromJson) — only the user's feed copy matters.
          status: WeeklyQuestStatus(
            quest: _weeklyQuest(status: 'active'),
            isCompleted: false,
          ),
          photos: photos,
        ),
      ),
    ),
    authStateProvider.overrideWith(_FakeAuthNotifier.new),
    questFeedProvider.overrideWith(
      () => _FakeFeedNotifier(
        QuestFeed(
          normalQuests: const [],
          weeklyQuest: _weeklyQuest(status: userQuestStatus),
        ),
      ),
    ),
  ]);
  addTearDown(container.dispose);
  await container.read(authStateProvider.future);
  await container.read(questFeedProvider.future);
  return container;
}

void main() {
  group('WeeklyNotifier isCompleted', () {
    test('true once the user\'s own quest instance is completed, even with '
        'no shared photo', () async {
      final container = await _containerFor(userQuestStatus: 'completed');

      final data = await container.read(weeklyProvider.future);

      expect(data.status!.isCompleted, isTrue);
    });

    test('false while the user\'s own quest instance is still accepted',
        () async {
      final container = await _containerFor(userQuestStatus: 'accepted');

      final data = await container.read(weeklyProvider.future);

      expect(data.status!.isCompleted, isFalse);
    });

    test('a shared community photo alone also counts as completed',
        () async {
      final container = await _containerFor(
        userQuestStatus: 'accepted',
        photos: [
          const WeeklyPhotoPost(
            id: '1',
            userId: 'me',
            userDisplayName: 'Me',
            photoUrl: 'https://example.com/x.png',
            questTitle: 'Sketch the view',
          ),
        ],
      );

      final data = await container.read(weeklyProvider.future);

      expect(data.status!.isCompleted, isTrue);
    });

    test('community photos from other users are always returned, regardless '
        'of the current user\'s completion state', () async {
      final container = await _containerFor(
        userQuestStatus: 'accepted',
        photos: [
          const WeeklyPhotoPost(
            id: '1',
            userId: 'someone-else',
            userDisplayName: 'PixelWanderer',
            photoUrl: 'https://example.com/x.png',
            questTitle: 'Sketch the view',
          ),
        ],
      );

      final data = await container.read(weeklyProvider.future);

      expect(data.photos, hasLength(1));
      expect(data.photos.single.userDisplayName, 'PixelWanderer');
      // Someone else's post must not mark *this* user as completed.
      expect(data.status!.isCompleted, isFalse);
    });

    test(
        'reads completed correctly even while questFeedProvider is still '
        'mid-refetch (regression: must await .future, not read a stale '
        '.value)', () async {
      final container = ProviderContainer(overrides: [
        weeklyRepositoryProvider.overrideWithValue(
          WeeklyRepository(
            _FakeWeeklyApi(
              status: WeeklyQuestStatus(
                quest: _weeklyQuest(status: 'active'),
                isCompleted: false,
              ),
            ),
          ),
        ),
        authStateProvider.overrideWith(_FakeAuthNotifier.new),
        // Deliberately NOT pre-awaited below, and its build() takes 20ms —
        // simulating completeQuest() invalidating questFeedProvider and
        // weeklyProvider back-to-back, where the feed refetch is still in
        // flight when weeklyProvider goes to read it.
        questFeedProvider.overrideWith(
          () => _SlowFeedNotifier(
            QuestFeed(
              normalQuests: const [],
              weeklyQuest: _weeklyQuest(status: 'completed'),
            ),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      final data = await container.read(weeklyProvider.future);

      expect(data.status!.isCompleted, isTrue);
    });
  });
}
