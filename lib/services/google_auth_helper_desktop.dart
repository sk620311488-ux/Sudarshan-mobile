import 'package:desktop_webview_auth/desktop_webview_auth.dart';
import 'package:desktop_webview_auth/google.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/mobile_config.dart';
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  @override
  Future<UserCredential?> signIn() async {
    try {
      final googleArgs = GoogleSignInArgs(
        clientId: MobileFirebaseConfig.googleWebClientId,
        redirectUri: 'https://sk-studies-a8338.firebaseapp.com/__/auth/handler',
      );

      final result = await DesktopWebviewAuth.signIn(googleArgs);

      if (result == null) return null;

      final credential = GoogleAuthProvider.credential(
        accessToken: result.accessToken,
        idToken: result.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Windows Google Sign-In Error: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
