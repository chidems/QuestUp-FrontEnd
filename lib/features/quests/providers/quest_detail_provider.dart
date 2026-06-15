import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quest_models.dart';
import 'accepted_npc_quests_provider.dart';
import 'quest_feed_provider.dart';

final questDetailProvider = FutureProvider.family<Quest, String>((ref, id) {
  // Accepted NPC quests live only in-session, not in the feed payload.
  final npc = ref.read(acceptedNpcQuestsProvider);
  final match = npc.where((q) => q.id == id);
  if (match.isNotEmpty) return Future.value(match.first);
  return ref.read(questRepositoryProvider).getQuest(id);
});
