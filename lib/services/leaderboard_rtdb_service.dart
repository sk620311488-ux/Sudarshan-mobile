import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class LeaderboardRtdbService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  static const String _basePath = 'leaderboards';

  /// Syncs a user's attempt to RTDB for the daily leaderboard.
  Future<void> syncDailyAttempt({
    required String dateKey,
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    if (Firebase.apps.isEmpty) return;

    final ref = _db.ref('$_basePath/daily/$dateKey/$uid');
    await ref.set(data);
  }

  /// Watches the daily leaderboard for a specific dateKey in realtime.
  Stream<LeaderboardView> watchDailyLeaderboard({
    required String dateKey,
    String? currentUid,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(const LeaderboardView(
        period: LeaderboardPeriod.daily,
        entries: [],
        totalParticipants: 0,
      ));
    }

    final ref = _db.ref('$_basePath/daily/$dateKey');

    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return const LeaderboardView(
          period: LeaderboardPeriod.daily,
          entries: [],
          totalParticipants: 0,
        );
      }

      final rawData = snapshot.value as Map<dynamic, dynamic>;
      final entries = <DailyLeaderboardEntry>[];

      rawData.forEach((key, value) {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          entries.add(DailyLeaderboardEntry.fromJson(map));
        }
      });

      // Sort entries by points (descending), then score, then time (ascending)
      entries.sort((a, b) {
        final pointsCompare = b.points.compareTo(a.points);
        if (pointsCompare != 0) return pointsCompare;

        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;

        return a.timeTakenSec.compareTo(b.timeTakenSec);
      });

      // Assign ranks
      final rankedEntries = entries.asMap().entries.map((item) {
        return item.value.copyWith(rank: item.key + 1);
      }).toList();

      DailyLeaderboardEntry? currentUserEntry;
      if (currentUid != null) {
        try {
          currentUserEntry = rankedEntries.firstWhere((e) => e.uid == currentUid);
        } catch (_) {
          currentUserEntry = null;
        }
      }

      return LeaderboardView(
        period: LeaderboardPeriod.daily,
        entries: rankedEntries,
        totalParticipants: rankedEntries.length,
        currentUser: currentUserEntry,
      );
    });
  }
}
