import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/routing/route_names.dart';
import '../../auth/models/auth_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/presentation/avatar_preview.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../../achievements/presentation/achievement_card.dart';
import '../../achievements/providers/achievements_provider.dart';
import '../models/profile_models.dart';
import '../providers/profile_provider.dart';
import 'stat_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(statsProvider);
                ref.invalidate(achievementsProvider);
                await ref.read(authStateProvider.notifier).refreshUser();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Header(user: user),
                  const SizedBox(height: 24),
                  const _SectionLabel('Life Stats'),
                  const SizedBox(height: 8),
                  const _StatsSection(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: _SectionLabel('Achievements')),
                      TextButton(
                        onPressed: () => context.push(RouteNames.achievements),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const _RecentAchievements(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.push(RouteNames.history),
                    icon: const Icon(Icons.history),
                    label: const Text('Quest History'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Header extends ConsumerWidget {
  final User user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider).value ??
        AvatarAppearance.defaults;
    final progress = (user.totalXp % 100) / 100;

    return Column(
      children: [
        SizedBox(
          width: 160,
          child: AvatarPreview(appearance: appearance),
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text('Level ${user.level}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: context.colors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(context.colors.xpColor),
          ),
        ),
        const SizedBox(height: 4),
        Text('${user.totalXp} XP',
            style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Stat(
                icon: Icons.monetization_on,
                label: '${user.coins}',
                color: context.colors.accent),
            _Stat(
                icon: Icons.local_fire_department,
                label: '${user.currentStreak}',
                color: context.colors.actionQuest),
            _Stat(
                icon: Icons.emoji_events,
                label: 'Best ${user.longestStreak}',
                color: context.colors.rarityLegendary),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Stat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    return stats.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      error: (_, __) => const Text('Could not load stats.'),
      data: (LifeStats s) {
        if (s.values.isEmpty) return const Text('No stats yet.');
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
      loading: () =>
          const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      error: (_, __) => const Text('Could not load achievements.'),
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
