import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../../../core/app_router.dart';
import '../controller/auth_controller.dart';
import '../../../widgets/custom_button.dart';
import '../../auth/presentation/widgets/google_signin_button.dart';
import '../../../utils/validators.dart';
import '../presentation/widgets/auth_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _showForgotPasswordForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().clearMessages();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // MARK: - Auth Actions
  Future<void> _handleLogin(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authController.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      context.go(AppRouter.home);
    } else if (authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  Future<void> _handleGoogleSignIn(AuthController authController) async {
    final success = await authController.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      // Small delay to ensure auth state is fully updated
      await Future.delayed(const Duration(milliseconds: 100));
      // Use context.go instead of context.push to avoid keeping auth routes in stack
      if (mounted) {
        context.go(AppRouter.home);
      }
    } else if (authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  Future<void> _handleForgotPassword(AuthController authController) async {
    final email = _emailController.text.trim();
    final emailValidation = Validators.email(email);

    if (emailValidation != null) {
      _showErrorSnackBar('Please enter a valid email address first');
      return;
    }

    final success = await authController.resetPassword(email: email);

    if (!mounted) return;

    if (success) {
      setState(() => _showForgotPasswordForm = false);
    }
  }

  void _togglePasswordReset(AuthController authController) {
    setState(() => _showForgotPasswordForm = !_showForgotPasswordForm);
    authController.clearMessages();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  // MARK: - Widgets
  Widget _buildLogo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      shape: BoxShape.circle,
      boxShadow: AppConstants.boxShadow,
    ),
    child: AppTheme.logo(size: 48),
  );

  Widget _buildHeader() => Column(
    children: [
      Text(
        _showForgotPasswordForm ? "Reset Password" : "Welcome back",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        _showForgotPasswordForm
            ? "Enter your email to receive reset instructions"
            : "Sign in to your ${AppConstants.appName} account",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildMessageContainer(String? message, bool isError) {
    if (message == null) return const SizedBox.shrink();
    final color = isError ? AppTheme.errorColor : AppTheme.successColor;
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(AuthController authController) => AuthTextField(
    hintText: "Email",
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    validator: Validators.email,
    isLoading: authController.isLoading,
    focusNode: _emailFocus,
    textInputAction: TextInputAction.next,
    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
  );

  Widget _buildPasswordField(AuthController authController) {
    if (_showForgotPasswordForm) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        AuthTextField(
          hintText: "Password",
          controller: _passwordController,
          isPassword: true,
          validator: Validators.password,
          isLoading: authController.isLoading,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(authController),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: authController.isLoading
                ? null
                : () => _togglePasswordReset(authController),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(AuthController authController) => CustomButton(
    label: _showForgotPasswordForm ? 'Send Reset Email' : 'Sign In',
    onPressed: authController.isLoading
        ? null
        : () async {
            if (_showForgotPasswordForm) {
              await _handleForgotPassword(authController);
            } else {
              await _handleLogin(authController);
            }
          },
    variant: ButtonVariant.filled,
    size: ButtonSize.large,
  );

  Widget _buildSecondaryActions(AuthController authController) {
    if (_showForgotPasswordForm) {
      return CustomButton(
        label: 'Back to Sign In',
        onPressed: authController.isLoading
            ? null
            : () async => _togglePasswordReset(authController),
        variant: ButtonVariant.outlined,
        size: ButtonSize.large,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        _buildDivider(),
        const SizedBox(height: 20),
        GoogleSignInButton(
          onPressed: authController.isLoading
              ? null
              : () => _handleGoogleSignIn(authController),
        ),
        const SizedBox(height: 32),
        _buildSignUpLink(authController),
      ],
    );
  }

  Widget _buildDivider() => Row(
    children: [
      const Expanded(child: Divider(thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          'OR',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      const Expanded(child: Divider(thickness: 1)),
    ],
  );

  Widget _buildSignUpLink(AuthController authController) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        "Don't have an account? ",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      TextButton(
        onPressed: authController.isLoading
            ? null
            : () => context.push(AppRouter.authSignup),
        child: Text(
          'Sign Up',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppConstants.paddingLarge),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth < 500
                            ? constraints.maxWidth
                            : AppConstants.authInputWidth,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            _buildLogo(),
                            const SizedBox(height: 24),
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildMessageContainer(
                              authController.errorMessage,
                              true,
                            ),
                            _buildMessageContainer(
                              authController.successMessage,
                              false,
                            ),
                            _buildEmailField(authController),
                            _buildPasswordField(authController),
                            const SizedBox(height: 24),
                            _buildActionButton(authController),
                            const SizedBox(height: 16),
                            _buildSecondaryActions(authController),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
