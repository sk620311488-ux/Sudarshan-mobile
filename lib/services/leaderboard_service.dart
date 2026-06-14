import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/app_models.dart';

class LeaderboardService {
  static const _dailyResultsCollection = 'daily_results';
  static const _userProfilesCollection = 'user_profiles';

  // Cache mechanism
  static final Map<String, _CachedBoard> _cache = {};
  static const _cacheDuration = Duration(minutes: 5);

  Future<LeaderboardView> loadLeaderboard({
    required LeaderboardPeriod period,
    String? currentUid,
    DateTime? anchorDate,
    bool forceRefresh = false,
  }) async {
    if (Firebase.apps.isEmpty) {
      return _emptyBoard(period);
    }

    final anchor = anchorDate ?? DateTime.now();
    final cacheKey = '${period.name}_${_dateKey(anchor)}';

    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.view.copyWith(
          currentUser: _findCurrentUser(cached.view.entries, currentUid),
        );
      }
    }

    final dateKeys = _dateKeysForPeriod(period, anchor);

    try {
      final daySnapshots = await Future.wait(
        dateKeys.map(
          (dateKey) => FirebaseFirestore.instance
              .collection(_dailyResultsCollection)
              .doc(dateKey)
              .collection('users')
              .get(),
        ),
      );

      final aggregated = <String, _AggregateEntry>{};
      for (final snapshot in daySnapshots) {
        await _mergeDaySnapshot(snapshot, aggregated);
      }

      await _hydrateMissingStudentIds(aggregated);

      final rankedEntries = aggregated.values
          .map(_toLeaderboardEntry)
          .toList()
        ..sort(_compareEntries);

      final entriesWithRank = rankedEntries
          .asMap()
          .entries
          .map((item) => item.value.copyWith(rank: item.key + 1))
          .toList();

      final view = LeaderboardView(
        period: period,
        entries: entriesWithRank,
        totalParticipants: entriesWithRank.length,
      );

      _cache[cacheKey] = _CachedBoard(
        view: view,
        timestamp: DateTime.now(),
      );

      return view.copyWith(
        currentUser: _findCurrentUser(entriesWithRank, currentUid),
      );
    } catch (error) {
      // ignore: avoid_print
      print('Leaderboard error ($period): $error');
      return _emptyBoard(period);
    }
  }

  Stream<LeaderboardView> watchLeaderboard({
    required LeaderboardPeriod period,
    String? currentUid,
    DateTime? anchorDate,
    bool forceRefresh = false,
  }) {
    if (Firebase.apps.isEmpty) {
      return Stream.value(_emptyBoard(period));
    }

    final dateKeys = _dateKeysForPeriod(period, anchorDate ?? DateTime.now());
    final controller = StreamController<LeaderboardView>();
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    var closed = false;

    Future<void> emitLatest({bool force = false}) async {
      if (closed) {
        return;
      }
      final board = await loadLeaderboard(
        period: period,
        currentUid: currentUid,
        anchorDate: anchorDate,
        forceRefresh: force,
      );
      if (!closed) {
        controller.add(board);
      }
    }

    for (final dateKey in dateKeys) {
      final subscription = FirebaseFirestore.instance
          .collection(_dailyResultsCollection)
          .doc(dateKey)
          .collection('users')
          .snapshots()
          .listen(
        (_) => emitLatest(),
        onError: controller.addError,
      );
      subscriptions.add(subscription);
    }

    controller.onListen = () => emitLatest(force: forceRefresh);
    controller.onCancel = () async {
      closed = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Future<void> _mergeDaySnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    Map<String, _AggregateEntry> aggregated,
  ) async {
    final eligibleAttemptSnapshots = await Future.wait(
      snapshot.docs.map(
        (doc) => doc.reference
            .collection('attempts')
            .where('leaderboard_eligible', isEqualTo: true)
            .get(),
      ),
    );

    for (var i = 0; i < snapshot.docs.length; i++) {
      final userDoc = snapshot.docs[i];
      final uid = userDoc.id;
      final attemptsSnapshot = eligibleAttemptSnapshots[i];

      if (attemptsSnapshot.docs.isEmpty) {
        final legacyAttempt = _AttemptData.tryFromLegacyUserDoc(uid, userDoc.data());
        if (legacyAttempt != null) {
          final existing = aggregated[uid];
          aggregated[uid] = existing == null
              ? _AggregateEntry.first(legacyAttempt)
              : existing.merge(legacyAttempt);
        }
        continue;
      }

      for (final attemptDoc in attemptsSnapshot.docs) {
        final attempt = _AttemptData.fromFirestore(uid, attemptDoc.data());
        final existing = aggregated[uid];
        aggregated[uid] =
            existing == null ? _AggregateEntry.first(attempt) : existing.merge(attempt);
      }
    }
  }

  Future<void> _hydrateMissingStudentIds(
    Map<String, _AggregateEntry> aggregated,
  ) async {
    final missingIds = aggregated.entries
        .where((entry) => entry.value.customStudentId.isEmpty)
        .map((entry) => entry.key)
        .toList();
    if (missingIds.isEmpty) {
      return;
    }

    try {
      final profileSnapshots = await Future.wait(
        missingIds.map(
          (uid) => FirebaseFirestore.instance
              .collection(_userProfilesCollection)
              .doc(uid)
              .get(),
        ),
      );

      for (var i = 0; i < missingIds.length; i++) {
        final customStudentId =
            (profileSnapshots[i].data()?['customStudentId'] ?? '').toString().trim();
        if (customStudentId.isEmpty) {
          continue;
        }
        final uid = missingIds[i];
        final existing = aggregated[uid];
        if (existing == null) {
          continue;
        }
        aggregated[uid] = existing.copyWith(customStudentId: customStudentId);
      }
    } catch (_) {
      // Profile hydration is best-effort; leaderboard data should still render.
    }
  }

  DailyLeaderboardEntry _toLeaderboardEntry(_AggregateEntry aggregate) {
    final avgPercent = aggregate.totalPossible == 0
        ? 0
        : ((aggregate.totalScore / aggregate.totalPossible) * 100).round();
    return DailyLeaderboardEntry(
      uid: aggregate.uid,
      name: aggregate.name,
      email: aggregate.email,
      dateKey: aggregate.bestDateKey,
      percent: avgPercent,
      score: aggregate.totalScore,
      total: aggregate.totalPossible,
      timeTakenSec: aggregate.totalTimeTakenSec,
      attemptCount: aggregate.attemptCount,
      leaderboardEligible: true,
      customStudentId: aggregate.customStudentId,
    );
  }

  int _compareEntries(DailyLeaderboardEntry a, DailyLeaderboardEntry b) {
    final pointsCompare = b.points.compareTo(a.points);
    if (pointsCompare != 0) {
      return pointsCompare;
    }

    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }

    final percentCompare = b.percent.compareTo(a.percent);
    if (percentCompare != 0) {
      return percentCompare;
    }

    return a.timeTakenSec.compareTo(b.timeTakenSec);
  }

  DailyLeaderboardEntry? _findCurrentUser(
    List<DailyLeaderboardEntry> entries,
    String? currentUid,
  ) {
    if (currentUid == null || currentUid.trim().isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.uid == currentUid) {
        return entry;
      }
    }
    return null;
  }

  LeaderboardView _emptyBoard(LeaderboardPeriod period) {
    return LeaderboardView(
      period: period,
      entries: const [],
      totalParticipants: 0,
    );
  }

  List<String> _dateKeysForPeriod(LeaderboardPeriod period, DateTime anchor) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return [_dateKey(anchor)];
      case LeaderboardPeriod.weekly:
        return List.generate(
          7,
          (index) => _dateKey(anchor.subtract(Duration(days: index))),
        );
      case LeaderboardPeriod.monthly:
        return List.generate(
          30,
          (index) => _dateKey(anchor.subtract(Duration(days: index))),
        );
    }
  }

  String _dateKey(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

class _CachedBoard {
  final LeaderboardView view;
  final DateTime timestamp;

  _CachedBoard({required this.view, required this.timestamp});
}

class _AttemptData {
  const _AttemptData({
    required this.uid,
    required this.name,
    required this.email,
    required this.customStudentId,
    required this.score,
    required this.total,
    required this.percent,
    required this.timeTakenSec,
    required this.dateKey,
  });

  final String uid;
  final String name;
  final String email;
  final String customStudentId;
  final int score;
  final int total;
  final int percent;
  final int timeTakenSec;
  final String dateKey;

  factory _AttemptData.fromFirestore(String uid, Map<String, dynamic> data) {
    return _AttemptData(
      uid: uid,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      customStudentId: (data['customStudentId'] ?? '').toString().trim(),
      score: int.tryParse((data['score'] ?? 0).toString()) ?? 0,
      total: int.tryParse((data['total'] ?? 0).toString()) ?? 0,
      percent: int.tryParse((data['percent'] ?? 0).toString()) ?? 0,
      timeTakenSec: int.tryParse(
            (data['time_taken_sec'] ?? data['timeTakenSec'] ?? 0).toString(),
          ) ??
          0,
      dateKey: (data['date'] ?? data['dateKey'] ?? '').toString(),
    );
  }

  static _AttemptData? tryFromLegacyUserDoc(String uid, Map<String, dynamic> data) {
    final eligible = data['leaderboard_eligible'] != false;
    final hasScore = data.containsKey('score') && data.containsKey('total');
    if (!eligible || !hasScore) {
      return null;
    }
    return _AttemptData.fromFirestore(uid, data);
  }
}

class _AggregateEntry {
  const _AggregateEntry({
    required this.uid,
    required this.name,
    required this.email,
    required this.customStudentId,
    required this.totalScore,
    required this.totalPossible,
    required this.maxPercent,
    required this.totalTimeTakenSec,
    required this.bestDateKey,
    required this.attemptCount,
  });

  final String uid;
  final String name;
  final String email;
  final String customStudentId;
  final int totalScore;
  final int totalPossible;
  final int maxPercent;
  final int totalTimeTakenSec;
  final String bestDateKey;
  final int attemptCount;

  factory _AggregateEntry.first(_AttemptData attempt) {
    return _AggregateEntry(
      uid: attempt.uid,
      name: attempt.name,
      email: attempt.email,
      customStudentId: attempt.customStudentId,
      totalScore: attempt.score,
      totalPossible: attempt.total,
      maxPercent: attempt.percent,
      totalTimeTakenSec: attempt.timeTakenSec,
      bestDateKey: attempt.dateKey,
      attemptCount: 1,
    );
  }

  _AggregateEntry merge(_AttemptData attempt) {
    return _AggregateEntry(
      uid: uid,
      name: name.isNotEmpty ? name : attempt.name,
      email: email.isNotEmpty ? email : attempt.email,
      customStudentId:
          customStudentId.isNotEmpty ? customStudentId : attempt.customStudentId,
      totalScore: totalScore + attempt.score,
      totalPossible: totalPossible + attempt.total,
      maxPercent: attempt.percent > maxPercent ? attempt.percent : maxPercent,
      totalTimeTakenSec: totalTimeTakenSec + attempt.timeTakenSec,
      bestDateKey: attempt.dateKey,
      attemptCount: attemptCount + 1,
    );
  }

  _AggregateEntry copyWith({
    String? customStudentId,
  }) {
    return _AggregateEntry(
      uid: uid,
      name: name,
      email: email,
      customStudentId: customStudentId ?? this.customStudentId,
      totalScore: totalScore,
      totalPossible: totalPossible,
      maxPercent: maxPercent,
      totalTimeTakenSec: totalTimeTakenSec,
      bestDateKey: bestDateKey,
      attemptCount: attemptCount,
    );
  }
}
