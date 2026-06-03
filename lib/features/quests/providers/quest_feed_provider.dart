import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/dio_client.dart';
import '../data/quest_api.dart';
import '../data/quest_repository.dart';
import '../models/quest_models.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final questApiProvider =
    Provider<QuestApi>((ref) => QuestApi(ref.read(dioClientProvider)));

final questRepositoryProvider =
    Provider<QuestRepository>((ref) => QuestRepository(ref.read(questApiProvider)));

class QuestFeedNotifier extends AsyncNotifier<QuestFeed> {
  @override
  Future<QuestFeed> build() => _load();

  Future<QuestFeed> _load() async {
    // Mock mode skips GPS so the app runs on any device/emulator.
    final location = AppConfig.useMockApi
        ? const LatLng(49.2827, -123.1207)
        : await ref.read(locationServiceProvider).getCurrentLocation();

    return ref.read(questRepositoryProvider).getFeed(
          latitude: location.latitude,
          longitude: location.longitude,
          timezone: DateTime.now().timeZoneName,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final questFeedProvider =
    AsyncNotifierProvider<QuestFeedNotifier, QuestFeed>(QuestFeedNotifier.new);
