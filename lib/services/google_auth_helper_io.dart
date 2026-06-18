import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_helper_mobile_stub.dart' 
    if (dart.library.io) 'google_auth_helper_mobile.dart' as mobile;
import 'google_auth_helper_desktop.dart' as desktop;
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  @override
  Future<UserCredential?> signIn() {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      // Use dynamic or cast to avoid direct reference during desktop compilation if possible
      return (mobile.GoogleAuthHelperImpl()).signIn();
    } else {
      return (desktop.GoogleAuthHelperImpl()).signIn();
    }
  }

  @override
  Future<void> signOut() {
    if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      return (mobile.GoogleAuthHelperImpl()).signOut();
    } else {
      return (desktop.GoogleAuthHelperImpl()).signOut();
    }
  }
}
