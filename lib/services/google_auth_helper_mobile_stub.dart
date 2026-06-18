import 'package:firebase_auth/firebase_auth.dart';
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  @override
  Future<UserCredential?> signIn() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();
}
