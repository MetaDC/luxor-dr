import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/firebase.dart';
import '../views/mobile/auth/login_view.dart';
import '../views/mobile/home/home_shell.dart';
import '../views/mobile/home/home_view.dart';
import '../views/mobile/home/schedule/schedule_view.dart';
import '../views/mobile/home/profile/profile_view.dart';
import '../views/mobile/home/contacts/contacts_view.dart';
import '../views/mobile/splash_view.dart';
import '../views/mobile/deactivated_view.dart';
import '../controllers/auth_ctrl.dart';

class GoRouterNotifier extends ChangeNotifier {
  StreamSubscription? _authSub;

  GoRouterNotifier() {
    _authSub = FBAuth.auth.authStateChanges().listen((_) => notifyListeners());
  }

  bool get isLoggedIn => FBAuth.auth.currentUser != null;

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late GoRouter globalRouter;

GoRouter buildRouter(GoRouterNotifier notifier) {
  globalRouter = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = notifier.isLoggedIn;
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;
      final onLogin = loc == '/login';
      if (!loggedIn && !onLogin) return '/login';
      
      if (loggedIn) {
        try {
          final auth = AuthCtrl.to;
          final isInactive = auth.currentDoctor != null && !auth.currentDoctor!.isActive;
          if (isInactive) {
            if (loc != '/deactivated') return '/deactivated';
            return null;
          } else {
            if (loc == '/deactivated') return '/home';
          }
        } catch (_) {}
      }

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
      GoRoute(
        path: '/deactivated',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DeactivatedView(),
        ),
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
            pageBuilder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return NoTransitionPage(
                key: state.pageKey,
                child: ScheduleView(initialFilter: filter),
              );
            },
          ),
          GoRoute(
            path: '/home/contacts',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ContactsView(),
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
  return globalRouter;
}
