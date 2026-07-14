import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_box.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../quests/models/quest_models.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/map_providers.dart';
import 'map_pins.dart';

/// Nearby quests on a retro-styled Google Map. Centers on the user, draws the
/// preferred-radius circle, and drops a pixel-art pin per quest that has
/// coordinates (color-coded by category; teal flag = weekly, purple "!" =
/// NPC). Tapping a pin opens a themed info card with a jump to the quest.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _controller;
  String? _darkStyle;
  String? _lightStyle;

  @override
  void initState() {
    super.initState();
    _loadStyles();
  }

  Future<void> _loadStyles() async {
    final dark = await rootBundle.loadString('assets/map_style/map_style_dark.json');
    final light =
        await rootBundle.loadString('assets/map_style/map_style_light.json');
    if (!mounted) return;
    setState(() {
      _darkStyle = dark;
      _lightStyle = light;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _recenter(LatLng center) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(center, 15),
    );
  }

  Future<void> _focusQuest(Quest quest) async {
    ref.read(selectedMapQuestProvider.notifier).select(quest);
    await _controller?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(quest.targetLatitude!, quest.targetLongitude!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final centerAsync = ref.watch(mapCenterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: centerAsync.when(
        loading: () => const LoadingView(message: 'Finding your location...'),
        error: (_, __) => ErrorView(
          message: 'Could not get your location.',
          onRetry: () => ref.invalidate(mapCenterProvider),
        ),
        data: (center) => _MapView(
          center: center,
          darkStyle: _darkStyle,
          lightStyle: _lightStyle,
          onMapCreated: (c) => _controller = c,
          onRecenter: () => _recenter(center),
          onQuestTap: _focusQuest,
        ),
      ),
    );
  }
}

class _MapView extends ConsumerWidget {
  final LatLng center;
  final String? darkStyle;
  final String? lightStyle;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onRecenter;
  final ValueChanged<Quest> onQuestTap;

  const _MapView({
    required this.center,
    required this.darkStyle,
    required this.lightStyle,
    required this.onMapCreated,
    required this.onRecenter,
    required this.onQuestTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final settings = ref.watch(settingsProvider).value;
    // Dark is the default theme; mirror that fallback here.
    final darkMode = settings?.darkMode ?? true;
    final radiusKm = settings?.radiusKm ?? 2.0;
    final quests = ref.watch(mapQuestsProvider);
    final pinIcons = ref.watch(mapPinIconsProvider).value;
    final selected = ref.watch(selectedMapQuestProvider);

    final markers = {
      if (pinIcons != null)
        for (final q in quests)
          Marker(
            markerId: MarkerId(q.id),
            position: LatLng(q.targetLatitude!, q.targetLongitude!),
            icon: pinIcons[questPinKey(q)]!,
            anchor: const Offset(0.5, 1.0),
            onTap: () => onQuestTap(q),
          ),
    };

    final circles = {
      Circle(
        circleId: const CircleId('preferred_radius'),
        center: center,
        radius: radiusKm * 1000,
        fillColor: palette.accent.withValues(alpha: 0.12),
        strokeColor: palette.accent,
        strokeWidth: 2,
      ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 15),
          style: darkMode ? darkStyle : lightStyle,
          onMapCreated: onMapCreated,
          markers: markers,
          circles: circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          // Tapping empty map dismisses the quest card.
          onTap: (_) =>
              ref.read(selectedMapQuestProvider.notifier).select(null),
        ),
        // Quest-count badge.
        Positioned(
          top: 12,
          left: 12,
          child: PixelBox(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              quests.length == 1 ? '1 quest nearby' : '${quests.length} quests nearby',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: palette.textPrimary),
            ),
          ),
        ),
        // Recenter control; slides up when the quest card is open.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          bottom: selected != null ? 196 : 16,
          right: 16,
          child: PixelButton(
            label: 'Recenter',
            icon: Icons.my_location,
            variant: PixelButtonVariant.navigation,
            onPressed: onRecenter,
          ),
        ),
        // Tapped-pin quest card.
        if (selected case final quest?)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _QuestCard(
              quest: quest,
              onClose: () =>
                  ref.read(selectedMapQuestProvider.notifier).select(null),
            ),
          ),
      ],
    );
  }
}

/// Info card for the tapped pin: category art, title, reward/distance chips,
/// a source badge for weekly/NPC quests, and a jump to the quest detail.
class _QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback onClose;

  const _QuestCard({required this.quest, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final isNpc = quest.source == 'npc';

    return PixelBox(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryIcon(questType: quest.questType, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (quest.targetPlaceName case final place?) ...[
                      const SizedBox(height: 2),
                      Text(place, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 20, color: p.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.star,
                color: p.primaryLight,
                label: quest.difficultyLabel,
              ),
              _InfoChip(
                icon: Icons.bolt,
                color: p.xpColor,
                label: '${quest.xpReward} XP',
              ),
              _InfoChip(
                icon: Icons.monetization_on,
                color: p.accent,
                label: '${quest.coinReward}',
              ),
              if (quest.distanceMeters case final meters?)
                _InfoChip(
                  icon: Icons.directions_walk,
                  color: p.textSecondary,
                  label: _distanceLabel(meters),
                ),
              if (isNpc)
                _InfoChip(
                  icon: Icons.priority_high,
                  color: p.primary,
                  label: 'NPC QUEST',
                ),
              if (quest.isWeekly)
                _InfoChip(
                  icon: Icons.flag,
                  color: p.accentTeal,
                  label: 'WEEKLY',
                ),
            ],
          ),
          const SizedBox(height: 12),
          PixelButton(
            label: 'View Quest',
            fullWidth: true,
            onPressed: () => context.push('/quests/${quest.id}'),
          ),
        ],
      ),
    );
  }

  String _distanceLabel(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(1)} km'
      : '${meters.round()} m';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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
