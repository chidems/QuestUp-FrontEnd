import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../quests/providers/quest_feed_provider.dart';
import '../data/npc_api.dart';
import '../models/npc_models.dart';

final npcApiProvider =
    Provider<NpcApi>((ref) => NpcApi(ref.read(dioClientProvider)));

/// Holds the current NPC encounter (null when none). The walking session
/// triggers checks; the feed screen listens and shows the modal.
class NpcEncounterNotifier extends Notifier<NPCEncounter?> {
  @override
  NPCEncounter? build() => null;

  Future<void> sessionTick({
    required double latitude,
    required double longitude,
    required int walkingSeconds,
  }) async {
    try {
      await ref.read(npcApiProvider).sessionTick(
            latitude: latitude,
            longitude: longitude,
            walkingSeconds: walkingSeconds,
          );
    } catch (_) {
      // Best-effort context reporting; ignore failures.
    }
  }

  Future<void> checkEncounter({
    required double latitude,
    required double longitude,
  }) async {
    if (state != null) return; // an encounter is already showing
    try {
      final encounter = await ref
          .read(npcApiProvider)
          .checkEncounter(latitude: latitude, longitude: longitude);
      if (encounter != null) state = encounter;
    } catch (_) {
      // No encounter on failure.
    }
  }

  Future<void> accept() async {
    final encounter = state;
    if (encounter == null) return;
    await ref.read(npcApiProvider).accept(encounter.id);
    ref.invalidate(questFeedProvider); // NPC quest joins the active list
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
