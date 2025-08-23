import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/constants.dart';
import '../controller/auth_controller.dart';
import '../../../widgets/custom_button.dart';
import '../../auth/presentation/widgets/google_signin_button.dart';
import '../../auth/presentation/signup_screen.dart';
import '../../home/presentation/home_screen.dart';
import '../../../utils/validators.dart';
import '../presentation/widgets/auth_textfield.dart';
import '../presentation/widgets/auth_loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(AuthController authController) async {
    if (!_formKey.currentState!.validate()) return;

    await authController.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (authController.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage!)),
      );
    }
  }

  Future<void> _forgotPassword(AuthController authController) async {
    final email = _emailController.text.trim();
    if (Validators.validateEmail(email) != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email for reset')),
      );
      return;
    }

    await authController.resetPassword(email: email);

    if (!mounted) return;
    if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    }
  }

  Future<void> _signInWithGoogle(AuthController authController) async {
    await authController.signInWithGoogle();

    if (!mounted) return;

    if (authController.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return AuthLoadingOverlay(
          isLoading: authController.loading,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    AppTheme.logo(fontSize: 48),
                    const SizedBox(height: 40),
                    AuthTextField(
                      hintText: "Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      hintText: "Password",
                      controller: _passwordController,
                      isPassword: true,
                      validator: Validators.validatePassword,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _forgotPassword(authController),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      label: 'Login',
                      onPressed: () => _login(authController),
                      isLoading: authController.loading,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider(thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('OR'),
                        ),
                        Expanded(child: Divider(thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GoogleSignInButton(
                      onPressed: () => _signInWithGoogle(authController),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
