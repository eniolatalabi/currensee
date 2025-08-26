import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/splash/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/signup_screen.dart' as signup;
import '../features/auth/presentation/login_screen.dart' as login;
import '../features/auth/controller/auth_controller.dart';
import '../presentation/main_navigation.dart'; 

/// AppRouter - central navigation manager using GoRouter
class AppRouter {
  // ===== Route Constants =====
  static const String splash = "/";
  static const String onboarding = "/onboarding";
  static const String auth = "/auth";
  static const String home = "/home"; 
  static const String authSignup = "/auth/signup";
  static const String authLogin = "/auth/login";

  /// Check if user is authenticated for protected routes
  static bool _isAuthenticated(BuildContext context) {
    final authController = context.read<AuthController>();
    return authController.isAuthenticated;
  }

  /// Improved redirect logic for auth-guarded routes
  static String? _redirect(BuildContext context, GoRouterState state) {
    final isAuth = _isAuthenticated(context);
    final currentPath = state.uri.path;
    final isAuthRoute = currentPath.startsWith('/auth');
    final isPublicRoute = currentPath == splash || currentPath == onboarding;

    if (isPublicRoute) return null;

    if (!isAuth && !isAuthRoute) return auth;

    if (isAuth && isAuthRoute) return home;

    return null;
  }

  /// GoRouter configuration with proper refresh listenable
  static final GoRouter router = GoRouter(
    initialLocation: splash,
    redirect: _redirect,
    refreshListenable: _AuthChangeNotifier(),
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: auth, builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: home,
        builder: (context, state) =>
            const MainNavigationScreen(), 
      ),
      GoRoute(
        path: authSignup,
        builder: (context, state) => const signup.SignUpScreen(),
      ),
      GoRoute(
        path: authLogin,
        builder: (context, state) => const login.LoginScreen(),
      ),
    ],
  );
}

/// Custom listenable to trigger router rebuilds when Firebase auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  late final StreamSubscription<User?> _authSubscription;

  _AuthChangeNotifier() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
