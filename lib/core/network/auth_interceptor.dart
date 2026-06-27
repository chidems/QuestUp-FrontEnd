import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  /// A bare Dio (no auth interceptor) used to refresh tokens and replay the
  /// original request, so a refresh can't recurse back through [onError].
  final Dio _refreshDio;

  AuthInterceptor(this._tokenStorage, this._refreshDio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthCall = path.contains('/auth/refresh') ||
        path.contains('/auth/login') ||
        path.contains('/auth/register');

    if (err.response?.statusCode == 401 && !isAuthCall) {
      final newToken = await _tryRefresh();
      if (newToken != null) {
        try {
          // Replay the original request once with the fresh access token.
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await _refreshDio.fetch(options);
          return handler.resolve(response);
        } catch (_) {
          // Retry failed; fall through to clearing the session below.
        }
      }
      // Refresh impossible/failed: clear stale tokens; the router redirect
      // sends the user to login.
      await _tokenStorage.clearTokens();
    }
    handler.next(err);
  }

  /// Exchanges the stored refresh token for a new pair via `/auth/refresh`.
  /// Returns the new access token, or null if no refresh token / it failed.
  Future<String?> _tryRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      final access = data['access_token'] as String;
      final refresh = data['refresh_token'] as String?;
      await _tokenStorage.saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
      return access;
    } catch (_) {
      return null;
    }
  }
}
