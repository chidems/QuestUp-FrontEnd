import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/avatar_repository.dart';
import '../models/avatar_models.dart';

final avatarRepositoryProvider =
    Provider<AvatarRepository>((ref) => AvatarRepository());

/// The user's current avatar look, persisted locally.
class AppearanceNotifier extends AsyncNotifier<AvatarAppearance> {
  @override
  Future<AvatarAppearance> build() async {
    // Watched (not read): switching accounts on the same device changes this
    // id, which must re-run build() and load *that* account's own saved
    // look — otherwise a freshly registered user would see whichever
    // appearance happened to be cached from whoever used the app before them.
    final userId = ref.watch(authStateProvider.select((auth) => auth.value?.id));
    if (userId == null) return AvatarAppearance.defaults;
    return ref.read(avatarRepositoryProvider).getAppearance(userId);
  }

  Future<void> apply(AvatarAppearance next) async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    await ref.read(avatarRepositoryProvider).saveAppearance(userId, next);
    state = AsyncData(next);
  }
}

final appearanceProvider =
    AsyncNotifierProvider<AppearanceNotifier, AvatarAppearance>(
  AppearanceNotifier.new,
);
