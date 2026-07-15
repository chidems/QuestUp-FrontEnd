import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/pixel_badge.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/presentation/avatar_preview.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../providers/onboarding_flow_provider.dart';
import 'adventure_level_screen.dart';

/// How each inferred quest type reads in the reveal headline.
const _typePhrases = {
  QuestType.location: 'discovering new places',
  QuestType.social: 'connecting with people',
  QuestType.action: 'staying active',
};

/// Step 3: the payoff — the user's hero beside a summary card of their
/// picks, with a personalized headline. Confirming submits everything.
class AdventurerRevealStep extends ConsumerWidget {
  final Future<void> Function() onConfirm;

  const AdventurerRevealStep({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final flow = ref.watch(onboardingFlowProvider);
    final appearance =
        ref.watch(appearanceProvider).value ?? AvatarAppearance.defaults;
    final tierName = difficultyTiers[flow.difficulty]!;
    final tierColor = difficultyTierColor(palette, flow.difficulty);

    final questTypes = flow.questTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(width: 130, child: AvatarPreview(appearance: appearance)),
        ),
        const SizedBox(height: 16),
        Text(
          _headline(questTypes, tierName),
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold, height: 1.4),
        ),
        const SizedBox(height: 20),
        PixelBox(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (final type in questTypes) ...[
                    CategoryIcon(questType: type, size: 40),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  PixelBadge(label: tierName, color: tierColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions_walk,
                      size: 16, color: palette.accentTeal),
                  const SizedBox(width: 6),
                  Text(
                    '${flow.radiusKm.toStringAsFixed(1)} km roam radius',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'These shape the quests you get. You can adjust your '
                'search radius anytime in Settings.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PixelButton(
          label: 'Start Questing',
          fullWidth: true,
          isLoading: flow.submitting,
          onPressed: flow.submitting ? null : () => onConfirm(),
        ),
      ],
    );
  }

  /// e.g. "Your quests will lean toward discovering new places &
  /// staying active — at Hero level."
  String _headline(Set<String> questTypes, String tierName) {
    if (questTypes.length == 3) {
      return 'Your quests will cover a bit of everything — '
          'at $tierName level.';
    }
    final phrases = [
      for (final entry in _typePhrases.entries)
        if (questTypes.contains(entry.key)) entry.value,
    ];
    return 'Your quests will lean toward ${phrases.join(' & ')} — '
        'at $tierName level.';
  }
}
