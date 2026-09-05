import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../demo_mode.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/crew/screens/add_worker_screen.dart';
import '../../features/crew/screens/crew_screen.dart';
import '../../features/crew/screens/worker_detail_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/scan/screens/scan_results_screen.dart';
import '../../features/scan/screens/scan_screen.dart';
import '../../features/settings/screens/privacy_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
    _ref.listen(demoModeProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<GoRouterRefreshNotifier>((ref) {
  final notifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/scan',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      if (ref.read(demoModeProvider)) {
        final path = state.matchedLocation;
        if (path == '/login' || path == '/signup' || path == '/onboarding') {
          return '/scan';
        }
        return null;
      }

      final authAsync = ref.read(authStateProvider);
      final profileAsync = ref.read(userProfileProvider);

      if (authAsync.isLoading) return null;

      final user = authAsync.valueOrNull;
      final path = state.matchedLocation;
      final isAuthRoute = path == '/login' || path == '/signup';
      final isOnboarding = path == '/onboarding';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      if (profileAsync.isLoading) {
        return isAuthRoute || isOnboarding ? null : null;
      }

      final profile = profileAsync.valueOrNull;
      final needsOnboarding =
          profile == null || profile.onboardingComplete != true;

      if (needsOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      if (isAuthRoute || isOnboarding) {
        return '/scan';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/crew/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddWorkerScreen(),
      ),
      GoRoute(
        path: '/crew/:workerId/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final workerId = state.pathParameters['workerId']!;
          return AddWorkerScreen(editWorkerId: workerId);
        },
      ),
      GoRoute(
        path: '/crew/:workerId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final workerId = state.pathParameters['workerId']!;
          return WorkerDetailScreen(workerId: workerId);
        },
      ),
      GoRoute(
        path: '/settings/privacy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/scan/results',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ScanResultsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/scan',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const ScanScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/crew',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const CrewScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const SettingsScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
