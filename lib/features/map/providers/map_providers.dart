import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart' as loc;
import '../../../core/theme/app_palette.dart';
import '../../quests/models/quest_models.dart';
import '../../quests/providers/accepted_npc_quests_provider.dart';
import '../../quests/providers/quest_feed_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../presentation/map_pins.dart';

/// Fixed demo location used in mock mode. Matches the coordinates baked into
/// the mock quest fixtures (see QuestApi._mockFeed).
const mapDemoCenter = LatLng(49.2827, -123.1207);

/// The map's center: the user's current location. Mirrors questFeedProvider's
/// strategy — a fixed demo point under USE_MOCK_API (so it runs on any
/// emulator), real GPS via the shared LocationService otherwise.
final mapCenterProvider = FutureProvider<LatLng>((ref) async {
  if (AppConfig.useMockApi) return mapDemoCenter;
  final loc.LatLng pos =
      await ref.read(locationServiceProvider).getCurrentLocation();
  return LatLng(pos.latitude, pos.longitude);
});

/// Quests from the active feed that carry map coordinates, plus any accepted
/// NPC quests (those live only in-session, outside the feed payload). Derived
/// state — the Map tab reuses what's already fetched instead of refetching.
/// Returns an empty list while the feed is still loading or errored.
final mapQuestsProvider = Provider<List<Quest>>((ref) {
  final feed = ref.watch(questFeedProvider).value;
  final npc = ref.watch(acceptedNpcQuestsProvider);
  if (feed == null) return questsWithCoordinates(null, extras: npc);
  return questsWithCoordinates(feed, extras: npc);
});

/// Pure filter: the quests in [feed] (normal + weekly) and [extras] that have
/// both a target latitude and longitude, deduped by id. Kept top-level so it
/// is trivially testable.
List<Quest> questsWithCoordinates(QuestFeed? feed,
    {List<Quest> extras = const []}) {
  final all = <Quest>[
    ...?feed?.normalQuests,
    if (feed?.weeklyQuest case final weekly?) weekly,
    ...extras,
  ];
  final seen = <String>{};
  return all
      .where((q) => q.targetLatitude != null && q.targetLongitude != null)
      .where((q) => seen.add(q.id))
      .toList();
}

/// The quest whose pin was tapped; the map screen shows its info card.
/// Cleared by tapping elsewhere on the map or closing the card.
class SelectedMapQuestNotifier extends Notifier<Quest?> {
  @override
  Quest? build() => null;

  void select(Quest? quest) => state = quest;
}

final selectedMapQuestProvider =
    NotifierProvider<SelectedMapQuestNotifier, Quest?>(
  SelectedMapQuestNotifier.new,
);

/// The pixel-art marker bitmaps, keyed by [questPinKey] values. Regenerated
/// when the theme flips so pin colors track the active palette.
final mapPinIconsProvider = FutureProvider<Map<String, BitmapDescriptor>>(
  (ref) async {
    final darkMode = ref.watch(
      settingsProvider.select((s) => s.value?.darkMode ?? true),
    );
    final palette = darkMode ? AppPalette.dark : AppPalette.light;
    final dpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    return renderQuestPins(palette, dpr);
  },
);
