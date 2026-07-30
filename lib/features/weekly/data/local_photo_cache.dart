import 'dart:io';

import '../../../core/storage/local_cache.dart';

/// Maps a submitted community post to the local file it was shared from.
///
/// The backend has nowhere to actually host shared photos yet — every
/// `photo_url` it returns is a `local://` placeholder with nothing behind it
/// (see BACKEND_CHANGES_COMMUNITY_PHOTOS.md) — so this is what lets the
/// device that made a post show the real photo instead of a "pending"
/// placeholder. It only works on that same device: nobody else's photos can
/// resolve this way until the backend actually hosts images.
class LocalPhotoCache {
  static const _prefix = 'local_shared_photo_';

  LocalCache? _cache;

  Future<LocalCache> _ensureCache() async {
    if (_cache case final cache?) return cache;
    final cache = LocalCache();
    await cache.init();
    return _cache = cache;
  }

  Future<void> savePath(String postId, String path) async {
    final cache = await _ensureCache();
    await cache.setString('$_prefix$postId', path);
  }

  /// The local file for [postId], if this device shared it and the file is
  /// still on disk (picked images live in a cache dir the OS can reclaim).
  Future<String?> pathFor(String postId) async {
    final cache = await _ensureCache();
    final path = cache.getString('$_prefix$postId');
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }
}
