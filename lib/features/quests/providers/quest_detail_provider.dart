import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_models.dart';
import 'accepted_npc_quests_provider.dart';
import 'quest_feed_provider.dart';

final questDetailProvider =
    FutureProvider.family<Quest, String>((ref, id) async {
  // Accepted NPC quests live only in-session, not in the feed payload.
  final npc = ref.read(acceptedNpcQuestsProvider);
  final match = npc.where((q) => q.id == id);
  final quest = match.isNotEmpty
      ? match.first
      : await ref.read(questRepositoryProvider).getQuest(id);
  await scheduleDeadlineReminders(ref, [quest]);
  return quest;
});
