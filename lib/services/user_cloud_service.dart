import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class UserCloudService {
  Future<AppSession> hydrateSessionProfile(AppSession session) async {
    if (Firebase.apps.isEmpty || session.uid.trim().isEmpty) {
      return session;
    }

    try {
      final snapshot = await _userProfileRef(session.uid).get();
      final data = snapshot.data();
      if (data == null) {
        return session;
      }

      final customStudentId = (data['customStudentId'] ?? '').toString().trim();
      if (customStudentId.isEmpty || customStudentId == session.customStudentId) {
        return session;
      }

      return session.copyWith(customStudentId: customStudentId);
    } catch (_) {
      return session;
    }
  }

  Future<void> ensureUserProfile(AppSession session) async {
    if (Firebase.apps.isEmpty || session.uid.trim().isEmpty) {
      return;
    }

    final String studentId = session.studentId;

    final payload = <String, dynamic>{
      'uid': session.uid,
      'name': session.name,
      'email': session.email,
      'mode': session.mode,
      'leaderboard_eligible': !session.isGuest,
      'last_seen_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
      'customStudentId': studentId,
    };

    await _userProfileRef(session.uid).set(payload, SetOptions(merge: true));
  }

  Future<bool> saveGuestDailyAttempt({
    required AppSession session,
    required AppTest test,
    required ResultSummary summary,
  }) async {
    if (Firebase.apps.isEmpty || !session.isGuest || !test.isDaily) {
      return false;
    }

    final dateKey = _todayKey();
    final userDocRef = _guestDailyUserRef(dateKey, session.uid);
    final existing = await userDocRef.get();
    if (existing.exists) {
      return false;
    }

    await userDocRef.set(
      _buildDailyUserSummary(
        session: session,
        uid: session.uid,
        dateKey: dateKey,
      ),
    );

    await userDocRef.collection('attempts').add(
      _buildAttemptPayload(
        session: session,
        test: test,
        summary: summary,
        uid: session.uid,
        dateKey: dateKey,
        leaderboardEligible: false,
      ),
    );

    return true;
  }

  Future<int> migrateGuestDataToUser({
    required AppSession guestSession,
    required AppSession userSession,
    required List<AppAttempt> attempts,
  }) async {
    if (Firebase.apps.isEmpty ||
        !guestSession.isGuest ||
        userSession.isGuest ||
        guestSession.uid.trim().isEmpty ||
        userSession.uid.trim().isEmpty) {
      return 0;
    }

    final uniqueDates = attempts
        .where((item) => item.isDaily && item.dateKey.trim().isNotEmpty)
        .map((item) => item.dateKey.trim())
        .toSet()
        .toList()
      ..sort();

    var migratedCount = 0;

    for (final dateKey in uniqueDates) {
      final guestRef = _guestDailyUserRef(dateKey, guestSession.uid);
      final guestSnap = await guestRef.get();
      if (!guestSnap.exists) {
        continue;
      }
      final guestAttempts = await guestRef.collection('attempts').limit(1).get();
      final guestAttemptData = guestAttempts.docs.isNotEmpty
          ? guestAttempts.docs.first.data()
          : _legacyAttemptDataFromRoot(guestSnap.data());
      if (guestAttemptData == null) {
        continue;
      }

      final targetUserRef = _dailyUserRef(dateKey, userSession.uid);
      final targetAttemptsRef = targetUserRef.collection('attempts');
      final existingAttempts = await targetAttemptsRef.limit(1).get();

      await targetUserRef.set(
        _buildDailyUserSummary(
          session: userSession,
          uid: userSession.uid,
          dateKey: dateKey,
        ),
        SetOptions(merge: true),
      );

      if (existingAttempts.docs.isEmpty) {
        final migratedPayload = _buildMigratedAttemptPayload(
          guestAttemptData: guestAttemptData,
          guestUid: guestSession.uid,
          userSession: userSession,
        );
        await targetAttemptsRef.add(migratedPayload);
        migratedCount += 1;
      }

      await guestRef.set(
        {
          'migrated_to_uid': userSession.uid,
          'migrated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await _userProfileRef(userSession.uid).set(
      {
        'linked_guest_uids': FieldValue.arrayUnion([guestSession.uid]),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return migratedCount;
  }

  DocumentReference<Map<String, dynamic>> _userProfileRef(String uid) {
    return FirebaseFirestore.instance.collection('user_profiles').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _dailyUserRef(String dateKey, String uid) {
    return FirebaseFirestore.instance
        .collection('daily_results')
        .doc(dateKey)
        .collection('users')
        .doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _guestDailyUserRef(
    String dateKey,
    String uid,
  ) {
    return FirebaseFirestore.instance
        .collection('guest_daily_results')
        .doc(dateKey)
        .collection('users')
        .doc(uid);
  }

  Map<String, dynamic> _buildDailyUserSummary({
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

  Map<String, dynamic> _buildMigratedAttemptPayload({
    required Map<String, dynamic> guestAttemptData,
    required String guestUid,
    required AppSession userSession,
  }) {
    return {
      ...guestAttemptData,
      'uid': userSession.uid,
      'name': userSession.name,
      'email': userSession.email,
      'mode': userSession.mode,
      'customStudentId': userSession.customStudentId,
      'leaderboard_eligible': true,
      'migrated_from_guest_uid': guestUid,
      'migrated_at': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic>? _legacyAttemptDataFromRoot(Map<String, dynamic>? data) {
    if (data == null) {
      return null;
    }
    if (!data.containsKey('score') || !data.containsKey('total')) {
      return null;
    }
    return Map<String, dynamic>.from(data);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
