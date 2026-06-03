import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/avatar_api.dart';
import '../data/avatar_repository.dart';
import '../models/avatar_models.dart';

final avatarApiProvider =
    Provider<AvatarApi>((ref) => AvatarApi(ref.read(dioClientProvider)));

final avatarRepositoryProvider = Provider<AvatarRepository>(
  (ref) => AvatarRepository(ref.read(avatarApiProvider)),
);

class AvatarNotifier extends AsyncNotifier<AvatarData> {
  @override
  Future<AvatarData> build() => _load();

  Future<AvatarData> _load() async {
    final repo = ref.read(avatarRepositoryProvider);
    final (avatar, inventory) =
        await (repo.getAvatar(), repo.getInventory()).wait;
    return AvatarData(avatar: avatar, inventory: inventory);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> equip(String itemId) async {
    await ref.read(avatarRepositoryProvider).equip(itemId);
    await refresh();
  }
}

final avatarProvider =
    AsyncNotifierProvider<AvatarNotifier, AvatarData>(AvatarNotifier.new);
