import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional import: background_service_mobile.dart is only compiled on
// platforms that have dart:io (Android, iOS, desktop). The stub is used on
// web. workmanager and firebase_messaging stay inside the mobile file so
// they never reach the Windows/macOS/Linux linker.
import 'services/background_service_stub.dart'
    if (dart.library.io) 'services/background_service_mobile.dart'
    as bg;

import 'app.dart';
import 'firebase_options.dart';

// Entry-point for Workmanager background tasks (Android only).
// @pragma keeps it in the release build; on non-Android it is never called.
@pragma('vm:entry-point')
void callbackDispatcher() => bg.callbackDispatcher();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Workmanager + FCM are Android/iOS only.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await bg.registerBackgroundTasks();
    }
  } catch (exc) {
    debugPrint('Background init skipped: $exc');
  }
  runApp(const SudarshanMobileApp());
}
