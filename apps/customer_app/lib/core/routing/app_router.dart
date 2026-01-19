import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/signup_screen.dart';
import '../../features/home/ui/home_shell.dart';
import '../../features/deals/ui/restaurant_view_screen.dart';

import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.home,

  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;

    final isAuthRoute = state.matchedLocation == RouteNames.login ||
        state.matchedLocation == RouteNames.signup;

    if (session == null && !isAuthRoute) return RouteNames.login;
    if (session != null && isAuthRoute) return RouteNames.home;
    return null;
  },

  routes: [
    GoRoute(
      path: RouteNames.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: RouteNames.signup,
      builder: (_, __) => const SignupScreen(),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (_, __) => const HomeShell(),
    ),
    GoRoute(
      path: '${RouteNames.restaurant}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RestaurantViewScreen(restaurantId: id);
      },
    ),
  ],
);
