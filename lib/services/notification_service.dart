import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Use dynamic to avoid type checking issues on Web stubs
  final dynamic _plugin = kIsWeb ? null : FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      // Local notifications on Windows require extra setup or different package usually
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    
    await _plugin.initialize(settings: settings);
    
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showDailyTestNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    
    await _plugin.show(
      id: 1001,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_test_channel',
          'Daily Test Alerts',
          channelDescription: 'Alerts when a new daily test is available.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showLeaderboardDropNotification({
    required int newRank,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    await _plugin.show(
      id: 1002,
      title: 'Leaderboard update',
      body: 'Someone has surpassed you. Your daily rank is now #$newRank.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'leaderboard_channel',
          'Leaderboard Alerts',
          channelDescription: 'Alerts when your leaderboard rank changes.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleDailyReminder() async {
    if (!_initialized || kIsWeb) return;

    await _plugin.periodicallyShow(
      id: 1003,
      title: 'Sudarshan: Time to study!',
      body: 'Don\'t let your streak break. Solve a quick test now.',
      repeatInterval: RepeatInterval.daily,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Study Reminders',
          channelDescription: 'Daily reminders to maintain your streak.',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
