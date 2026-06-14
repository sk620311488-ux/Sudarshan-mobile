import 'package:firebase_auth/firebase_auth.dart';
import 'google_auth_helper_stub.dart'
    if (dart.library.io) 'google_auth_helper_io.dart'
    if (dart.library.html) 'google_auth_helper_web.dart';

abstract class GoogleAuthHelper {
  Future<UserCredential?> signIn();
  Future<void> signOut();

  factory GoogleAuthHelper() => GoogleAuthHelperImpl();
}
