// lib/features/history/presentation/widgets/animated_stat_card.dart
import 'package:flutter/material.dart';

class AnimatedStatCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final AnimationController animationController;
  final Duration delay;
  final bool isNumeric;

  const AnimatedStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.animationController,
    this.delay = Duration.zero,
    this.isNumeric = true,
  });

  @override
  State<AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _numberAnimation;
  late AnimationController _delayController;

  @override
  void initState() {
    super.initState();

    _delayController = AnimationController(duration: widget.delay, vsync: this);

    // Scale animation for the card entrance
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Slide animation for the icon
    _slideAnimation = Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Interval(0.2, 0.8, curve: Curves.bounceOut),
      ),
    );

    // Number animation for numeric values
    if (widget.isNumeric) {
      final numericValue =
          double.tryParse(widget.value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      _numberAnimation = Tween<double>(begin: 0.0, end: numericValue).animate(
        CurvedAnimation(
          parent: widget.animationController,
          curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
        ),
      );
    }

    // Start animation after delay
    if (widget.delay.inMilliseconds > 0) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          widget.animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: widget.animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with slide animation
                    Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          widget.icon,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      widget.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Animated value
                    if (widget.isNumeric)
                      AnimatedBuilder(
                        animation: _numberAnimation,
                        builder: (context, child) {
                          return Text(
                            _formatAnimatedNumber(_numberAnimation.value),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                              fontSize: 24,
                            ),
                          );
                        },
                      )
                    else
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(
                          milliseconds: 800 + widget.delay.inMilliseconds,
                        ),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Text(
                                widget.value,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  fontSize: 20,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
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

  String _formatAnimatedNumber(double value) {
    if (value == 0) return '0';

    // For large numbers, add commas
    if (value >= 1000) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    // For decimal values (like averages)
    if (value % 1 != 0) {
      return value.toStringAsFixed(0);
    }

    return value.toInt().toString();
  }
}
