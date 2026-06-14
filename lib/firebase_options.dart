import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'config/mobile_config.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: MobileFirebaseConfig.apiKey,
    appId: '1:794708033386:web:3545d4100ed5cb13ee2f13',
    messagingSenderId: '794708033386',
    projectId: MobileFirebaseConfig.projectId,
    authDomain: 'sk-studies-a8338.firebaseapp.com',
    storageBucket: 'sk-studies-a8338.firebasestorage.app',
    databaseURL: 'https://sk-studies-a8338-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: MobileFirebaseConfig.apiKey,
    appId: '1:794708033386:android:2ac979c6f1bd6995ee2f13',
    messagingSenderId: '794708033386',
    projectId: MobileFirebaseConfig.projectId,
    storageBucket: 'sk-studies-a8338.firebasestorage.app',
    databaseURL: 'https://sk-studies-a8338-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
