import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart' as loc;
import '../../quests/models/quest_models.dart';
import '../../quests/providers/quest_feed_provider.dart';

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

/// Quests from the active feed that carry map coordinates. Derived from
/// [questFeedProvider] — the Map tab reuses the feed instead of fetching again.
/// Returns an empty list while the feed is still loading or errored.
final mapQuestsProvider = Provider<List<Quest>>((ref) {
  final feed = ref.watch(questFeedProvider).value;
  if (feed == null) return const [];
  return questsWithCoordinates(feed);
});

/// Pure filter: the quests in [feed] (normal + weekly) that have both a
/// target latitude and longitude. Kept top-level so it is trivially testable.
List<Quest> questsWithCoordinates(QuestFeed feed) {
  final all = <Quest>[
    ...feed.normalQuests,
    if (feed.weeklyQuest != null) feed.weeklyQuest!,
  ];
  return all
      .where((q) => q.targetLatitude != null && q.targetLongitude != null)
      .toList();
}
