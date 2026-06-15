import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import '../../features/quests/models/completion_models.dart';
import 'pixel_button.dart';
import 'pixel_confetti.dart';
import 'rarity_badge.dart';

/// Shows the post-completion reward summary. Resolves when dismissed.
Future<void> showRewardSummary(
  BuildContext context,
  QuestCompletionResult result,
) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RewardSummaryModal(result: result),
  );
}

class RewardSummaryModal extends StatefulWidget {
  final QuestCompletionResult result;

  const RewardSummaryModal({super.key, required this.result});

  @override
  State<RewardSummaryModal> createState() => _RewardSummaryModalState();
}

class _RewardSummaryModalState extends State<RewardSummaryModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller.forward();
    if (widget.result.didLevelUp) {
      // Heavy thump when the level-up banner lands.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) HapticFeedback.heavyImpact();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Sub-animation over a slice of the controller's timeline.
  Animation<double> _slice(double begin, double end,
          [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final result = widget.result;

    // Banner reveals stagger after the stats row.
    var bannerIndex = 0;
    Animation<double> nextBanner() {
      final begin = (0.55 + bannerIndex * 0.08).clamp(0.0, 0.85);
      bannerIndex++;
      return _slice(begin, begin + 0.15);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rCard),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: AppRadius.rCard,
              border: Border.all(color: p.accent, width: 2),
              boxShadow: p.softShadow(),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _slice(0.0, 0.4, Curves.elasticOut),
                  child: Icon(Icons.emoji_events, color: p.accent, size: 48),
                ),
                const SizedBox(height: 8),
                _Reveal(
                  animation: _slice(0.1, 0.35),
                  child: Text(
                    'Quest Complete!',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (result.message != null) ...[
                  const SizedBox(height: 4),
                  _Reveal(
                    animation: _slice(0.15, 0.4),
                    child: Text(
                      result.message!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _Reveal(
                  animation: _slice(0.3, 0.55),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, _) {
                      // Numbers count up while the row settles in.
                      final c = _slice(0.3, 0.7).value;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _RewardStat(
                              icon: Icons.bolt,
                              label: '+${(result.xpGained * c).round()} XP',
                              color: p.xpColor),
                          const SizedBox(width: 20),
                          _RewardStat(
                              icon: Icons.monetization_on,
                              label: '+${(result.coinsGained * c).round()}',
                              color: p.accent),
                          const SizedBox(width: 20),
                          _RewardStat(
                              icon: Icons.local_fire_department,
                              label: '${result.streakCount}',
                              color: p.actionQuest),
                        ],
                      );
                    },
                  ),
                ),
                if (result.didLevelUp) ...[
                  const SizedBox(height: 16),
                  _Reveal(
                    animation: nextBanner(),
                    child: _Banner(
                      icon: Icons.arrow_upward,
                      text:
                          'Level up! ${result.levelBefore} → ${result.levelAfter}',
                      color: p.primaryLight,
                    ),
                  ),
                ],
                if (result.statChanges.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _Reveal(
                    animation: nextBanner(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: result.statChanges.entries
                          .map((e) => _Pill('+${e.value} ${_label(e.key)}'))
                          .toList(),
                    ),
                  ),
                ],
                for (final a in result.unlockedAchievements) ...[
                  const SizedBox(height: 12),
                  _Reveal(
                    animation: nextBanner(),
                    child: _Banner(
                      icon: Icons.military_tech,
                      text: 'Achievement: ${a.name}',
                      color: p.xpColor,
                    ),
                  ),
                ],
                for (final item in result.itemRewards) ...[
                  const SizedBox(height: 12),
                  _Reveal(
                    animation: nextBanner(),
                    child: _Banner(
                      icon: Icons.card_giftcard,
                      text: 'Item: ${item.name}',
                      color: rarityColor(p, item.rarity),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                _Reveal(
                  animation: _slice(0.85, 1.0),
                  child: PixelButton(
                    label: 'Awesome!',
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          if (result.didLevelUp)
            const Positioned.fill(child: PixelConfetti()),
        ],
      ),
    );
  }

  String _label(String key) =>
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
}

/// Fade + small upward slide driven by [animation].
class _Reveal extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _Reveal({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}

class _RewardStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RewardStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Banner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: context.colors.surfaceVariant),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
