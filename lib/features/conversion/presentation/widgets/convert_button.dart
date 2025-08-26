// lib/features/conversion/presentation/widgets/convert_button.dart
import 'package:flutter/material.dart';
import '../../../../widgets/custom_button.dart';

/// ConvertButton - triggers currency conversion
/// Dynamically shows/hides based on app config or controller state
class ConvertButton extends StatelessWidget {
  final bool visible;
  final bool isLoading;
  final Future<void> Function() onPressed;

  const ConvertButton({
    super.key,
    required this.visible,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return CustomButton(
      label: 'Convert',
      onPressed: isLoading
          ? null
          : () async {
              try {
                await onPressed();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Conversion failed: $e')),
                  );
                }
              }
            },
      isLoading: isLoading,
      
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }
}
