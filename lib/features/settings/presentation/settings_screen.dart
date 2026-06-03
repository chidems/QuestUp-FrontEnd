import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/quest_constants.dart';
import '../../../core/location/location_service.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../../npc/providers/walking_session_provider.dart';
import '../providers/settings_provider.dart';

const _categoryLabels = {
  QuestType.location: 'Location quests',
  QuestType.social: 'Social quests',
  QuestType.action: 'Action quests',
};

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final walkingActive = ref.watch(walkingSessionProvider).isActive;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load settings.',
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (s) => ListView(
          children: [
            const _SectionLabel('Quest preferences'),
            ListTile(
              title: const Text('Search radius'),
              subtitle: Text('${s.radiusKm.toStringAsFixed(1)} km'),
            ),
            Slider(
              value: s.radiusKm,
              min: 0.5,
              max: 10,
              divisions: 19,
              label: '${s.radiusKm.toStringAsFixed(1)} km',
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setRadius(v),
            ),
            for (final type in _categoryLabels.keys)
              CheckboxListTile(
                title: Text(_categoryLabels[type]!),
                value: s.categories.contains(type),
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleCategory(type),
              ),
            const Divider(),
            const _SectionLabel('Location & walking'),
            SwitchListTile(
              title: const Text('Walking mode'),
              subtitle: const Text('Track walking to meet NPCs'),
              value: walkingActive,
              onChanged: (on) {
                final notifier = ref.read(walkingSessionProvider.notifier);
                on ? notifier.start() : notifier.stop();
              },
            ),
            ListTile(
              title: const Text('Location permission'),
              subtitle: const Text('Manage in system settings'),
              trailing: TextButton(
                onPressed: () => LocationService().openSettings(),
                child: const Text('Open'),
              ),
            ),
            const Divider(),
            const _SectionLabel('Privacy'),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'Weekly quest photos are private by default. They are only '
                'shared to the community page if you choose to share them.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Log out',
                    style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
