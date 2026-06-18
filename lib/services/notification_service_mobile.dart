// Mobile (Android/iOS) FCM setup.
// This file owns the firebase_messaging import so it never reaches the
// Windows/macOS/Linux linker.

import 'package:firebase_messaging/firebase_messaging.dart';

typedef ShowNotificationFn = Future<void> Function({
  required String title,
  required String body,
  required int id,
  String channelId,
  String channelName,
});

/// Requests FCM permissions and sets up the foreground message listener.
/// [showNotification] is a callback into NotificationService._showSimpleNotification.
Future<void> setupFcm(ShowNotificationFn showNotification) async {
  final fcm = FirebaseMessaging.instance;

  await fcm.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      showNotification(
        title: message.notification!.title ?? 'New Alert',
        body: message.notification!.body ?? '',
        id: 2001,
      );
    }
  });
}
