import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/pixel_progress_bar.dart';
import '../../achievements/presentation/achievement_card.dart';
import '../../achievements/providers/achievements_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/models/history_models.dart';
import '../../history/providers/history_provider.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/presentation/stat_bar.dart';
import '../../profile/providers/profile_provider.dart';
import '../../store/providers/store_provider.dart';
import '../models/avatar_models.dart';
import '../providers/avatar_provider.dart';
import 'avatar_preview.dart';

/// Hero overview: the customized avatar (with a Customize entry point next to
/// it), the player's item collection, level/stats, life stats, an
/// achievements preview, and their logged quest history — the single
/// consolidated identity + progress screen (formerly split across Hero and
/// Stats/Profile tabs).
class HeroScreen extends ConsumerWidget {
  const HeroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront),
            tooltip: 'Shop',
            onPressed: () => context.push(RouteNames.store),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: appearance.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorView(
          message: 'Could not load your avatar.',
          onRetry: () => ref.invalidate(appearanceProvider),
        ),
        data: (a) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(appearanceProvider);
            ref.invalidate(storeProvider);
            ref.invalidate(historyProvider);
            ref.invalidate(statsProvider);
            ref.invalidate(achievementsProvider);
            await ref.read(authStateProvider.notifier).refreshUser();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _AvatarRow(appearance: a),
              const SizedBox(height: 24),
              _SectionLabel('ITEMS'),
              const SizedBox(height: 8),
              const _ItemsSection(),
              const SizedBox(height: 24),
              _SectionLabel('STATS'),
              const SizedBox(height: 8),
              const _StatsSection(),
              const SizedBox(height: 24),
              _SectionLabel('LIFE STATS'),
              const SizedBox(height: 8),
              const _LifeStatsSection(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: _SectionLabel('ACHIEVEMENTS')),
                  TextButton(
                    onPressed: () => context.push(RouteNames.achievements),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _RecentAchievements(),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: _SectionLabel('LOGGED QUESTS')),
                  TextButton(
                    onPressed: () => context.push(RouteNames.history),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const _LoggedQuestsCarousel(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal carousel of the player's recently completed (logged) quests.
class _LoggedQuestsCarousel extends ConsumerWidget {
  const _LoggedQuestsCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return history.when(
      loading: () => const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Could not load your quests.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text(
            'No completed quests yet. Finish a quest to log it here.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return SizedBox(
          height: 158,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _LoggedQuestCard(item: items[i]),
          ),
        );
      },
    );
  }
}

class _LoggedQuestCard extends StatelessWidget {
  final QuestHistoryItem item;
  const _LoggedQuestCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final hasPhoto = item.photoUrl != null && item.photoUrl!.isNotEmpty;
    return SizedBox(
      width: 140,
      child: PixelBox(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.rSmall,
              child: SizedBox(
                height: 70,
                width: double.infinity,
                child: hasPhoto
                    ? CachedNetworkImage(
                        imageUrl: item.photoUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: p.surfaceDeep,
                        child: Center(
                          child: CategoryIcon(
                            questType: item.questType,
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.bolt, size: 13, color: p.xpColor),
                const SizedBox(width: 2),
                Text('${item.xpEarned}',
                    style: TextStyle(
                        color: p.xpColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Icon(Icons.monetization_on, size: 13, color: p.accent),
                const SizedBox(width: 2),
                Text('${item.coinsEarned}',
                    style: TextStyle(
                        color: p.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  final AvatarAppearance appearance;

  const _AvatarRow({required this.appearance});

  @override
  Widget build(BuildContext context) {
    // Fixed-width avatar leaves the rest for the button column; the pixel font
    // is wide, so the label gets a generous, predictable amount of room.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 150, child: AvatarPreview(appearance: appearance)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PixelButton(
                label: 'Customize',
                fullWidth: true,
                onPressed: () => context.push(RouteNames.customize),
              ),
              const SizedBox(height: 10),
              Text(
                'Change your look, outfit and held items.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
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

/// The player's owned items; the ones currently held are marked.
class _ItemsSection extends ConsumerWidget {
  const _ItemsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final appearance = ref.watch(appearanceProvider).value;
    final equippedIds = {appearance?.itemId};

    return store.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        'Could not load your items.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (items) {
        final owned = items.where((i) => i.isOwned).toList();
        if (owned.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No items yet. Complete quests to earn coins, then gear up!',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              PixelButton(
                label: 'Open Shop',
                icon: Icons.storefront,
                variant: PixelButtonVariant.navigation,
                onPressed: () => context.push(RouteNames.store),
              ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in owned)
              _ItemTile(
                item: item,
                equipped: equippedIds.contains(item.id),
              ),
          ],
        );
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final AvatarItem item;
  final bool equipped;

  const _ItemTile({required this.item, required this.equipped});

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Semantics(
      label: equipped ? '${item.name}, held' : item.name,
      child: Tooltip(
        message: item.name,
        child: Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: equipped ? p.surfaceDeep : p.surfaceVariant,
            border: Border.all(
              color: equipped ? p.xpColor : p.border,
              width: equipped ? 2 : 1,
            ),
          ),
          child: item.asset == null
              ? const SizedBox.shrink()
              : Image.asset(
                  item.asset!,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
        ),
      ),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();
    final p = context.colors;
    final xpIntoLevel = user.totalXp % 100;

    return PixelBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Level ${user.level}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatChip(
                icon: Icons.monetization_on,
                color: p.accent,
                label: '${user.coins}',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.local_fire_department,
                color: p.actionQuest,
                label: '${user.currentStreak} day streak',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.emoji_events,
                color: p.rarityLegendary,
                label: 'Best ${user.longestStreak}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          PixelProgressBar(value: xpIntoLevel / 100),
          const SizedBox(height: 6),
          Text(
            '$xpIntoLevel / 100 XP to level ${user.level + 1}'
            ' · ${user.totalXp} XP total',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-life-stat bars (social/creativity/exploration/knowledge/...), scaled
/// against the player's strongest stat.
class _LifeStatsSection extends ConsumerWidget {
  const _LifeStatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    return stats.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Could not load stats.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (LifeStats s) {
        if (s.values.isEmpty) {
          return Text(
            'No stats yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        final max = s.values.values.reduce((a, b) => a > b ? a : b);
        return Column(
          children: [
            for (final key in s.orderedKeys)
              StatBar(
                label: _label(key),
                value: s.values[key]!,
                maxValue: max,
              ),
          ],
        );
      },
    );
  }

  String _label(String key) =>
      key.isEmpty ? key : '${key[0].toUpperCase()}${key.substring(1)}';
}

class _RecentAchievements extends ConsumerWidget {
  const _RecentAchievements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    return achievements.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (_, _) => Text(
        'Could not load achievements.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      data: (items) {
        final unlocked = items.where((a) => a.isUnlocked).take(5).toList();
        if (unlocked.isEmpty) {
          return Text(
            'No achievements unlocked yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          );
        }
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: unlocked.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 220,
              child: AchievementCard(achievement: unlocked[i]),
            ),
          ),
        );
      },
    );
  }
}
