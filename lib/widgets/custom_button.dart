import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/loading_spinner.dart';

enum ButtonVariant { filled, outlined, text }

enum ButtonStatus { normal, success, error, warning }

/// 🔑 New button sizes
enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressed;
  final ButtonVariant variant;
  final ButtonStatus status;
  final ButtonSize size;
  final bool isLoading;
  final double? width;
  final double? height;
  final Widget? icon;

  // 🔑 Optional overrides
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.filled,
    this.status = ButtonStatus.normal,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _loading = false;

  /// 🔑 Button height based on size (width is usually infinity unless overridden)
  double _getHeight() {
    if (widget.height != null) return widget.height!;
    switch (widget.size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSpacing() {
    switch (widget.size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 14;
    }
  }

  /// 🔑 Spinner size scales with button size
  double _getSpinnerSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 20;
    }
  }

  Color _getBackgroundColor() {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (widget.status) {
      case ButtonStatus.success:
        return AppTheme.successColor;
      case ButtonStatus.error:
        return AppTheme.errorColor;
      case ButtonStatus.warning:
        return AppTheme.warningColor;
      case ButtonStatus.normal:
        return AppTheme.primaryColor;
    }
  }

  Color _getForegroundColor() {
    return widget.foregroundColor ?? Colors.white;
  }

  Color _getOutlineColor() {
    if (widget.borderColor != null) return widget.borderColor!;
    switch (widget.status) {
      case ButtonStatus.success:
        return AppTheme.successColor;
      case ButtonStatus.error:
        return AppTheme.errorColor;
      case ButtonStatus.warning:
        return AppTheme.warningColor;
      case ButtonStatus.normal:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: _getFontSize(),
    );

    switch (widget.variant) {
      case ButtonVariant.filled:
        return _buildFilled(textStyle);
      case ButtonVariant.outlined:
        return _buildOutlined(textStyle);
      case ButtonVariant.text:
        return _buildText(textStyle);
    }
  }

  Widget _buildFilled(TextStyle? textStyle) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: _getHeight(),
      child: ElevatedButton(
        onPressed: _loading || widget.onPressed == null
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onPressed!();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius),
          ),
        ),
        child: _loading
            ? LoadingSpinner(
                customSize: _getSpinnerSize(),
                customColor: _getForegroundColor(),
              )
            : _buildChild(textStyle, _getForegroundColor()),
      ),
    );
  }

  Widget _buildOutlined(TextStyle? textStyle) {
    final textColor = widget.foregroundColor ?? _getOutlineColor();

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: _getHeight(),
      child: OutlinedButton(
        onPressed: _loading || widget.onPressed == null
            ? null
            : () async {
                setState(() => _loading = true);
                try {
                  await widget.onPressed!();
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _getOutlineColor(), width: 2),
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radius),
          ),
        ),
        child: _loading
            ? LoadingSpinner(
                customSize: _getSpinnerSize(),
                customColor: textColor,
              )
            : _buildChild(textStyle, textColor),
      ),
    );
  }

  Widget _buildText(TextStyle? textStyle) {
    final textColor = widget.foregroundColor ?? _getOutlineColor();

    return TextButton(
      onPressed: _loading || widget.onPressed == null
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed!();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      style: TextButton.styleFrom(foregroundColor: textColor),
      child: _loading
          ? LoadingSpinner(
              customSize: _getSpinnerSize(),
              customColor: textColor,
            )
          : _buildChild(textStyle, textColor),
    );
  }

  Widget _buildChild(TextStyle? style, Color textColor) {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.icon!,
          SizedBox(width: _getIconSpacing()),
          Text(widget.label, style: style?.copyWith(color: textColor)),
        ],
      );
    }
    return Text(widget.label, style: style?.copyWith(color: textColor));
  }
}
