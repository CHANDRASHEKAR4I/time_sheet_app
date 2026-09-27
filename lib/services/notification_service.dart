import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'timesheet_channel';
  static const String _channelName = 'Timesheet Notifications';

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
    );

    await _createChannel();

    await requestPermission();
  }

  // ============================================================
  // CREATE NOTIFICATION CHANNEL
  // ============================================================

  static Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description:
          'Notifications related to timesheet and leave.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      channel,
    );
  }

  // ============================================================
  // REQUEST NOTIFICATION PERMISSION
  // ============================================================

  static Future<void> requestPermission() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  // ============================================================
  // TEST NOTIFICATION
  // ============================================================

  static Future<void> showTestNotification() async {
    // Make sure permission is requested before showing.
    await requestPermission();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription:
            'Timesheet reminders.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
    );

    await _notifications.show(
      100,
      'please fill the timesheet',
      'new- tessolve Time sheet notification',
      details,
    );
  }
}