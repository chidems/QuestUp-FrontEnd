import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../avatar/models/avatar_models.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../data/store_api.dart';
import '../data/store_repository.dart';

final storeApiProvider =
    Provider<StoreApi>((ref) => StoreApi(ref.read(dioClientProvider)));

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => StoreRepository(ref.read(storeApiProvider)),
);

class StoreNotifier extends AsyncNotifier<List<AvatarItem>> {
  @override
  Future<List<AvatarItem>> build() => _load();

  Future<List<AvatarItem>> _load() =>
      ref.read(storeRepositoryProvider).getItems();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> buy(String itemId) async {
    await ref.read(storeRepositoryProvider).buy(itemId);
    // Reflect the purchase: store flags, owned inventory, and coin balance.
    await refresh();
    ref.invalidate(avatarProvider);
    await ref.read(authStateProvider.notifier).refreshUser();
  }
}

final storeProvider =
    AsyncNotifierProvider<StoreNotifier, List<AvatarItem>>(StoreNotifier.new);
