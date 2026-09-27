import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/collections/collections_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/ledger/ledger_screen.dart';
import 'features/members/members_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/home_shell.dart';
import 'state/auth_controller.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// App router with an auth gate. The five primary destinations live inside a
/// [StatefulShellRoute] (bottom nav); the login screen and a pushable ledger
/// view sit at the root.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(ref.read(isSignedInProvider));
  ref.onDispose(refresh.dispose);
  ref.listen(isSignedInProvider, (_, next) => refresh.value = next);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/dashboard',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!signedIn) return onAuthPage ? null : '/login';
      if (onAuthPage) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/ledger-view/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => LedgerScreen(
          initialEventId: state.pathParameters['id'],
          standalone: true,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/dashboard', builder: (_, _) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/collections',
                builder: (_, _) => const CollectionsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/members', builder: (_, _) => const MembersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ledger', builder: (_, _) => const LedgerScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings', builder: (_, _) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});
