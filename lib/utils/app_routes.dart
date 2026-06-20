import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/firebase.dart';
import '../views/mobile/auth/login_view.dart';
import '../views/mobile/home/home_shell.dart';
import '../views/mobile/home/home_view.dart';
import '../views/mobile/home/schedule/schedule_view.dart';
import '../views/mobile/home/profile/profile_view.dart';
import '../views/mobile/splash_view.dart';

class GoRouterNotifier extends ChangeNotifier {
  GoRouterNotifier() {
    FBAuth.auth.authStateChanges().listen((_) => notifyListeners());
  }

  bool get isLoggedIn => FBAuth.auth.currentUser != null;
}

GoRouter buildRouter(GoRouterNotifier notifier) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = notifier.isLoggedIn;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      final onLogin = loc == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashView()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginView()),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeView()),
          ),
          GoRoute(
            path: '/home/schedule',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ScheduleView(),
            ),
          ),
          GoRoute(
            path: '/home/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileView(),
            ),
          ),
        ],
      ),
    ],
  );
}
