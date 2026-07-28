import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_models.dart';
import 'accepted_npc_quests_provider.dart';
import 'quest_feed_provider.dart';

/// Ids of quests accepted during this session. The backend is the real source
/// of truth (it persists an `accepted` status); this is an optimistic overlay
/// so a freshly accepted quest moves to the active list immediately, without
/// waiting for the feed to refetch.
class AcceptedQuestIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  Future<void> accept(String id) async {
    if (state.contains(id)) return;
    await ref.read(questRepositoryProvider).acceptQuest(id);
    state = {...state, id};
  }

  /// Records a quest accepted through another flow (NPC encounters have their
  /// own accept endpoint), so it lands in the active list like any other.
  void markAccepted(String id) => state = {...state, id};

  /// Abandoning is permanent: the backend has no route from `accepted` back to
  /// `active`, so this skips the quest instead. Refetching the feed drops it
  /// and pulls in the replacement the backend generates.
  Future<void> abandon(String id) async {
    await ref.read(questRepositoryProvider).skipQuest(id);
    state = {...state}..remove(id);
    // NPC quests live only in-session, so drop the object as well.
    ref.read(acceptedNpcQuestsProvider.notifier).remove(id);
    ref.invalidate(questFeedProvider);
  }
}

final acceptedQuestIdsProvider =
    NotifierProvider<AcceptedQuestIdsNotifier, Set<String>>(
  AcceptedQuestIdsNotifier.new,
);

/// Whether [quest] belongs in the active list. `status == 'accepted'` is the
/// backend's own record, so accepted quests stay active across restarts;
/// [acceptedIds] covers the gap before the feed refetches. The weekly quest is
/// assigned rather than picked up, so it always counts as active.
bool isQuestAccepted(Quest quest, Set<String> acceptedIds) =>
    quest.isWeekly ||
    quest.status == 'accepted' ||
    acceptedIds.contains(quest.id);
