import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class DailyResultSaveResult {
  final bool success;
  final bool isFirstAttempt;
  final int pointsAwarded;

  const DailyResultSaveResult({
    required this.success,
    this.isFirstAttempt = false,
    this.pointsAwarded = 0,
  });
}

class DailyResultService {
  Future<DailyResultSaveResult> saveFirstAttempt({
    required AppSession session,
    required AppTest test,
    required ResultSummary summary,
  }) async {
    if (!test.isDaily || session.isGuest || Firebase.apps.isEmpty) {
      return const DailyResultSaveResult(success: false);
    }

    final uid = _resolveUid(session);
    if (uid.isEmpty) {
      return const DailyResultSaveResult(success: false);
    }

    final dateKey = _todayKey();
    final userDocRef = _userDocRef(dateKey, uid);
    final attemptsRef = userDocRef.collection('attempts');

    final existingAttempts = await attemptsRef.limit(1).get();
    final isFirstAttempt = existingAttempts.docs.isEmpty;

    final userSummary = _buildUserSummary(
      session: session,
      uid: uid,
      dateKey: dateKey,
    );

    await userDocRef.set(
      userSummary,
      SetOptions(merge: true),
    );

    final attemptPayload = _buildAttemptPayload(
      session: session,
      test: test,
      summary: summary,
      uid: uid,
      dateKey: dateKey,
      leaderboardEligible: isFirstAttempt,
    );

    await attemptsRef.add(attemptPayload);

    // autoritative points for leaderboard are actually calculated in LeaderboardService,
    // but for the UI we show a nominal reward if it's the first attempt.
    return DailyResultSaveResult(
      success: true,
      isFirstAttempt: isFirstAttempt,
      pointsAwarded: isFirstAttempt ? (summary.correct * 10) + 50 : 0,
    );
  }

  String _resolveUid(AppSession session) {
    final authUser = FirebaseAuth.instance.currentUser;
    return session.uid.trim().isNotEmpty ? session.uid.trim() : authUser?.uid ?? '';
  }

  DocumentReference<Map<String, dynamic>> _userDocRef(String dateKey, String uid) {
    return FirebaseFirestore.instance
        .collection('daily_results')
        .doc(dateKey)
        .collection('users')
        .doc(uid);
  }

  Map<String, dynamic> _buildUserSummary({
    required AppSession session,
    required String uid,
    required String dateKey,
  }) {
    return {
      'uid': uid,
      'name': session.name,
      'email': session.email,
      'mode': session.mode,
      'customStudentId': session.customStudentId,
      'date': dateKey,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildAttemptPayload({
    required AppSession session,
    required AppTest test,
    required ResultSummary summary,
    required String uid,
    required String dateKey,
    required bool leaderboardEligible,
  }) {
    return {
      'uid': uid,
      'name': session.name,
      'email': session.email,
      'mode': session.mode,
      'customStudentId': session.customStudentId,
      'leaderboard_eligible': leaderboardEligible,
      'date': dateKey,
      'test_id': test.id,
      'test_name': test.title,
      'subject': test.subject,
      'chapter_name': test.chapter,
      'score': summary.correct,
      'total': summary.total,
      'percent': summary.percent,
      'time_taken_sec': summary.timeSpentSec,
      'submitted_at': FieldValue.serverTimestamp(),
    };
  }

  String _todayKey() {
    final today = DateTime.now();
    return '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
  }
}
