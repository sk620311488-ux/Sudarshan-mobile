import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'google_auth_helper_mobile.dart' as mobile;
import 'google_auth_helper_desktop.dart' as desktop;
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  final GoogleAuthHelper _delegate = (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
      ? mobile.GoogleAuthHelperImpl()
      : desktop.GoogleAuthHelperImpl();

  @override
  Future<UserCredential?> signIn() => _delegate.signIn();

  @override
  Future<void> signOut() => _delegate.signOut();
}
