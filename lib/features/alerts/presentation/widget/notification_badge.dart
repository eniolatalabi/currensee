// lib/features/notifications/presentation/widget/notification_badge_icon.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/notification_controller.dart';

class NotificationBadgeIcon extends StatelessWidget {
  final Color? iconColor;
  final VoidCallback? onTap;
  final double size;

  const NotificationBadgeIcon({
    super.key,
    this.iconColor,
    this.onTap,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;

    return Consumer<NotificationController>(
      builder: (context, controller, _) {
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Notification icon
                Icon(
                  controller.hasUnreadHighPriority
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: controller.hasUnreadHighPriority
                      ? theme.colorScheme.error
                      : effectiveIconColor,
                  size: size,
                ),

                // Badge with count
                if (controller.unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      decoration: BoxDecoration(
                        color: controller.hasUnreadHighPriority
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _formatCount(controller.unreadCount),
                          style: TextStyle(
                            color: controller.hasUnreadHighPriority
                                ? theme.colorScheme.onError
                                : theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Pulse animation for high priority notifications
                if (controller.hasUnreadHighPriority)
                  Positioned.fill(
                    child: _PulseAnimation(
                      color: theme.colorScheme.error.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count > 99) return '99+';
    if (count > 9) return count.toString();
    return count.toString();
  }
}

class _PulseAnimation extends StatefulWidget {
  final Color color;

  const _PulseAnimation({required this.color});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(1 - _animation.value),
              width: 2 * _animation.value,
            ),
          ),
        );
      },
    );
  }
}
