import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Use dynamic to avoid type checking issues on Web stubs
  final dynamic _plugin = kIsWeb ? null : FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
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

    // FCM Permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showSimpleNotification(
          title: message.notification!.title ?? 'New Alert',
          body: message.notification!.body ?? '',
          id: 2001,
        );
      }
    });

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
