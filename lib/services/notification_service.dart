import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// firebase_messaging is Android/iOS only — only import on non-web, non-Windows.
// We use a conditional import so the symbol is never resolved on desktop.
import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_mobile.dart' as fcm_helper;

class NotificationService {
  // Use dynamic to avoid type checking issues on Web stubs
  final dynamic _plugin = kIsWeb ? null : FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    
    await _plugin.initialize(settings: settings);
    
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // FCM Permissions + foreground listener — delegated to mobile helper
    // so that firebase_messaging symbols never reach the Windows linker.
    await fcm_helper.setupFcm(_showSimpleNotification);

    _initialized = true;
  }

  Future<void> _showSimpleNotification({
    required String title,
    required String body,
    required int id,
    String channelId = 'general_channel',
    String channelName = 'General Alerts',
  }) async {
    if (!_initialized || kIsWeb) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showFlashcardMilestone(int count) async {
    await _showSimpleNotification(
      id: 3000 + count,
      title: '🏆 Flashcard Milestone!',
      body: 'Shaabash! Aapne $count flashcards collect kar liye hain. Revision jaari rakhein!',
      channelId: 'milestone_channel',
      channelName: 'Achievement Alerts',
    );
  }

  Future<void> showSyncNotification(String testTitle) async {
    await _showSimpleNotification(
      id: 4001,
      title: '✨ New Test Synced',
      body: 'Subah 4 baje ka auto-sync successful! Naya test ready hai: $testTitle',
      channelId: 'sync_channel',
      channelName: 'Sync Alerts',
    );
  }

  Future<void> showDailyTestNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    
    await _plugin.show(
      1001,
      title,
      body,
      const NotificationDetails(
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
      1002,
      'Leaderboard update',
      'Someone has surpassed you. Your daily rank is now #$newRank.',
      const NotificationDetails(
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
      1003,
      'Sudarshan: Time to study!',
      'Don\'t let your streak break. Solve a quick test now.',
      RepeatInterval.daily,
      const NotificationDetails(
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
