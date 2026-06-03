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

  factory NPCEncounter.fromJson(Map<String, dynamic> json) => NPCEncounter(
        id: json['id']?.toString() ?? '',
        npcName: json['npc_name'] as String? ?? 'Mysterious Stranger',
        npcImageUrl: json['npc_image_url'] as String?,
        message: json['message'] as String? ?? '',
        questOffer: json['quest_offer'] is Map<String, dynamic>
            ? Quest.fromJson(json['quest_offer'] as Map<String, dynamic>)
            : null,
        expiresAt: json['expires_at'] != null
            ? DateTime.tryParse(json['expires_at'].toString())
            : null,
        encounterChanceUsed:
            (json['encounter_chance_used'] as num?)?.toDouble(),
      );
}
