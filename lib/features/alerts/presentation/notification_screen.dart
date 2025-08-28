// lib/features/notifications/presentation/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../data/models/app_notification_model.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/notification_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      final user = authController.currentUser;
      if (user != null) {
        context.read<NotificationController>().initialize(user.uid);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final authController = context.read<AuthController>();
      final user = authController.currentUser;
      if (user != null) {
        context.read<NotificationController>().loadMoreNotifications(user.uid);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          Consumer<NotificationController>(
            builder: (context, controller, _) {
              return PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  if (controller.unreadCount > 0)
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 18),
                          SizedBox(width: 8),
                          Text('Mark All Read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationController>(
        builder: (context, controller, _) {
          return Column(
            children: [
              _buildFilterHeader(theme, controller),
              Expanded(child: _buildNotificationsList(controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterHeader(
    ThemeData theme,
    NotificationController controller,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'All',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: 'All', child: Text('All')),
                DropdownMenuItem(
                  value: 'Unread',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Unread'),
                      if (controller.unreadCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            controller.unreadCount.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const DropdownMenuItem(
                  value: 'Priority',
                  child: Text('Priority'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationController controller) {
    if (controller.isLoading && controller.notifications.isEmpty) {
      return _buildLoadingState();
    }

    if (controller.error != null && controller.notifications.isEmpty) {
      return _buildErrorState(controller.error!);
    }

    final filteredNotifications = _getFilteredNotifications(controller);

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        itemCount:
            filteredNotifications.length + (controller.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredNotifications.length) {
            return _buildLoadingMoreIndicator();
          }

          final notification = filteredNotifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildNotificationItem(notification, controller),
          );
        },
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(
    NotificationController controller,
  ) {
    switch (_selectedFilter) {
      case 'Unread':
        return controller.unreadNotifications;
      case 'Priority':
        return controller.highPriorityNotifications;
      default:
        return controller.notifications;
    }
  }

  Widget _buildNotificationItem(
    AppNotification notification,
    NotificationController controller,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: notification.isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: notification.isRead
              ? theme.colorScheme.outline.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.3),
          width: notification.isRead ? 1 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification, controller),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNotificationIcon(notification, theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (notification.isHigh || notification.isUrgent)
                              _buildPriorityBadge(notification, theme),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildNotificationActions(notification, controller),
                ],
              ),
              if (notification.data.isNotEmpty &&
                  notification.type == NotificationType.conversionSuccess)
                _buildConversionDetails(notification, theme),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getNotificationTypeText(notification.type),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification, ThemeData theme) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.conversionSuccess:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.currencyRateChange:
        iconData = Icons.trending_up;
        iconColor = theme.colorScheme.secondary;
        break;
      case NotificationType.baseCurrencyChanged:
        iconData = Icons.currency_exchange;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.achievementUnlocked:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationType.welcomeMessage:
        iconData = Icons.waving_hand;
        iconColor = theme.colorScheme.primary;
        break;
      case NotificationType.systemUpdate:
        iconData = Icons.system_update;
        iconColor = theme.colorScheme.tertiary;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = theme.colorScheme.onSurface;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildPriorityBadge(AppNotification notification, ThemeData theme) {
    Color badgeColor = notification.priority == NotificationPriority.urgent
        ? theme.colorScheme.error
        : theme.colorScheme.tertiary;

    String label = notification.priority == NotificationPriority.urgent
        ? 'URGENT'
        : 'HIGH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onError,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConversionDetails(
    AppNotification notification,
    ThemeData theme,
  ) {
    final amount = notification.data['amount'] as double?;
    final convertedAmount = notification.data['convertedAmount'] as double?;
    final fromCurrency = notification.data['fromCurrency'] as String?;
    final toCurrency = notification.data['toCurrency'] as String?;

    if (amount == null ||
        convertedAmount == null ||
        fromCurrency == null ||
        toCurrency == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${amount.toStringAsFixed(2)} $fromCurrency → ${convertedAmount.toStringAsFixed(2)} $toCurrency',
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildNotificationActions(
    AppNotification notification,
    NotificationController controller,
  ) {
    return PopupMenuButton<String>(
      onSelected: (value) =>
          _handleNotificationAction(value, notification, controller),
      itemBuilder: (context) => [
        if (!notification.isRead)
          const PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read, size: 16),
                SizedBox(width: 8),
                Text('Mark as Read'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 16, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(4),
        child: const Icon(Icons.more_vert, size: 16),
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Loading notifications...', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Notifications',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotifications,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    String message;
    String subtitle;

    switch (_selectedFilter) {
      case 'Unread':
        message = 'All caught up!';
        subtitle = 'No unread notifications';
        break;
      case 'Priority':
        message = 'No priority notifications';
        subtitle = 'Important notifications will appear here';
        break;
      default:
        message = 'No notifications yet';
        subtitle = 'New notifications will appear here';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(message, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user != null) {
      await context.read<NotificationController>().refresh(user.uid);
    }
  }

  void _handleMenuAction(String action) async {
    final controller = context.read<NotificationController>();
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user == null) return;

    switch (action) {
      case 'mark_all_read':
        await controller.markAllAsRead(user.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All notifications marked as read')),
          );
        }
        break;
      case 'refresh':
        await _refreshNotifications();
        break;
    }
  }

  void _handleNotificationTap(
    AppNotification notification,
    NotificationController controller,
  ) async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user != null && !notification.isRead) {
      await controller.markAsRead(notification, user.uid);
    }
  }

  void _handleNotificationAction(
    String action,
    AppNotification notification,
    NotificationController controller,
  ) async {
    final authController = context.read<AuthController>();
    final user = authController.currentUser;
    if (user == null) return;

    switch (action) {
      case 'mark_read':
        await controller.markAsRead(notification, user.uid);
        break;
      case 'delete':
        await controller.deleteNotification(notification, user.uid);
        break;
    }
  }

  String _getNotificationTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.conversionSuccess:
        return 'Conversion';
      case NotificationType.currencyRateChange:
        return 'Rate Alert';
      case NotificationType.welcomeMessage:
        return 'Welcome';
      case NotificationType.achievementUnlocked:
        return 'Achievement';
      case NotificationType.systemUpdate:
        return 'System';
      case NotificationType.baseCurrencyChanged:
        return 'Currency';
      default:
        return 'Notification';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
