import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../shared/widgets/pixel_button.dart';
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rCard),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: AppRadius.rCard,
          border: Border.all(color: context.colors.primaryLight, width: 2),
          boxShadow: context.colors.softShadow(),
        ),
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
                  child: PixelButton(
                    label: 'Decline',
                    fullWidth: true,
                    variant: PixelButtonVariant.neutral,
                    onPressed: _busy
                        ? null
                        : () => _resolve(
                            ref.read(npcEncounterProvider.notifier).decline),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PixelButton(
                    label: 'Accept',
                    fullWidth: true,
                    isLoading: _busy,
                    onPressed: _busy
                        ? null
                        : () => _resolve(
                            ref.read(npcEncounterProvider.notifier).accept),
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
        color: context.colors.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.primaryLight, width: 2),
      ),
      clipBehavior: Clip.hardEdge,
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          : Icon(Icons.person, size: 48, color: context.colors.primaryLight),
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
        color: context.colors.surfaceVariant,
        borderRadius: AppRadius.rSmall,
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.6)),
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
              Icon(Icons.bolt, size: 16, color: context.colors.xpColor),
              const SizedBox(width: 3),
              Text('${offer.xpReward} XP',
                  style: TextStyle(
                      color: context.colors.xpColor, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Icon(Icons.monetization_on,
                  size: 16, color: context.colors.accent),
              const SizedBox(width: 3),
              Text('${offer.coinReward}',
                  style: TextStyle(
                      color: context.colors.accent, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
