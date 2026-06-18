import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/mobile_config.dart';
import 'google_auth_helper.dart';

// google_sign_in ^7.x API — used only on Android/iOS at runtime.
// This file is compiled on all dart:io platforms (including Windows) but
// called only when defaultTargetPlatform is Android or iOS (enforced by
// google_auth_helper_io.dart). All ^7.x symbols (GoogleSignIn.instance,
// .authenticate(), .idToken) are present in the platform-interface package
// which is always resolved, so this compiles cleanly on Windows even though
// the native backing is not present.
class GoogleAuthHelperImpl implements GoogleAuthHelper {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(
      serverClientId: MobileFirebaseConfig.googleWebClientId,
    );
    _initialized = true;
  }

  @override
  Future<UserCredential?> signIn() async {
    await _ensureInitialized();

    // authenticate() is a Future — no await needed on the .authentication
    // getter (it's sync in ^7.x, returns GoogleSignInAuthentication directly).
    final GoogleSignInAccount googleUser =
        await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // ^7.x removed accessToken from GoogleSignInAuthentication.
    // Use only idToken for Firebase credential.
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.disconnect();
  }
}
