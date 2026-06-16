import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

import 'google_auth_helper.dart';

class AuthService {
  static const _sessionKey = 'sudarshan_mobile_session';
  final GoogleAuthHelper _googleHelper = GoogleAuthHelper();

  Future<AppSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final storedSession = _readStoredSession(prefs);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return storedSession;
      }

      final session = _sessionFromUser(
        user,
        storedCustomStudentId:
            storedSession?.uid == user.uid ? storedSession?.customStudentId : null,
      );
      await saveSession(session);
      return session;
    } catch (_) {
      return storedSession;
    }
  }

  Future<void> saveSession(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<AppSession> continueAsGuest({String name = 'Guest Student'}) async {
    await _signOutFirebase();

    final suffix = Random().nextInt(999999).toString().padLeft(6, '0');
    final session = AppSession(
      mode: 'guest',
      uid: 'guest_$suffix',
      name: name,
      email: '',
      signedIn: true,
    );

    await saveSession(session);
    return session;
  }

  Future<AppSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Email sign-in complete nahi hua.');
      }

      final session = await _buildSessionFromUser(user, mode: 'email');
      await saveSession(session);
      return session;
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseError(error.code));
    }
  }

  Future<AppSession> signInWithGoogle() async {
    try {
      final credential = await _googleHelper.signIn();
      if (credential == null) {
        throw Exception('Google sign-in cancel kiya gaya.');
      }

      final user = credential.user;
      if (user == null) {
        throw Exception('Google sign-in complete nahi hua.');
      }

      final session = await _buildSessionFromUser(user, mode: 'google');
      await saveSession(session);
      return session;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<AppSession> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Account create nahi hua.');
      }

      final displayName =
          name.trim().isEmpty ? email.split('@').first : name.trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      final refreshedUser = FirebaseAuth.instance.currentUser ?? user;
      final session = await _buildSessionFromUser(
        refreshedUser,
        mode: 'email',
        fallbackName: displayName,
        fallbackEmail: email.trim(),
      );
      await saveSession(session);
      return session;
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseError(error.code));
    }
  }

  Future<void> signOut() async {
    await _signOutFirebase();
    await clearSession();
  }

  Future<void> _signOutFirebase() async {
    try {
      await _googleHelper.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Firebase can be unavailable on some platforms
    }
  }

  Future<AppSession> _buildSessionFromUser(
    User user, {
    required String mode,
    String fallbackName = '',
    String fallbackEmail = '',
  }) async {
    final resolvedName = (user.displayName ?? fallbackName).trim().isNotEmpty
        ? (user.displayName ?? fallbackName).trim()
        : (user.email ?? fallbackEmail).split('@').first;

    return AppSession(
      mode: mode,
      uid: user.uid,
      name: resolvedName,
      email: (user.email ?? fallbackEmail).trim(),
      idToken: (await user.getIdToken()) ?? '',
      signedIn: true,
    );
  }

  AppSession? _readStoredSession(SharedPreferences prefs) {
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      return AppSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  AppSession _sessionFromUser(
    User user, {
    String? storedCustomStudentId,
  }) {
    final providerIds = user.providerData.map((item) => item.providerId).toSet();
    final mode = providerIds.contains('google.com')
        ? 'google'
        : providerIds.contains('password')
            ? 'email'
            : 'email';

    return AppSession(
      mode: mode,
      uid: user.uid,
      name: (user.displayName ?? user.email?.split('@').first ?? 'Student')
          .trim(),
      email: (user.email ?? '').trim(),
      signedIn: true,
      customStudentId: (storedCustomStudentId ?? '').trim(),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseError(error.code));
    }
  }

  Future<void> sendEmailVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  bool isEmailVerified() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.emailVerified ?? false;
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
      case 'EMAIL_EXISTS':
        return 'Is email se account already bana hua hai.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'INVALID_PASSWORD':
      case 'EMAIL_NOT_FOUND':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email ya password sahi nahi hai.';
      case 'weak-password':
      case 'WEAK_PASSWORD':
        return 'Password kam se kam 6 characters ka hona chahiye.';
      case 'network-request-failed':
        return 'Network issue hai. Internet check karo.';
      case 'too-many-requests':
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'Bahut attempts ho gaye. Thodi der baad try karo.';
      case 'account-exists-with-different-credential':
        return 'Is email par doosre sign-in method se account bana hua hai.';
      default:
        return 'Firebase auth error: $code';
    }
  }
}
