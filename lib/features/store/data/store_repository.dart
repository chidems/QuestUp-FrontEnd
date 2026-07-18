import '../../avatar/models/avatar_models.dart';
import 'store_api.dart';

class StoreRepository {
  final StoreApi _api;

  StoreRepository(this._api);

  // The real backend still has a handful of seed items with no matching
  // bundled art (no pixel_asset_key hit and no hosted image_url yet) — hide
  // those rather than show the bare placeholder glyph in the shop.
  Future<List<AvatarItem>> getItems() async {
    final items = await _api.getItems();
    return items.where((item) => item.hasArt).toList();
  }

  Future<void> buy(String itemId) => _api.buy(itemId);
}
