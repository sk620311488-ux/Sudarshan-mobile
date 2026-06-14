import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class ProgressCloudSnapshot {
  const ProgressCloudSnapshot({
    required this.attempts,
    required this.notebookCards,
    required this.totalExp,
    this.achievements = const [],
    this.rankTitle = 'Novice',
  });

  final List<AppAttempt> attempts;
  final List<NotebookCard> notebookCards;
  final int totalExp;
  final List<String> achievements;
  final String rankTitle;
}

class ProgressCloudService {
  static const _progressCollection = 'user_progress';

  Future<ProgressCloudSnapshot?> loadProgress(String uid) async {
    if (Firebase.apps.isEmpty || uid.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot = await _progressRef(uid).get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      return ProgressCloudSnapshot(
        attempts: _decodeAttempts(data['attempts']),
        notebookCards: _decodeNotebookCards(data['notebookCards']),
        totalExp: int.tryParse((data['totalExp'] ?? 0).toString()) ?? 0,
        achievements: _decodeAchievements(data['achievements']),
        rankTitle: (data['rankTitle'] ?? 'Novice').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required AppSession session,
    required List<AppAttempt> attempts,
    required List<NotebookCard> notebookCards,
    required int totalExp,
    required List<String> achievements,
    required String rankTitle,
  }) async {
    if (Firebase.apps.isEmpty || session.isGuest || session.uid.trim().isEmpty) {
      return;
    }

    await _progressRef(session.uid).set(
      {
        'uid': session.uid,
        'attempts': attempts.map((item) => item.toJson()).toList(),
        'notebookCards': notebookCards.map((item) => item.toJson()).toList(),
        'totalExp': totalExp,
        'achievements': achievements,
        'rankTitle': rankTitle,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  DocumentReference<Map<String, dynamic>> _progressRef(String uid) {
    return FirebaseFirestore.instance.collection(_progressCollection).doc(uid);
  }

  List<AppAttempt> _decodeAttempts(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => AppAttempt.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  List<NotebookCard> _decodeNotebookCards(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => NotebookCard.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  List<String> _decodeAchievements(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.map((e) => e.toString()).toList();
  }
}
