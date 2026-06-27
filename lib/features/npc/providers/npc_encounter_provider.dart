import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../quests/providers/accepted_npc_quests_provider.dart';
import '../data/npc_api.dart';
import '../models/npc_models.dart';

final npcApiProvider =
    Provider<NpcApi>((ref) => NpcApi(ref.read(dioClientProvider)));

/// Holds the current NPC encounter (null when none). The walking session
/// triggers checks; the feed screen listens and shows the modal.
class NpcEncounterNotifier extends Notifier<NPCEncounter?> {
  @override
  NPCEncounter? build() => null;

  /// Asks the backend whether an NPC spawns now. The walking session reports
  /// location via /walking/session/update before calling this.
  Future<void> checkSpawn() async {
    if (state != null) return; // an encounter is already showing
    try {
      final encounter = await ref.read(npcApiProvider).checkSpawn();
      if (encounter != null) state = encounter;
    } catch (_) {
      // No encounter on failure.
    }
  }

  Future<void> accept() async {
    final encounter = state;
    if (encounter == null) return;
    await ref.read(npcApiProvider).accept(encounter.id);
    // Surface the accepted quest in the active feed (NPC quests aren't part of
    // the regular feed payload).
    final offer = encounter.questOffer;
    if (offer != null) {
      ref.read(acceptedNpcQuestsProvider.notifier).add(offer);
    }
    state = null;
  }

  Future<void> decline() async {
    final encounter = state;
    if (encounter == null) return;
    await ref.read(npcApiProvider).decline(encounter.id);
    state = null;
  }
}

final npcEncounterProvider =
    NotifierProvider<NpcEncounterNotifier, NPCEncounter?>(
  NpcEncounterNotifier.new,
);
