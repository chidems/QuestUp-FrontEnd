import '../../../core/storage/local_cache.dart';
import '../models/avatar_models.dart';

/// Stores the avatar look locally. The backend has no concept of the bundled
/// sprite ids yet; when it grows appearance endpoints, sync the same payload
/// from here.
class AvatarRepository {
  static const _kAppearance = 'avatar_appearance';

  LocalCache? _cache;

  Future<LocalCache> _ensureCache() async {
    if (_cache case final cache?) return cache;
    final cache = LocalCache();
    await cache.init();
    return _cache = cache;
  }

  Future<AvatarAppearance> getAppearance() async {
    final cache = await _ensureCache();
    final stored = cache.getString(_kAppearance);
    if (stored == null) return AvatarAppearance.defaults;
    try {
      return AvatarAppearance.decode(stored);
    } on FormatException {
      return AvatarAppearance.defaults;
    }
  }

  Future<void> saveAppearance(AvatarAppearance appearance) async {
    final cache = await _ensureCache();
    await cache.setString(_kAppearance, appearance.encode());
  }
}
