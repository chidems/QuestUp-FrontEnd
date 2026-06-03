import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../quests/models/quest_models.dart';
import '../models/npc_models.dart';
import '../providers/npc_encounter_provider.dart';

class NpcEncounterModal extends ConsumerStatefulWidget {
  final NPCEncounter encounter;

  const NpcEncounterModal({super.key, required this.encounter});

  @override
  ConsumerState<NpcEncounterModal> createState() => _NpcEncounterModalState();
}

class _NpcEncounterModalState extends ConsumerState<NpcEncounterModal> {
  bool _busy = false;

  Future<void> _resolve(Future<void> Function() action) async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      navigator.pop();
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.encounter;
    final offer = e.questOffer;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NpcAvatar(imageUrl: e.npcImageUrl),
            const SizedBox(height: 12),
            Text(
              e.npcName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              e.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (offer != null) ...[
              const SizedBox(height: 16),
              _OfferCard(offer: offer),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _resolve(
                            ref.read(npcEncounterProvider.notifier).decline),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy
                        ? null
                        : () => _resolve(
                            ref.read(npcEncounterProvider.notifier).accept),
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NpcAvatar extends StatelessWidget {
  final String? imageUrl;
  const _NpcAvatar({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryLight, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          : const Icon(Icons.person, size: 48, color: AppColors.primaryLight),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Quest offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border.all(color: AppColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            offer.title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            offer.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: AppColors.xpColor),
              const SizedBox(width: 3),
              Text('${offer.xpReward} XP',
                  style: const TextStyle(
                      color: AppColors.xpColor, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              const Icon(Icons.monetization_on,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 3),
              Text('${offer.coinReward}',
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
