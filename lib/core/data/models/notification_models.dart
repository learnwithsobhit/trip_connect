import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_models.freezed.dart';
part 'notification_models.g.dart';

@freezed
class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    @Default(false) bool isRead,
    String? imageUrl,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) => _$AppNotificationFromJson(json);
}

enum NotificationType {
  newPost,
  newComment,
  newReaction,
  newStory,
  tripUpdate,
  mention,
  achievement,
  reminder,
}

extension NotificationTypeX on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.newPost:
        return 'New Post';
      case NotificationType.newComment:
        return 'New Comment';
      case NotificationType.newReaction:
        return 'New Reaction';
      case NotificationType.newStory:
        return 'New Story';
      case NotificationType.tripUpdate:
        return 'Trip Update';
      case NotificationType.mention:
        return 'Mention';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.reminder:
        return 'Reminder';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.newPost:
        return Icons.post_add;
      case NotificationType.newComment:
        return Icons.comment;
      case NotificationType.newReaction:
        return Icons.favorite;
      case NotificationType.newStory:
        return Icons.auto_stories;
      case NotificationType.tripUpdate:
        return Icons.update;
      case NotificationType.mention:
        return Icons.alternate_email;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.reminder:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.newPost:
        return Colors.blue;
      case NotificationType.newComment:
        return Colors.green;
      case NotificationType.newReaction:
        return Colors.red;
      case NotificationType.newStory:
        return Colors.purple;
      case NotificationType.tripUpdate:
        return Colors.orange;
      case NotificationType.mention:
        return Colors.indigo;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.reminder:
        return Colors.teal;
    }
  }
}
