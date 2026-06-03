import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/photo_api.dart';
import '../models/completion_models.dart';
import 'quest_feed_provider.dart';

final photoApiProvider =
    Provider<PhotoApi>((ref) => PhotoApi(ref.read(dioClientProvider)));

/// Drives one quest's completion flow. `null` data means "not submitted yet";
/// loading means uploading/completing; data with a result means success.
class QuestCompletionNotifier
    extends AutoDisposeFamilyAsyncNotifier<QuestCompletionResult?, String> {
  /// URL of the photo uploaded during [submit], so the weekly share step can
  /// reuse it instead of uploading again. Null if the quest had no photo.
  String? uploadedPhotoUrl;

  @override
  Future<QuestCompletionResult?> build(String questId) async => null;

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

      final result = await ref
          .read(questRepositoryProvider)
          .completeQuest(arg, photoUrl: photoUrl);

      // Reflect the new XP/coins/quest list across the app.
      ref.invalidate(questFeedProvider);
      await ref.read(authStateProvider.notifier).refreshUser();

      return result;
    });
  }
}

final questCompletionProvider = AsyncNotifierProvider.autoDispose
    .family<QuestCompletionNotifier, QuestCompletionResult?, String>(
  QuestCompletionNotifier.new,
);
