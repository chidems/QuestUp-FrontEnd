import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/avatar_repository.dart';
import '../models/avatar_models.dart';

final avatarRepositoryProvider =
    Provider<AvatarRepository>((ref) => AvatarRepository());

/// The user's current avatar look, persisted locally.
class AppearanceNotifier extends AsyncNotifier<AvatarAppearance> {
  @override
  Future<AvatarAppearance> build() =>
      ref.read(avatarRepositoryProvider).getAppearance();

  Future<void> apply(AvatarAppearance next) async {
    await ref.read(avatarRepositoryProvider).saveAppearance(next);
    state = AsyncData(next);
  }
}

final appearanceProvider =
    AsyncNotifierProvider<AppearanceNotifier, AvatarAppearance>(
  AppearanceNotifier.new,
);
