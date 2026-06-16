import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/sync_service.dart';

import 'app.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "dailySyncTask") {
      final syncService = SyncService();
      await syncService.performEarlyMorningSync();
    }
    return Future.value(true);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Background FCM handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register 4 AM Sync Task
    // Note: We schedule it to run every 24 hours. 
    // Calculating delay to 4 AM is more precise but a simple periodic task works too.
    await Workmanager().registerPeriodicTask(
      "1",
      "dailySyncTask",
      frequency: const Duration(hours: 24),
      initialDelay: _calculateDelayTo4AM(),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );

  } catch (exc) {
    debugPrint('Background init skipped: $exc');
  }
  runApp(const SudarshanMobileApp());
}

Duration _calculateDelayTo4AM() {
  final now = DateTime.now();
  var scheduled = DateTime(now.year, now.month, now.day, 4, 0);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled.difference(now);
}
