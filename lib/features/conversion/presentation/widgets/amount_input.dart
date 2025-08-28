// lib/features/conversion/presentation/widgets/amount_input.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../conversion/controller/conversion_controller.dart';
import '../../../../core/constants.dart';

/// Professional numeric input for currency amount with proper decimal handling
class AmountInput extends StatefulWidget {
  final ConversionController controller;
  final bool compact;

  const AmountInput({
    super.key,
    required this.controller,
    this.compact = false,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.amount == 0.0
          ? ''
          : _formatDisplayValue(widget.controller.amount),
    );

    // Listen to external changes from controller
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_isInternalUpdate) return;

    final newValue = widget.controller.amount;
    final displayText = newValue == 0.0 ? '' : _formatDisplayValue(newValue);

    if (_textController.text != displayText) {
      final cursorPos = _textController.selection.baseOffset;
      _textController.value = TextEditingValue(
        text: displayText,
        selection: TextSelection.collapsed(
          offset: cursorPos > displayText.length
              ? displayText.length
              : cursorPos,
        ),
      );
    }
  }

  String _formatDisplayValue(double value) {
    // Remove trailing zeros and unnecessary decimal point
    String formatted = value.toStringAsFixed(6);
    formatted = formatted.replaceAll(RegExp(r'0*$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted;
  }

  double _parseInputValue(String text) {
    if (text.isEmpty) return 0.0;

    // Handle cases where user types just decimal point
    if (text == '.') return 0.0;

    // Parse the value
    final parsed = double.tryParse(text);
    return parsed ?? 0.0;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.compact) ...[
          Text(
            'Amount',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
        ],
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppConstants.radius),
            border: Border.all(color: theme.dividerColor, width: 1.0),
            boxShadow: AppConstants.boxShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              AppConstants.radius,
            ), // important
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  if (text.split('.').length > 2) return oldValue;
                  if (text.contains('.')) {
                    final parts = text.split('.');
                    if (parts.length == 2 && parts[1].length > 6) {
                      return oldValue;
                    }
                  }
                  return newValue;
                }),
              ],
              style: widget.compact
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    )
                  : theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  color: theme.hintColor.withValues(alpha: 0.5),
                ),
                prefixText: widget.compact
                    ? null
                    : '${widget.controller.baseCurrency} ',
                // ISSUE 3 FIX: Make currency label respect theme
                prefixStyle: widget.compact
                    ? null
                    : theme.textTheme.headlineSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface, // Respect theme color
                        fontWeight: FontWeight.w600,
                      ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: widget.compact ? 12 : AppConstants.paddingMedium,
                ),
                isDense: widget.compact,
              ),
              onChanged: (text) {
                _isInternalUpdate = true;
                final parsed = _parseInputValue(text);
                widget.controller.updateAmount(parsed);
                _isInternalUpdate = false;
              },
              onTap: () {
                if (_textController.text.isEmpty) {
                  _textController.selection = TextSelection.collapsed(
                    offset: 0,
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
