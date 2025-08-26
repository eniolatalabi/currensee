import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme.dart';
import '../../../../core/app_router.dart';
import '../../../../widgets/custom_button.dart';
import '../../../../utils/validators.dart';
import '../presentation/widgets/password_strength_indicator.dart';
import '../../../features/auth/controller/auth_controller.dart';
import '../presentation/widgets/auth_textfield.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _passwordHasFocus = false;
  bool _showConfirmPasswordError = false;

  @override
  void initState() {
    super.initState();
    _confirmPasswordController.addListener(_onConfirmPasswordChanged);
    _passwordController.addListener(
      _onPasswordChanged,
    ); // FIXED: Added missing listener
    _passwordFocus.addListener(_onPasswordFocusChanged);
    _confirmPasswordFocus.addListener(_onConfirmPasswordFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().clearMessages();
    });
  }

  // FIXED: Added missing method that was causing NoSuchMethodError
  void _onPasswordChanged() {
    setState(() {
      // Trigger rebuild for password strength indicator
      // This fixes the cascade of NoSuchMethodError exceptions
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _showConfirmPasswordError =
          _confirmPasswordController.text.isNotEmpty &&
          _confirmPasswordController.text != _passwordController.text;
    });
  }

  void _onPasswordFocusChanged() {
    setState(() {
      _passwordHasFocus = _passwordFocus.hasFocus;
    });
  }

  void _onConfirmPasswordFocusChanged() {
    if (!_confirmPasswordFocus.hasFocus) {
      setState(() => _showConfirmPasswordError = false);
    }
  }

  @override
  void dispose() {
    // FIXED: Properly remove all listeners before disposing
    _confirmPasswordController.removeListener(_onConfirmPasswordChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _passwordFocus.removeListener(_onPasswordFocusChanged);
    _confirmPasswordFocus.removeListener(_onConfirmPasswordFocusChanged);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();

    super.dispose();
  }

  Future<void> _handleSignUp(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    // Prevent multiple simultaneous submissions
    if (authController.isLoading) return;

    // Clear any error states
    setState(() {
      _showConfirmPasswordError = false;
    });

    authController.clearMessages();

    final success = await authController.signUpWithEmail(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(
        authController.successMessage ?? 'Account created successfully!',
      );
    } else if (authController.errorMessage != null) {
      _showErrorSnackBar(authController.errorMessage!);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.email_outlined,
            color: AppTheme.successColor,
            size: 32,
          ),
        ),
        title: const Text(
          'Account Created!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: 'Continue to Sign In',
              size: ButtonSize.medium,
              onPressed: () async {
                Navigator.of(context).pop();
                context.go(AppRouter.authLogin);
              },
            ),
          ),
        ],
      ),
    );
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
        'Create Account',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        'Join ${AppConstants.appName} to start tracking currencies',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );

  // FIXED: Updated to handle loading state properly
  Widget _buildTextField(Widget child, {bool isLoading = false}) {
    return SizedBox(
      width: AppConstants.authInputWidth,
      child: IgnorePointer(
        ignoring: isLoading, // Disables interaction when loading
        child: Opacity(
          opacity: isLoading ? 0.6 : 1.0, // Visual feedback when disabled
          child: child,
        ),
      ),
    );
  }

  // Professional password field with integrated strength indicator
  Widget _buildPasswordField(bool isLoading) {
    return Column(
      children: [
        _buildTextField(
          AuthTextField(
            controller: _passwordController,
            hintText: 'Password',
            focusNode: _passwordFocus,
            isPassword: true,
            validator: Validators.strongPassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
            isLoading:
                isLoading, // FIXED: Use parameter instead of context.watch
          ),
          isLoading: isLoading,
        ),
        // Show compact strength indicator when password has content
        if (_passwordController.text.isNotEmpty)
          _buildTextField(
            ListenableBuilder(
              listenable: _passwordController,
              builder: (context, _) {
                return PasswordStrengthIndicator(
                  password: _passwordController.text,
                  showRequirements:
                      _passwordHasFocus, // Only show details when focused
                  isCompact:
                      !_passwordHasFocus, // More compact when not focused
                );
              },
            ),
            isLoading: isLoading,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final isLoading = authController.isLoading;

        return Scaffold(
          appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
          body: LayoutBuilder(
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
                          const SizedBox(height: 20),
                          _buildLogo(),
                          const SizedBox(height: 24),
                          _buildHeader(),
                          const SizedBox(height: 32),

                          // FIXED: All TextFields now properly disabled during loading
                          _buildTextField(
                            AuthTextField(
                              controller: _firstNameController,
                              hintText: 'First Name',
                              focusNode: _firstNameFocus,
                              validator: Validators.name,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _lastNameFocus.requestFocus(),
                              isLoading: isLoading, // FIXED: Use loading state
                            ),
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            AuthTextField(
                              controller: _lastNameController,
                              hintText: 'Last Name',
                              focusNode: _lastNameFocus,
                              validator: Validators.name,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _emailFocus.requestFocus(),
                              isLoading: isLoading, // FIXED: Use loading state
                            ),
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            AuthTextField(
                              controller: _emailController,
                              hintText: 'Email',
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              isLoading: isLoading, // FIXED: Use loading state
                            ),
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Enhanced password field with professional strength indicator
                          _buildPasswordField(isLoading),

                          const SizedBox(height: 16),
                          _buildTextField(
                            AuthTextField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm Password',
                              focusNode: _confirmPasswordFocus,
                              isPassword: true,
                              validator: (value) => Validators.confirmPassword(
                                value,
                                _passwordController.text,
                              ),
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => isLoading
                                  ? null
                                  : _handleSignUp(authController),
                              isLoading: isLoading, // Already correct
                            ),
                            isLoading: isLoading,
                          ),

                          // Inline confirm password error (minimal)
                          if (_showConfirmPasswordError)
                            _buildTextField(
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: AppTheme.errorColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Passwords do not match',
                                      style: TextStyle(
                                        color: AppTheme.errorColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              isLoading: isLoading,
                            ),

                          const SizedBox(height: 32),
                          _buildTextField(
                            CustomButton(
                              label: 'Create Account',
                              size: ButtonSize.large,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () => _handleSignUp(authController),
                            ),
                            isLoading:
                                false, // Button handles its own loading state
                          ),

                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => context.go(AppRouter.authLogin),
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
