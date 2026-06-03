import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/quests/presentation/quest_feed_screen.dart';
import '../../features/quests/presentation/quest_detail_screen.dart';
import '../../features/quests/presentation/quest_completion_screen.dart';
import '../../features/weekly/presentation/weekly_quest_screen.dart';
import '../../features/avatar/presentation/avatar_screen.dart';
import '../../features/store/presentation/store_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/history/presentation/quest_history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Use a ChangeNotifier so GoRouter re-evaluates redirects on auth changes
  // without recreating the entire router instance.
  final notifier = _AuthChangeNotifier();

  ref.listen(authStateProvider, (_, __) => notifier.notify());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: RouteNames.login,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authValue = ref.read(authStateProvider);

      // Still initialising — don't redirect yet.
      if (authValue.isLoading) return null;

      final isLoggedIn = authValue.valueOrNull != null;
      final onAuthScreen = state.matchedLocation == RouteNames.login ||
          state.matchedLocation == RouteNames.register;

      if (!isLoggedIn && !onAuthScreen) return RouteNames.login;
      if (isLoggedIn && onAuthScreen) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.questDetail,
        builder: (_, state) =>
            QuestDetailScreen(questId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.questComplete,
        builder: (_, state) =>
            QuestCompletionScreen(questId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RouteNames.store,
        builder: (_, __) => const StoreScreen(),
      ),
      GoRoute(
        path: RouteNames.achievements,
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: RouteNames.history,
        builder: (_, __) => const QuestHistoryScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.home,
              builder: (_, __) => const QuestFeedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.weekly,
              builder: (_, __) => const WeeklyQuestScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.avatar,
              builder: (_, __) => const AvatarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: RouteNames.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});

class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
