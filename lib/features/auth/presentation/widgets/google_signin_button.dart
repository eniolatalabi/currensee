import 'package:flutter/material.dart';
import 'package:currensee/widgets/custom_button.dart';

class GoogleSignInButton extends StatelessWidget {
  final Future<void> Function()? onPressed;

  const GoogleSignInButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      icon: Image.asset('assets/icons/google.png', height: 24, width: 24),
      label: 'Continue with Google',
      variant: ButtonVariant.outlined,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      borderColor: const Color.fromARGB(255, 111, 111, 111),
      width: 260,
      onPressed:
          onPressed ??
          () async {
            //
            // 
          },
    );
  }
}
