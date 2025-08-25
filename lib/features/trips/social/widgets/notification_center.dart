import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/data/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class NotificationCenter extends ConsumerStatefulWidget {
  final List<AppNotification> notifications;
  final Function(String) onNotificationTap;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  const NotificationCenter({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  @override
  ConsumerState<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends ConsumerState<NotificationCenter> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: Text(
                'Notifications',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
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
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: widget.onMarkAllRead,
              child: const Text(
                'Mark Read',
                style: TextStyle(fontSize: 12),
              ),
            ),
          if (widget.notifications.isNotEmpty)
            TextButton(
              onPressed: widget.onClearAll,
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
      body: widget.notifications.isEmpty
          ? _buildEmptyState(theme)
          : _buildNotificationsList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(ThemeData theme) {
    return ListView.builder(
      padding: AppSpacing.paddingMd,
      itemCount: widget.notifications.length,
      itemBuilder: (context, index) {
        final notification = widget.notifications[index];
        return _buildNotificationCard(theme, notification);
      },
    );
  }

  Widget _buildNotificationCard(ThemeData theme, AppNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: notification.isRead ? 1 : 2,
      color: notification.isRead 
          ? theme.colorScheme.surface 
          : theme.colorScheme.primaryContainer.withOpacity(0.1),
      child: InkWell(
        onTap: () => widget.onNotificationTap(notification.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: notification.type.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  notification.type.icon,
                  color: notification.type.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                              color: notification.isRead 
                                  ? theme.colorScheme.onSurface 
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.type.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeago.format(notification.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        _buildActionButtons(theme, notification),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, AppNotification notification) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick action based on notification type
        if (notification.type == NotificationType.newPost ||
            notification.type == NotificationType.newStory)
          GestureDetector(
            onTap: () => _handleQuickAction(notification),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.visibility,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (notification.type == NotificationType.newComment)
          GestureDetector(
            onTap: () => _handleQuickAction(notification),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.reply,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        if (notification.type == NotificationType.newReaction)
          GestureDetector(
            onTap: () => _handleQuickAction(notification),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.favorite,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  void _handleQuickAction(AppNotification notification) {
    // Handle quick actions based on notification type
    switch (notification.type) {
      case NotificationType.newPost:
      case NotificationType.newStory:
        // Navigate to the post/story
        widget.onNotificationTap(notification.id);
        break;
      case NotificationType.newComment:
        // Show reply dialog
        _showReplyDialog(notification);
        break;
      case NotificationType.newReaction:
        // Show reaction options
        _showReactionDialog(notification);
        break;
      default:
        widget.onNotificationTap(notification.id);
    }
  }

  void _showReplyDialog(AppNotification notification) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement reply functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reply sent!')),
              );
            },
            child: const Text('Reply'),
          ),
        ],
      ),
    );
  }

  void _showReactionDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Reaction'),
        content: Wrap(
          spacing: 8,
          children: ReactionType.values.map((reactionType) {
            return InkWell(
              onTap: () {
                // TODO: Implement reaction functionality
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${reactionType.displayName} reaction added!')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reactionType.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
