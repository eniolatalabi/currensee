import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// OnboardingController - drives PageView & progress state
class OnboardingController extends ChangeNotifier {
  final PageController pageController = PageController();
  final int totalPages;

  int currentIndex = 0;

  OnboardingController({required this.totalPages}) {
    // keep track of current index as user swipes
    pageController.addListener(_pageListener);
  }

  bool get isLastPage => currentIndex == totalPages - 1;

  void _pageListener() {
    final newIndex = pageController.page?.round() ?? 0;
    if (newIndex != currentIndex) {
      currentIndex = newIndex;
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (!isLastPage) {
      await pageController.nextPage(
        duration: AppConstants.normalAnim,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> previous() async {
    if (currentIndex > 0) {
      await pageController.previousPage(
        duration: AppConstants.normalAnim,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> skipToEnd() async {
    await pageController.animateToPage(
      totalPages - 1,
      duration: AppConstants.normalAnim,
      curve: Curves.easeInOut,
    );
  }

  Future<void> goToPage(int index) async {
    await pageController.animateToPage(
      index,
      duration: AppConstants.normalAnim,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    pageController.removeListener(_pageListener);
    pageController.dispose();
    super.dispose();
  }
}
