import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../providers/onboarding_flow_provider.dart';

/// Difficulty tiers 1-5, colored with the palette's existing rarity ramp so
/// the progression reads as familiar instead of introducing new colors.
const difficultyTiers = {
  1: 'Novice',
  2: 'Apprentice',
  3: 'Adventurer',
  4: 'Hero',
  5: 'Legend',
};

Color difficultyTierColor(AppPalette p, int tier) => switch (tier) {
      1 => p.rarityCommon,
      2 => p.rarityUncommon,
      3 => p.rarityRare,
      4 => p.rarityEpic,
      _ => p.rarityLegendary,
    };

/// Step 2: challenge tier picker + roaming range slider. Slider range/step
/// deliberately mirrors the Settings radius slider so they feel like the
/// same control.
class AdventureLevelStep extends ConsumerWidget {
  const AdventureLevelStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final flow = ref.watch(onboardingFlowProvider);
    final notifier = ref.read(onboardingFlowProvider.notifier);
    final tierColor = difficultyTierColor(palette, flow.difficulty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel('CHALLENGE'),
        const SizedBox(height: 6),
        Text(
          'How much of a challenge do you want your quests to be?',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final tier in difficultyTiers.keys) ...[
              if (tier > 1) const SizedBox(width: 6),
              Expanded(
                child: _TierSegment(
                  tier: tier,
                  selected: flow.difficulty == tier,
                  onTap: () => notifier.setDifficulty(tier),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            difficultyTiers[flow.difficulty]!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: tierColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const SizedBox(height: 28),
        _SectionLabel('ROAMING RANGE'),
        const SizedBox(height: 6),
        Text(
          'How far are you willing to roam for a quest?',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        // Same range/step/default as the Settings radius slider.
        Slider(
          value: flow.radiusKm,
          min: 0.5,
          max: 10,
          divisions: 19,
          label: '${flow.radiusKm.toStringAsFixed(1)} km',
          onChanged: notifier.setRadius,
        ),
        Center(
          child: Text(
            '${flow.radiusKm.toStringAsFixed(1)} km',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: palette.accentTeal,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 28),
        PixelButton(
          label: 'Next',
          fullWidth: true,
          onPressed: notifier.nextStep,
        ),
      ],
    );
  }
}

class _TierSegment extends StatelessWidget {
  final int tier;
  final bool selected;
  final VoidCallback onTap;

  const _TierSegment({
    required this.tier,
    required this.selected,
    required this.onTap,
  });

  // Roman numerals keep the segments compact and read as RPG tiers.
  static const _numerals = {1: 'I', 2: 'II', 3: 'III', 4: 'IV', 5: 'V'};

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final color = difficultyTierColor(palette, tier);
    return Semantics(
      button: true,
      selected: selected,
      label: difficultyTiers[tier],
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 46,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.28)
                : palette.surfaceDeep,
            border: Border.all(
              color: selected ? color : palette.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _numerals[tier]!,
              style: TextStyle(
                color: selected ? color : palette.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
