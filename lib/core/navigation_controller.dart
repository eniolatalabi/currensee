// lib/core/navigation_controller.dart
import 'package:flutter/foundation.dart';

class NavigationController extends ChangeNotifier {
  static final NavigationController _instance =
      NavigationController._internal();
  static NavigationController get instance => _instance;
  NavigationController._internal();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void navigateToTab(int index) {
    if (index >= 0 && index <= 4 && index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();

      if (kDebugMode) {
        final tabNames = ['Home', 'Convert', 'History', 'News', 'Profile'];
        debugPrint(
          '[NavigationController] Navigated to ${tabNames[index]} tab',
        );
      }
    }
  }

  void navigateToHistory() {
    navigateToTab(2); // History is at index 2
  }

  void navigateToHome() {
    navigateToTab(0); // Home is at index 0
  }

  void navigateToConvert() {
    navigateToTab(1); // Convert is at index 1
  }

  void navigateToNews() {
    navigateToTab(3); // News is at index 3
  }

  void navigateToProfile() {
    navigateToTab(4); // Profile is at index 4
  }
}
