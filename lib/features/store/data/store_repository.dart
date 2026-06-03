import '../../avatar/models/avatar_models.dart';
import 'store_api.dart';

class StoreRepository {
  final StoreApi _api;

  StoreRepository(this._api);

  Future<List<AvatarItem>> getItems() => _api.getItems();

  Future<void> buy(String itemId) => _api.buy(itemId);
}
