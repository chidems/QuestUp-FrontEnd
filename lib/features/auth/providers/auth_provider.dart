import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    AuthApi(ref.read(dioClientProvider)),
    ref.read(tokenStorageProvider),
  );
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return ref.read(authRepositoryProvider).restoreSession();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(email, password),
    );
  }

  Future<void> register(
    String email,
    String displayName,
    String password,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .register(email, displayName, password),
    );
  }

  // Re-fetches the current user (e.g. after a quest completion changes
  // XP/coins). Keeps the previous value visible while refreshing.
  Future<void> refreshUser() async {
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).restoreSession(),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
