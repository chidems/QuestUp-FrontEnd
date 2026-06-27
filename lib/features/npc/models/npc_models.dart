import '../../quests/models/quest_models.dart';

class NPCEncounter {
  final String id;
  final String npcName;
  final String? npcImageUrl;
  final String message;
  final Quest? questOffer;
  final DateTime? expiresAt;
  final double? encounterChanceUsed;

  const NPCEncounter({
    required this.id,
    required this.npcName,
    this.npcImageUrl,
    required this.message,
    this.questOffer,
    this.expiresAt,
    this.encounterChanceUsed,
  });

  // Built from an NPC offer object (see /npc/spawn/check, /npc/offers/current):
  // { id, user_id, npc_id, generated_title, generated_description,
  //   xp_reward, coin_reward, status }. The offer's description doubles as the
  // NPC's spoken message, and the offer itself becomes the quest on accept.
  factory NPCEncounter.fromJson(Map<String, dynamic> json) {
    final offer = json['offer'] is Map<String, dynamic>
        ? json['offer'] as Map<String, dynamic>
        : json;
    return NPCEncounter(
      id: offer['id']?.toString() ?? '',
      npcName: offer['npc_name'] as String? ?? 'Mysterious Stranger',
      npcImageUrl: offer['npc_image_url'] as String?,
      message: offer['generated_description'] as String? ??
          offer['message'] as String? ??
          '',
      questOffer: Quest.fromJson({
        'id': offer['id'],
        'generated_title': offer['generated_title'],
        'generated_description': offer['generated_description'],
        'xp_reward': offer['xp_reward'],
        'coin_reward': offer['coin_reward'],
        'source': 'npc',
        'status': 'active',
        'npc_id': offer['npc_id'],
      }),
      expiresAt: offer['expires_at'] != null
          ? DateTime.tryParse(offer['expires_at'].toString())
          : null,
      encounterChanceUsed:
          (offer['encounter_chance_used'] as num?)?.toDouble(),
    );
  }
}
