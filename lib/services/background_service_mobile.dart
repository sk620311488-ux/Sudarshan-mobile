// Mobile-only background service initialisation.
// This file imports workmanager and firebase_messaging — both Android/iOS-only
// packages. It is ONLY compiled when dart.library.io is available AND the
// platform runtime check in main.dart confirms we are on Android or iOS.
//
// DO NOT add this file to a conditional import chain that includes Windows/
// macOS/Linux — those platforms will fail at link time if these packages
// are not registered.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'sync_service.dart';

// ---------------------------------------------------------------------------
// Workmanager callback (runs in a separate Dart isolate on Android)
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    if (task == 'dailySyncTask') {
      final syncService = SyncService();
      await syncService.performEarlyMorningSync();
    }
    return Future.value(true);
  });
}

// ---------------------------------------------------------------------------
// FCM background handler (Android/iOS)
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  debugPrint('Handling a background FCM message: ${message.messageId}');
}

// ---------------------------------------------------------------------------
// Public entry point called from main()
// ---------------------------------------------------------------------------

Future<void> registerBackgroundTasks() async {
  // Register FCM background handler.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialise Workmanager and register the 4 AM daily sync.
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    '1',
    'dailySyncTask',
    frequency: const Duration(hours: 24),
    initialDelay: _delayTo4AM(),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
  );
}

Duration _delayTo4AM() {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, 4, 0);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled.difference(now);
}
