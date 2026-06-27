import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import 'auth_api.dart';

class AuthRepository {
  final AuthApi _api;
  final TokenStorage _tokenStorage;

  AuthRepository(this._api, this._tokenStorage);

  Future<User> login(String email, String password) async {
    final tokens =
        await _api.login(LoginRequest(email: email, password: password));
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    // Login returns only tokens; the user comes from /auth/me.
    return _api.getMe();
  }

  Future<User> register(
    String email,
    String displayName,
    String password,
  ) async {
    final tokens = await _api.register(RegisterRequest(
      email: email,
      displayName: displayName,
      password: password,
    ));
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return _api.getMe();
  }

  // Returns the current user from the server if a stored token exists.
  Future<User?> restoreSession() async {
    final token = await _tokenStorage.getAccessToken();
    if (token == null) return null;
    try {
      return await _api.getMe();
    } catch (_) {
      await _tokenStorage.clearTokens();
      return null;
    }
  }

  Future<void> logout() => _tokenStorage.clearTokens();
}
