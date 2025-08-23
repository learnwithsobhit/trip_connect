import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    _isInitialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Handle notification tap - navigate to appropriate screen
      print('Notification tapped with payload: $payload');
    }
  }

  Future<void> showTripNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'trip_channel',
      'Trip Notifications',
      channelDescription: 'Notifications for trip updates and activities',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> showAnnouncementNotification({
    required String title,
    required String body,
    required String tripId,
    bool requiresAck = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'announcement_channel',
      'Announcements',
      channelDescription: 'Important trip announcements',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: requiresAck,
      autoCancel: !requiresAck,
      actions: requiresAck ? <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'acknowledge',
          'Acknowledge',
          showsUserInterface: true,
        ),
      ] : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📢 $title',
      body,
      details,
      payload: 'announcement:$tripId',
    );
  }

  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical emergency alerts',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'view_location',
          'View Location',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'call_emergency',
          'Call Emergency',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final locationInfo = lat != null && lng != null 
        ? '\nLocation: $lat, $lng' 
        : '';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🚨 $title',
      '$body$locationInfo',
      details,
      payload: 'emergency:$tripId:$lat:$lng',
    );
  }

  Future<void> showRollCallNotification({
    required String title,
    required String body,
    required String tripId,
    required String rollCallId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rollcall_channel',
      'Roll Call',
      channelDescription: 'Roll call check-in reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'checkin',
          'Check In',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✋ $title',
      body,
      details,
      payload: 'rollcall:$tripId:$rollCallId',
    );
  }

  Future<void> showChatNotification({
    required String senderName,
    required String message,
    required String tripId,
    String? tripName,
  }) async {
    final title = tripName != null ? '$tripName' : 'Trip Chat';
    
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Trip Chat',
      channelDescription: 'Messages from trip chat',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      '$senderName: $message',
      details,
      payload: 'chat:$tripId',
    );
  }

  Future<void> scheduleDelayNotification({
    required String tripName,
    required String delay,
    required DateTime scheduledTime,
    required String tripId,
  }) async {
    // For MVP, we'll just show immediate notification instead of scheduling
    // In production, you'd use timezone package for proper scheduling
    await showTripNotification(
      title: '⏰ Trip Delay',
      body: '$tripName is running $delay behind schedule',
      payload: 'delay:$tripId',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
