import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../widgets/loading_spinner.dart';
import '../../splash/controller/splash_controller.dart';

/// SplashScreen - app entry point with branding + routing logic
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for branding
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    // Decide navigation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    final ctrl = context.read<SplashController>();
    final nextRoute = await ctrl.decideNextRoute();

    if (!mounted) return;

    // Delay for smooth branding + fade feel
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // ✅Safe navigation (no async context issue)
    if (context.mounted) {
      context.go(nextRoute);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo / Branding
              Icon(
                Icons.monetization_on,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: AppConstants.paddingLarge),

              Text(
                "CurrenSee",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Loading indicator
              const LoadingSpinner(),
            ],
          ),
        ),
      ),
    );
  }
}
