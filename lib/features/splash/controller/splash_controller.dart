import 'package:flutter/material.dart';
import '../../../../core/app_router.dart';
import '../../../../data/services/storage_service.dart';

/// SplashController - decides next route (onboarding, auth, or home)
class SplashController with ChangeNotifier {
  final StorageService storage;

  SplashController(this.storage);

  Future<String> decideNextRoute() async {
    try {
      await Future.delayed(const Duration(seconds: 2)); // splash delay

      if (!storage.hasSeenOnboarding) {
        return AppRouter.onboarding;
      }

      if (storage.userToken == null) {
        return AppRouter.auth;
      }

      return AppRouter.home;
    } catch (e, stack) {
      debugPrint("Splash decision failed: $e\n$stack");
      // Fallback to safe default (auth or onboarding)
      return AppRouter.auth;
    }
  }
}

