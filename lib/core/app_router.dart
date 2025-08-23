import 'package:go_router/go_router.dart';

import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/home/presentation/home_screen.dart';

/// AppRouter - central navigation manager using GoRouter
class AppRouter {
  // Route names (constants, still useful for controllers & navigation)
  static const String splash = "/";
  static const String onboarding = "/onboarding";
  static const String auth = "/auth";
  static const String home = "/home";

  /// GoRouter configuration
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: auth, builder: (context, state) => const AuthScreen()),
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),
    ],
  );
}
