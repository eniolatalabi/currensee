// lib/features/auth/presentation/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../core/app_router.dart';
import '../../../../widgets/custom_button.dart'; // ✅ Missing import
import '../../../features/auth/controller/auth_controller.dart';
import '../presentation/widgets/google_signin_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.normalAnim,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> signInWithGoogle(AuthController authController) async {
    final success = await authController.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      // Small delay to ensure auth state is fully updated
      await Future.delayed(const Duration(milliseconds: 100));
      // Use context.go instead of checking authController.user
      if (mounted) {
        context.go(AppRouter.home);
      }
    } else if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(authController.errorMessage!)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius),
          ),
          margin: const EdgeInsets.all(AppConstants.paddingMedium),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AppConstants.spacingLarge,
                        AppConstants.spacingLarge,

                        /// ===== App Logo =====
                        Container(
                          padding: const EdgeInsets.all(
                            AppConstants.paddingLarge,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: AppConstants.boxShadow,
                          ),
                          child: AppTheme.logo(
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        AppConstants.spacingLarge,

                        /// ===== Welcome Text =====
                        Text(
                          "Welcome to ${AppConstants.appName}",
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        AppConstants.spacingMedium,

                        /// ===== Subtitle =====
                        Text(
                          "Track and convert currencies smarter with real-time insights.",
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        AppConstants.spacingLarge,
                        AppConstants.spacingLarge,

                        /// ===== Sign Up (Primary for new users) =====
                        SizedBox(
                          width: AppConstants.authInputWidth,
                          child: CustomButton(
                            label: "Sign Up",
                            size: ButtonSize.large,
                            variant: ButtonVariant.filled,
                            onPressed: () async {
                              context.push(AppRouter.authSignup);
                            },
                          ),
                        ),
                        AppConstants.spacingMedium,

                        /// ===== Log In (Secondary for returning users) =====
                        SizedBox(
                          width: AppConstants.authInputWidth,
                          child: CustomButton(
                            label: "Log In",
                            size: ButtonSize.large,
                            variant: ButtonVariant.outlined,
                            onPressed: () async {
                              context.push(AppRouter.authLogin);
                            },
                          ),
                        ),
                        AppConstants.spacingLarge,

                        /// ===== Divider with OR =====
                        SizedBox(
                          width: AppConstants.authInputWidth,
                          child: Row(
                            children: [
                              const Expanded(
                                child: Divider(thickness: 1, height: 1),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.paddingMedium,
                                ),
                                child: Text(
                                  "OR",
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(thickness: 1, height: 1),
                              ),
                            ],
                          ),
                        ),
                        AppConstants.spacingLarge,

                        /// ===== Continue with Google =====
                        SizedBox(
                          width: AppConstants.authInputWidth,
                          child: GoogleSignInButton(
                            onPressed: () => signInWithGoogle(authController),
                          ),
                        ),

                        AppConstants.spacingLarge,
                        AppConstants.spacingLarge,

                        /// ===== Footer Text =====
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                          ),
                          child: Text(
                            "By continuing, you agree to our usage policies.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
