import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

import '../config/mobile_config.dart';
import 'google_auth_helper.dart';

class GoogleAuthHelperImpl implements GoogleAuthHelper {
  @override
  Future<UserCredential?> signIn() async {
    HttpServer? server;
    try {
      // 1. Start local loopback server to receive the code
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port';

      // 2. PKCE - Proof Key for Code Exchange
      final codeVerifier = _generateRandomString(64);
      final codeChallenge = _base64UrlNoPadding(sha256.convert(utf8.encode(codeVerifier)).bytes);

      // 3. Construct Google Auth URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': MobileFirebaseConfig.googleWebClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'select_account',
      });

      // 4. Open URL in Default Browser
      if (!await launchUrl(authUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch default browser.');
      }

      // 5. Wait for the redirect callback
      final request = await server.first;
      final code = request.uri.queryParameters['code'];
      
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write('<html lang="en"><body style="font-family:sans-serif; text-align:center; padding:50px;">'
          '<h1>Authentication Successful</h1>'
          '<p>You can close this window and return to Sudarshan app.</p>'
          '</body></html>');
      await request.response.close();

      if (code == null) {
        throw Exception('No auth code received from Google.');
      }

      // 6. Exchange code for Token
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'client_id': MobileFirebaseConfig.googleWebClientId,
          'code': code,
          'code_verifier': codeVerifier,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Token exchange failed: ${tokenResponse.body}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final idToken = tokenData['id_token'];
      final accessToken = tokenData['access_token'];

      // 7. Sign in with Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      throw Exception('Windows Google Sign-In Error: $e');
    } finally {
      await server?.close();
    }
  }

  String _generateRandomString(int length) {
    const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _base64UrlNoPadding(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  @override
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
