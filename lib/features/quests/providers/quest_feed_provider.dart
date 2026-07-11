import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/dio_client.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/quest_api.dart';
import '../data/quest_repository.dart';
import '../models/quest_models.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final questApiProvider =
    Provider<QuestApi>((ref) => QuestApi(ref.read(dioClientProvider)));

final questRepositoryProvider =
    Provider<QuestRepository>((ref) => QuestRepository(ref.read(questApiProvider)));

/// Schedules deadline reminders for every quest that has one, if the user has
/// notifications and quest reminders turned on. Shared by the feed, weekly
/// and quest-detail providers — [Quest.expiresAt] covers normal, weekly and
/// NPC quests alike, so there's one scheduling path for all of them.
Future<void> scheduleDeadlineReminders(Ref ref, Iterable<Quest> quests) async {
  final settings = ref.read(settingsProvider).value;
  if (settings == null ||
      !settings.notificationsEnabled ||
      !settings.questReminders) {
    return;
  }
  final service = ref.read(notificationServiceProvider);
  for (final quest in quests) {
    await service.scheduleQuestDeadlineReminder(quest);
  }
}

class QuestFeedNotifier extends AsyncNotifier<QuestFeed> {
  @override
  Future<QuestFeed> build() => _load();

  Future<QuestFeed> _load() async {
    // Mock mode skips GPS so the app runs on any device/emulator.
    final location = AppConfig.useMockApi
        ? const LatLng(49.2827, -123.1207)
        : await ref.read(locationServiceProvider).getCurrentLocation();

    final feed = await ref.read(questRepositoryProvider).getFeed(
          latitude: location.latitude,
          longitude: location.longitude,
          timezone: DateTime.now().timeZoneName,
        );
    await scheduleDeadlineReminders(ref, [
      ...feed.normalQuests,
      if (feed.weeklyQuest case final weekly?) weekly,
    ]);
    return feed;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final questFeedProvider =
    AsyncNotifierProvider<QuestFeedNotifier, QuestFeed>(QuestFeedNotifier.new);
