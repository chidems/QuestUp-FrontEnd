import '../models/avatar_models.dart';
import 'avatar_api.dart';

class AvatarRepository {
  final AvatarApi _api;

  AvatarRepository(this._api);

  Future<Avatar> getAvatar() => _api.getAvatar();

  Future<List<AvatarItem>> getInventory() => _api.getInventory();

  Future<void> equip(String itemId) => _api.equip(itemId);
}
