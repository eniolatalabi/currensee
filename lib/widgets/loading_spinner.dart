import 'package:flutter/material.dart';
import '../core/theme.dart';

/// LoadingSpinner - reusable loader for API calls, forms, etc.
class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingSpinner({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(color ?? AppTheme.primaryColor),
        ),
      ),
    );
  }
}
