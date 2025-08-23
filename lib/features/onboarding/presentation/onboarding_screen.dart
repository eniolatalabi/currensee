import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/app_router.dart';
import '../../../data/services/storage_service.dart';
import '../../../widgets/app_indicator.dart';
import '../../../widgets/custom_button.dart';
import 'widgets/onboarding_page.dart';
import '../controller/onboarding_controller.dart';

/// OnboardingScreen - introduces app features with animations
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: "Track Currencies Easily",
      description:
          "Stay updated with real-time exchange rates across multiple currencies.",
      lottieAsset: "assets/lottie/track.json",
      fallbackIcon: Icons.attach_money,
    ),
    const OnboardingPage(
      title: "Set Alerts & Preferences",
      description:
          "Customize alerts for rate changes and manage your favorite currencies.",
      lottieAsset: "assets/lottie/alerts.json",
      fallbackIcon: Icons.notifications_active,
    ),
    const OnboardingPage(
      title: "Conversion Made Simple",
      description:
          "Convert currencies instantly with accurate and reliable data.",
      lottieAsset: "assets/lottie/conversion.json",
      fallbackIcon: Icons.swap_horiz,
    ),
  ];

  Future<void> _finish(BuildContext context) async {
    final storage = StorageService.instance;
    await storage.setOnboardingSeen();
    if (!context.mounted) return;
    context.go(AppRouter.auth);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingController(totalPages: _pages.length),
      child: Builder(
        builder: (context) {
          final ctrl = context.watch<OnboardingController>();
          final theme = Theme.of(context);
          final isLastPage = ctrl.isLastPage;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // PageView (listener on controller keeps index in sync)
                  Expanded(
                    child: PageView.builder(
                      controller: ctrl.pageController,
                      itemCount: _pages.length,
                      // removed onPageChanged: controller listens internally
                      itemBuilder: (_, index) => _pages[index],
                    ),
                  ),

                  // spacing
                  AppConstants.spacingMedium,

                  // Indicator – driven by PageController (fractional animation)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge,
                    ),
                    child: AppIndicator(
                      controller: ctrl.pageController, // << key change
                      itemCount: _pages.length,
                      type: IndicatorType.dots,
                    ),
                  ),

                  // spacing
                  AppConstants.spacingLarge,

                  // Buttons row: Skip | Next/Get Started
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingLarge,
                      vertical: AppConstants.paddingMedium,
                    ),
                    child: Row(
                      children: [
                        // Skip (hidden on last page) – Spacer keeps symmetry
                        if (!isLastPage)
                          Expanded(
                            child: CustomButton(
                              label: "Skip",
                              onPressed: ctrl.skipToEnd,
                              variant: ButtonVariant.outlined,
                            ),
                          )
                        else
                          const Spacer(),

                        // h spacing
                        AppConstants.hSpacingMedium,

                        Expanded(
                          child: CustomButton(
                            label: isLastPage ? "Get Started" : "Next",
                            onPressed: () =>
                                isLastPage ? _finish(context) : ctrl.next(),
                            variant: ButtonVariant.filled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
