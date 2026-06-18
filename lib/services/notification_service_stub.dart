// Stub for Web (and any platform where dart.library.io is absent).
// Provides a no-op setupFcm so NotificationService compiles everywhere.

typedef ShowNotificationFn = Future<void> Function({
  required String title,
  required String body,
  required int id,
  String channelId,
  String channelName,
});

Future<void> setupFcm(ShowNotificationFn showNotification) async {}
