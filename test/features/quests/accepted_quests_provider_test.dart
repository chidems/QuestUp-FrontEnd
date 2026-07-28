import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quest_up/features/quests/data/quest_api.dart';
import 'package:quest_up/features/quests/data/quest_repository.dart';
import 'package:quest_up/features/quests/models/quest_models.dart';
import 'package:quest_up/features/quests/providers/accepted_npc_quests_provider.dart';
import 'package:quest_up/features/quests/providers/accepted_quests_provider.dart';
import 'package:quest_up/features/quests/providers/quest_feed_provider.dart';

Quest _quest(
  String id, {
  String source = 'normal',
  bool isWeekly = false,
  String status = 'active',
}) =>
    Quest(
      id: id,
      title: 'Quest $id',
      description: '',
      questType: 'action',
      source: source,
      difficulty: 1,
      xpReward: 10,
      coinReward: 5,
      status: status,
      isWeekly: isWeekly,
    );

/// Records accept/skip calls instead of hitting the network. Only those two
/// are exercised, so the inherited members keep their real (unused) bodies.
class _FakeRepository extends QuestRepository {
  _FakeRepository() : super(QuestApi(Dio()));

  final acceptedIds = <String>[];
  final skippedIds = <String>[];

  @override
  Future<Quest> acceptQuest(String id) async {
    acceptedIds.add(id);
    return _quest(id, status: 'accepted');
  }

  @override
  Future<Quest> skipQuest(String id) async {
    skippedIds.add(id);
    return _quest(id, status: 'skipped');
  }
}

({ProviderContainer container, _FakeRepository repository}) _setUp() {
  final repository = _FakeRepository();
  final container = ProviderContainer(
    overrides: [questRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return (container: container, repository: repository);
}

void main() {
  group('AcceptedQuestIdsNotifier', () {
    test('accept records the quest and calls the backend once', () async {
      final (:container, :repository) = _setUp();
      final notifier = container.read(acceptedQuestIdsProvider.notifier);

      await notifier.accept('101');
      await notifier.accept('101'); // already accepted — no second call

      expect(repository.acceptedIds, ['101']);
      expect(
        isQuestAccepted(_quest('101'), container.read(acceptedQuestIdsProvider)),
        isTrue,
      );
    });

    test('a quest starts out available, not active', () {
      final (:container, repository: _) = _setUp();

      expect(
        isQuestAccepted(_quest('101'), container.read(acceptedQuestIdsProvider)),
        isFalse,
      );
    });

    test('abandon skips the quest on the backend', () async {
      final (:container, :repository) = _setUp();
      final notifier = container.read(acceptedQuestIdsProvider.notifier);

      await notifier.accept('101');
      await notifier.abandon('101');

      // A local drop alone would be undone by the backend, which has no route
      // from `accepted` back to `active` — the skip call is what makes it real.
      expect(repository.skippedIds, ['101']);
      expect(
        isQuestAccepted(_quest('101'), container.read(acceptedQuestIdsProvider)),
        isFalse,
      );
    });

    test('abandon drops an NPC quest entirely — it has no feed entry', () async {
      final (:container, repository: _) = _setUp();
      final npc = _quest('npc-1', source: 'npc');
      container.read(acceptedNpcQuestsProvider.notifier).add(npc);
      container.read(acceptedQuestIdsProvider.notifier).markAccepted(npc.id);

      expect(container.read(acceptedNpcQuestsProvider), [npc]);

      await container.read(acceptedQuestIdsProvider.notifier).abandon(npc.id);

      expect(container.read(acceptedNpcQuestsProvider), isEmpty);
      expect(
        isQuestAccepted(npc, container.read(acceptedQuestIdsProvider)),
        isFalse,
      );
    });

    test('a backend-accepted quest stays active across a restart', () {
      // Fresh container = no session state, as after an app restart. The
      // backend still reports the quest as accepted, so it must not fall
      // back into the available pool (re-accepting it would 400).
      final (:container, repository: _) = _setUp();

      expect(
        isQuestAccepted(
          _quest('101', status: 'accepted'),
          container.read(acceptedQuestIdsProvider),
        ),
        isTrue,
      );
    });

    test('the weekly quest counts as active without being accepted', () {
      final (:container, repository: _) = _setUp();

      expect(
        isQuestAccepted(
          _quest('900', source: 'weekly', isWeekly: true),
          container.read(acceptedQuestIdsProvider),
        ),
        isTrue,
      );
    });
  });
}
