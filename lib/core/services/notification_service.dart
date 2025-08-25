import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../data/models/models.dart';
import '../data/models/notification_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final List<AppNotification> _inAppNotifications = [];

  // Notification types
  static const String _channelId = 'trip_connect_notifications';
  static const String _channelName = 'Trip Connect Notifications';
  static const String _channelDescription = 'Notifications for trip activities and social interactions';

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // In-app notifications
  List<AppNotification> get inAppNotifications => List.unmodifiable(_inAppNotifications);

  void addInAppNotification(AppNotification notification) {
    _inAppNotifications.insert(0, notification);
    _showLocalNotification(notification);
  }

  void markAsRead(String notificationId) {
    final index = _inAppNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _inAppNotifications[index] = _inAppNotifications[index].copyWith(isRead: true);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _inAppNotifications.length; i++) {
      _inAppNotifications[i] = _inAppNotifications[i].copyWith(isRead: true);
    }
  }

  void clearAllNotifications() {
    _inAppNotifications.clear();
  }

  int get unreadCount => _inAppNotifications.where((n) => !n.isRead).length;

  // Local notifications
  Future<void> _showLocalNotification(AppNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
      payload: notification.id,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final notificationId = response.payload;
    if (notificationId != null) {
      markAsRead(notificationId);
      // TODO: Navigate to relevant screen based on notification type
    }
  }

  // Social feed notification helpers
  void notifyNewPost(SocialPost post, String authorName) {
    final notification = AppNotification(
      id: 'post_${post.id}',
      type: NotificationType.newPost,
      title: 'New Post from $authorName',
      body: post.content.length > 50 
          ? '${post.content.substring(0, 50)}...' 
          : post.content,
      data: {
        'postId': post.id,
        'tripId': post.tripId,
        'authorId': post.authorId,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  void notifyNewComment(Comment comment, String authorName, String postAuthorName) {
    final notification = AppNotification(
      id: 'comment_${comment.id}',
      type: NotificationType.newComment,
      title: '$authorName commented on $postAuthorName\'s post',
      body: comment.content.length > 50 
          ? '${comment.content.substring(0, 50)}...' 
          : comment.content,
      data: {
        'commentId': comment.id,
        'postId': comment.postId,
        'authorId': comment.authorId,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  void notifyNewReaction(Reaction reaction, String reactorName, String targetAuthorName) {
    final reactionText = _getReactionText(reaction.type);
    final notification = AppNotification(
      id: 'reaction_${reaction.id}',
      type: NotificationType.newReaction,
      title: '$reactorName reacted to $targetAuthorName\'s ${reaction.targetType == ReactionTarget.post ? 'post' : 'comment'}',
      body: '$reactorName $reactionText',
      data: {
        'reactionId': reaction.id,
        'targetId': reaction.targetId,
        'targetType': reaction.targetType.name,
        'reactorId': reaction.userId,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  void notifyNewStory(TripStory story, String authorName) {
    final notification = AppNotification(
      id: 'story_${story.id}',
      type: NotificationType.newStory,
      title: 'New Story from $authorName',
      body: story.title.isNotEmpty ? story.title : 'Check out the new story!',
      data: {
        'storyId': story.id,
        'tripId': story.tripId,
        'authorId': story.authorId,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  void notifyTripUpdate(String tripName, String updateType, String message) {
    final notification = AppNotification(
      id: 'trip_update_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.tripUpdate,
      title: 'Trip Update: $tripName',
      body: message,
      data: {
        'tripName': tripName,
        'updateType': updateType,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  void notifyMention(String mentionedBy, String postContent) {
    final notification = AppNotification(
      id: 'mention_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.mention,
      title: '$mentionedBy mentioned you',
      body: postContent.length > 50 
          ? '${postContent.substring(0, 50)}...' 
          : postContent,
      data: {
        'mentionedBy': mentionedBy,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
  }

  String _getReactionText(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return 'liked';
      case ReactionType.love:
        return 'loved';
      case ReactionType.laugh:
        return 'laughed at';
      case ReactionType.wow:
        return 'was amazed by';
      case ReactionType.sad:
        return 'felt sad about';
      case ReactionType.angry:
        return 'was angry about';
      case ReactionType.fire:
        return 'thought was fire';
      case ReactionType.heart:
        return 'hearted';
      case ReactionType.thumbsUp:
        return 'gave thumbs up to';
      case ReactionType.clap:
        return 'clapped for';
    }
  }

  // Roll Call specific notification methods
  Future<void> showRollCallReminder({
    required String userId,
    required String tripId,
    required String rollCallId,
    required dynamic anchorLocation,
    required String anchorName,
  }) async {
    final notification = AppNotification(
      id: 'rollcall_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reminder,
      title: 'Roll Call Reminder',
      body: 'Please check in at $anchorName for roll call',
      data: {
        'userId': userId,
        'tripId': tripId,
        'rollCallId': rollCallId,
        'anchorName': anchorName,
        'lat': anchorLocation.lat,
        'lng': anchorLocation.lng,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
    await _showLocalNotification(notification);
  }

  Future<void> showRollCallStarted({
    required String tripId,
    required String rollCallId,
    required dynamic anchorLocation,
    required String anchorName,
  }) async {
    final notification = AppNotification(
      id: 'rollcall_started_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reminder,
      title: 'Roll Call Started',
      body: 'Roll call has started at $anchorName. Please check in.',
      data: {
        'tripId': tripId,
        'rollCallId': rollCallId,
        'anchorName': anchorName,
        'lat': anchorLocation.lat,
        'lng': anchorLocation.lng,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
    await _showLocalNotification(notification);
  }

  Future<void> showRollCallClosed({
    required String tripId,
    required String rollCallId,
    required int presentCount,
    required int missingCount,
    String? closeMessage,
  }) async {
    final message = closeMessage ?? 'Roll call has been completed.';
    final notification = AppNotification(
      id: 'rollcall_closed_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reminder,
      title: 'Roll Call Completed',
      body: '$message Present: $presentCount, Missing: $missingCount',
      data: {
        'tripId': tripId,
        'rollCallId': rollCallId,
        'presentCount': presentCount,
        'missingCount': missingCount,
        'closeMessage': closeMessage,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
    await _showLocalNotification(notification);
  }

  Future<void> showRollCallCancelled({
    required String tripId,
    required String rollCallId,
  }) async {
    final notification = AppNotification(
      id: 'rollcall_cancelled_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.reminder,
      title: 'Roll Call Cancelled',
      body: 'The roll call has been cancelled by the trip leader.',
      data: {
        'tripId': tripId,
        'rollCallId': rollCallId,
      },
      createdAt: DateTime.now(),
    );
    addInAppNotification(notification);
    await _showLocalNotification(notification);
  }
}

