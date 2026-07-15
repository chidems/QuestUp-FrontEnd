import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';
import '../../auth/providers/auth_provider.dart';

/// Whether the signed-in user still needs the onboarding wizard.
///
/// The backend has no `onboarding_completed` flag yet (see
/// BACKEND_CHANGES_ONBOARDING.md), so this is the plan's documented local
/// fallback: a per-user "pending" flag in LocalCache. [markPending] is set on
/// register (only new users see onboarding — logging in on a fresh device
/// never re-prompts), and cleared by [markCompleted] when the wizard submits.
/// A kill mid-wizard leaves the flag pending, so restarting resumes it.
///
/// When the backend field ships, swap the cache read below for
/// `userProfileProvider`'s `onboarding_completed` and keep the same API.
class OnboardingStatusNotifier extends AsyncNotifier<bool> {
  static const _keyPrefix = 'pref_onboarding_pending_';

  /// Set by the register screen just before calling register, so that when
  /// the auth state flips and this notifier rebuilds for the new user id,
  /// it already knows this session is a fresh registration — no race with
  /// the router redirect.
  static bool _expectNewUser = false;

  static void expectNewUser() => _expectNewUser = true;

  /// Call when a registration attempt fails, so a later login on this
  /// device isn't misread as a new account.
  static void cancelExpectNewUser() => _expectNewUser = false;

  LocalCache? _cache;

  @override
  Future<bool> build() async {
    final userId = ref.watch(
      authStateProvider.select((auth) => auth.value?.id),
    );
    if (userId == null) return false;
    final cache = LocalCache();
    await cache.init();
    _cache = cache;
    final key = '$_keyPrefix$userId';
    if (_expectNewUser) {
      _expectNewUser = false;
      await cache.setBool(key, true);
      return true;
    }
    return cache.getBool(key) ?? false;
  }

  Future<void> markCompleted() async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId != null) {
      await _cache?.setBool('$_keyPrefix$userId', false);
    }
    state = const AsyncData(false);
  }
}

/// True when the current user should be shown the onboarding wizard.
final onboardingPendingProvider =
    AsyncNotifierProvider<OnboardingStatusNotifier, bool>(
  OnboardingStatusNotifier.new,
);
