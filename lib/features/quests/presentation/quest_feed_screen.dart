import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/location/location_service.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/pixel_progress_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/auth_models.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../../avatar/presentation/avatar_preview.dart';
import '../../npc/models/npc_models.dart';
import '../../npc/providers/npc_encounter_provider.dart';
import '../../npc/presentation/npc_encounter_modal.dart';
import '../../npc/presentation/walking_status_banner.dart';
import '../models/quest_models.dart';
import '../providers/accepted_npc_quests_provider.dart';
import '../providers/quest_feed_provider.dart';
import 'quest_card.dart';

class QuestFeedScreen extends ConsumerWidget {
  const QuestFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(questFeedProvider);
    final user = ref.watch(authStateProvider).value;

    // Show the NPC encounter modal when the walking session triggers one.
    ref.listen<NPCEncounter?>(npcEncounterProvider, (prev, next) {
      if (next != null && prev == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => NpcEncounterModal(encounter: next),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Quests')),
      body: Column(
        children: [
          if (user != null) _WelcomeHeader(user: user),
          const WalkingStatusBanner(),
          Expanded(
            child: feed.when(
              loading: () =>
                  const LoadingView(message: 'Finding quests near you...'),
              error: (error, _) => _FeedError(
                error: error,
                onRetry: () => ref.read(questFeedProvider.notifier).refresh(),
                onOpenSettings: () =>
                    ref.read(locationServiceProvider).openSettings(),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () => ref.read(questFeedProvider.notifier).refresh(),
                child: _FeedBody(
                  feed: data,
                  npcQuests: ref.watch(acceptedNpcQuestsProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  final QuestFeed feed;
  final List<Quest> npcQuests;
  const _FeedBody({required this.feed, required this.npcQuests});

  @override
  Widget build(BuildContext context) {
    // NPC quests lead the active list so the player notices the one they just
    // accepted; the feed's own quests follow.
    final active = [...npcQuests, ...feed.normalQuests];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (feed.weeklyQuest != null) ...[
          _SectionHeader('Weekly Quest'),
          const SizedBox(height: 8),
          _StaggerIn(
            index: 0,
            child: QuestCard(
              quest: feed.weeklyQuest!,
              featured: true,
              onTap: () => context.push('/quests/${feed.weeklyQuest!.id}'),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeader('Active Quests'),
        const SizedBox(height: 8),
        if (active.isEmpty)
          const EmptyState(
            icon: Icons.explore_off,
            message:
                'No active quests right now.\n'
                'Pull down to refresh and find new ones.',
          )
        else
          for (var i = 0; i < active.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StaggerIn(
                index: i + 1,
                child: QuestCard(
                  quest: active[i],
                  onTap: () => context.push('/quests/${active[i].id}'),
                ),
              ),
            ),
      ],
    );
  }
}

/// Entrance animation: fade + small upward slide, staggered by [index]
/// (capped so long lists don't keep the bottom cards waiting).
class _StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;

  const _StaggerIn({required this.index, required this.child});

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final CurvedAnimation _anim = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 50 * widget.index.clamp(0, 8)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(_anim),
        child: widget.child,
      ),
    );
  }
}

/// Distinguishes location problems (with an actionable button) from generic
/// failures.
class _FeedError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const _FeedError({
    required this.error,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isLocation = error is LocationException;
    final canOpenSettings =
        error is LocationException &&
        (error as LocationException).canOpenSettings;
    final message = error is LocationException
        ? (error as LocationException).message
        : 'We could not load your quests. Try refreshing or moving to '
              'another area.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLocation ? Icons.location_off : Icons.error_outline,
              size: 48,
              color: context.colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (canOpenSettings)
              PixelButton(label: 'Open settings', onPressed: onOpenSettings)
            else
              PixelButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.colors.textSecondary,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// Welcome header: greeting, the player's circular character avatar (taps
/// through to the Hero tab), their level progress and coin balance.
class _WelcomeHeader extends ConsumerWidget {
  final User user;
  const _WelcomeHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(appearanceProvider).value ?? AvatarAppearance.defaults;
    // Placeholder XP-to-next-level (100 XP/level) until the backend exposes
    // the real threshold.
    final progress = (user.totalXp % 100) / 100;

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Your hero. Opens the Hero tab.',
            child: GestureDetector(
              onTap: () => context.go(RouteNames.avatar),
              child: AvatarHeadCircle(appearance: appearance, size: 54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: context.colors.textMuted),
                ),
                Text(
                  user.displayName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Lv ${user.level}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: context.colors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'XP to next level',
                        value: '${(progress * 100).round()} percent',
                        child: PixelProgressBar(value: progress, height: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HudChip(
            icon: Icons.monetization_on,
            label: '${user.coins}',
            semanticLabel: '${user.coins} coins. Opens shop.',
            color: context.colors.accent,
            // Coins are spendable — tap through to the shop.
            onTap: () => context.push(RouteNames.store),
          ),
        ],
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String semanticLabel;
  final Color color;
  final VoidCallback? onTap;

  const _HudChip({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // The icon+number row reads poorly on its own ("12"), so it is excluded
    // and replaced by [semanticLabel] on the merged node.
    Widget chip = ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
    if (onTap != null) {
      chip = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 48dp minimum tap target for the interactive chip.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Center(widthFactor: 1, child: chip),
        ),
      );
    }
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: chip,
      ),
    );
  }
}
