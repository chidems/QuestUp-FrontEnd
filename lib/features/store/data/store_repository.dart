import '../../avatar/models/avatar_models.dart';
import 'store_api.dart';

class StoreRepository {
  final StoreApi _api;

  StoreRepository(this._api);

  // Two calls because ownership lives outside the store listing: the catalog
  // says what exists, the inventory says what the player already bought.
  //
  // The real backend still has a handful of seed items with no matching
  // bundled art (no pixel_asset_key hit and no hosted image_url yet) — hide
  // those rather than show the bare placeholder glyph in the shop.
  Future<List<AvatarItem>> getItems() async {
    final items = await _api.getItems();
    final ownedIds = await _api.getOwnedItemIds();
    return [
      for (final item in items)
        if (item.hasArt) item.copyWith(isOwned: ownedIds.contains(item.id)),
    ];
  }

  Future<void> buy(String itemId) => _api.buy(itemId);
}
