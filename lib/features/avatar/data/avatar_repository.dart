import '../../../core/storage/local_cache.dart';
import '../models/avatar_models.dart';

/// Stores the avatar look locally. The backend has no concept of the bundled
/// sprite ids yet; when it grows appearance endpoints, sync the same payload
/// from here.
///
/// Keyed by user id (same device can be logged into different accounts one
/// after another) so a fresh registration doesn't inherit the previous
/// account's look — each account keeps its own saved appearance across logins
/// on this device instead.
class AvatarRepository {
  static const _kAppearancePrefix = 'avatar_appearance_';

  LocalCache? _cache;

  Future<LocalCache> _ensureCache() async {
    if (_cache case final cache?) return cache;
    final cache = LocalCache();
    await cache.init();
    return _cache = cache;
  }

  Future<AvatarAppearance> getAppearance(String userId) async {
    final cache = await _ensureCache();
    final stored = cache.getString('$_kAppearancePrefix$userId');
    if (stored == null) return AvatarAppearance.defaults;
    try {
      return AvatarAppearance.decode(stored);
    } on FormatException {
      return AvatarAppearance.defaults;
    }
  }

  Future<void> saveAppearance(String userId, AvatarAppearance appearance) async {
    final cache = await _ensureCache();
    await cache.setString('$_kAppearancePrefix$userId', appearance.encode());
  }
}
