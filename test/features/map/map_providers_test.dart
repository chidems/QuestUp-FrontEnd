import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/features/map/providers/map_providers.dart';
import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/providers/quest_feed_provider.dart';

/// Stands in for the real feed notifier (which hits GPS + network) so the test
/// exercises mapQuestsProvider's filtering against a fixed feed.
class _FakeFeedNotifier extends QuestFeedNotifier {
  _FakeFeedNotifier(this._feed);

  final QuestFeed _feed;

  @override
  Future<QuestFeed> build() async => _feed;
}

Quest _quest(String id, {double? lat, double? lng, String source = 'normal'}) =>
    Quest(
      id: id,
      title: 'Quest $id',
      description: '',
      questType: 'location',
      source: source,
      difficulty: 1,
      xpReward: 10,
      coinReward: 5,
      status: 'active',
      targetLatitude: lat,
      targetLongitude: lng,
    );

ProviderContainer _containerFor(QuestFeed feed) {
  final container = ProviderContainer(
    overrides: [
      questFeedProvider.overrideWith(() => _FakeFeedNotifier(feed)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('mapQuestsProvider', () {
    test('keeps only quests that have both coordinates (incl. weekly)',
        () async {
      final feed = QuestFeed(
        normalQuests: [
          _quest('with-coords', lat: 49.2841, lng: -123.1182),
          _quest('no-coords'),
          _quest('lat-only', lat: 49.28),
        ],
        weeklyQuest:
            _quest('weekly', lat: 49.2858, lng: -123.1262, source: 'weekly'),
      );

      final container = _containerFor(feed);
      await container.read(questFeedProvider.future); // let the feed settle

      final ids = container.read(mapQuestsProvider).map((q) => q.id).toList();

      expect(ids, ['with-coords', 'weekly']);
    });

    test('is empty when no quest has coordinates', () async {
      final feed = QuestFeed(
        normalQuests: [_quest('a'), _quest('b')],
      );

      final container = _containerFor(feed);
      await container.read(questFeedProvider.future);

      expect(container.read(mapQuestsProvider), isEmpty);
    });

    test('is empty while the feed has not loaded yet', () {
      final feed = QuestFeed(normalQuests: [_quest('a', lat: 1, lng: 2)]);
      final container = _containerFor(feed);

      // Read without awaiting the feed future: it is still AsyncLoading.
      expect(container.read(mapQuestsProvider), isEmpty);
    });
  });

  group('questsWithCoordinates', () {
    test('filters a feed directly', () {
      final feed = QuestFeed(
        normalQuests: [
          _quest('keep', lat: 1, lng: 2),
          _quest('drop'),
        ],
      );

      expect(
        questsWithCoordinates(feed).map((q) => q.id),
        ['keep'],
      );
    });
  });
}
