import 'package:firebase_auth/firebase_auth.dart';
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  @override
  Future<UserCredential?> signIn() async {
    // Standard Google Sign-In for Windows is complex without dedicated desktop packages.
    // For now, providing a clean stub that explains the situation or fallback to email.
    throw Exception('Google Sign-in abhi Windows par support nahi ho raha. Kripya Email/Password use karein.');
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
