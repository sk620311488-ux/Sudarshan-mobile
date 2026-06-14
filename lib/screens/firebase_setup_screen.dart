import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: const [
            SoftCard(
              color: AppColors.blueSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Planned Mobile Stack',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  SizedBox(height: 10),
                  Text('Firebase Auth: Guest, Email/Password, Google',
                      style: TextStyle(color: AppColors.text)),
                  SizedBox(height: 6),
                  Text('Firestore: public_tests, daily_tests, user progress',
                      style: TextStyle(color: AppColors.text)),
                  SizedBox(height: 6),
                  Text('Storage: optional PDFs and assets',
                      style: TextStyle(color: AppColors.text)),
                ],
              ),
            ),
            SizedBox(height: 14),
            SoftCard(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What To Add Next',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  SizedBox(height: 10),
                  Text('1. flutterfire configure',
                      style: TextStyle(color: AppColors.muted, height: 1.35)),
                  Text('2. firebase_core + firebase_auth + cloud_firestore',
                      style: TextStyle(color: AppColors.muted, height: 1.35)),
                  Text('3. real sign-in screens',
                      style: TextStyle(color: AppColors.muted, height: 1.35)),
                  Text('4. published test fetch + quiz save',
                      style: TextStyle(color: AppColors.muted, height: 1.35)),
                  Text('5. trial/paywall layer',
                      style: TextStyle(color: AppColors.muted, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
