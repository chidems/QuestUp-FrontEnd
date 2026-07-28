import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/app_config.dart';
import '../../../core/location/location_service.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../data/photo_api.dart';
import '../models/completion_models.dart';
import 'quest_feed_provider.dart';

final photoApiProvider =
    Provider<PhotoApi>((ref) => PhotoApi(ref.read(dioClientProvider)));

/// Drives one quest's completion flow. `null` data means "not submitted yet";
/// loading means uploading/completing; data with a result means success.
///
/// Riverpod 3 family notifiers receive their argument via the constructor
/// (the family create fn is `NotifierT Function(Arg)`), so the quest id is
/// captured here rather than read from a `build(arg)` parameter.
class QuestCompletionNotifier extends AsyncNotifier<QuestCompletionResult?> {
  QuestCompletionNotifier(this._questId);

  final String _questId;

  /// URL of the photo uploaded during [submit], so the weekly share step can
  /// reuse it instead of uploading again. Null if the quest had no photo.
  String? uploadedPhotoUrl;

  @override
  Future<QuestCompletionResult?> build() async => null;

  /// Where the player says they finished, sent so the backend can verify they
  /// were actually at a location quest's target. Best-effort by design: a
  /// player who genuinely did the quest must not be blocked by a bad GPS fix,
  /// so any failure completes the quest without coordinates.
  Future<LatLng?> _completionLocation() async {
    if (AppConfig.useMockApi) return null;
    try {
      return await ref.read(locationServiceProvider).getCurrentLocation();
    } catch (_) {
      return null;
    }
  }

  Future<void> submit({XFile? photo}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      String? photoUrl;
      if (photo != null) {
        final uploaded =
            await ref.read(photoApiProvider).uploadPhoto(File(photo.path));
        photoUrl = uploaded.url;
      }
      uploadedPhotoUrl = photoUrl;

      final where = await _completionLocation();
      final result = await ref.read(questRepositoryProvider).completeQuest(
            _questId,
            photoUrl: photoUrl,
            completionLat: where?.latitude,
            completionLng: where?.longitude,
          );

      // Reflect the new XP/coins/quest list across the app.
      ref.invalidate(questFeedProvider);
      await ref.read(authStateProvider.notifier).refreshUser();
      // A quest was just done today — today's streak nudge is now moot.
      await ref.read(settingsProvider.notifier).recordQuestCompletedToday();

      return result;
    });
  }
}

final questCompletionProvider = AsyncNotifierProvider.autoDispose
    .family<QuestCompletionNotifier, QuestCompletionResult?, String>(
  QuestCompletionNotifier.new,
);
