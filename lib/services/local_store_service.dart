import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

class LocalStoreService {
  static const _notebookKey = 'sudarshan_mobile_notebook_cards';
  static const _customTestsKey = 'sudarshan_mobile_custom_tests';
  static const _attemptsKey = 'sudarshan_mobile_attempts';
  static const _cloudTestsKey = 'sudarshan_mobile_cloud_tests';
  static const _lastDailyAlertKey = 'sudarshan_mobile_last_daily_alert';
  static const _lastLeaderboardRankKey = 'sudarshan_mobile_last_daily_rank';

  Future<List<NotebookCard>> loadNotebookCards() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notebookKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => NotebookCard.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveNotebookCards(List<NotebookCard> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cards.map((item) => item.toJson()).toList());
    await prefs.setString(_notebookKey, encoded);
  }

  Future<List<AppTest>> loadCustomTests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customTestsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => AppTest.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCustomTests(List<AppTest> tests) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tests.map((item) => item.toJson()).toList());
    await prefs.setString(_customTestsKey, encoded);
  }

  Future<List<AppAttempt>> loadAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_attemptsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => AppAttempt.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAttempts(List<AppAttempt> attempts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(attempts.map((item) => item.toJson()).toList());
    await prefs.setString(_attemptsKey, encoded);
  }

  Future<List<AppTest>> loadCachedCloudTests() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cloudTestsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map>()
          .map((item) => AppTest.fromJson(item.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCachedCloudTests(List<AppTest> tests) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tests.map((item) => item.toJson()).toList());
    await prefs.setString(_cloudTestsKey, encoded);
  }

  Future<bool> shouldNotifyDailyTest(String testId) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_lastDailyAlertKey) ?? '';
    if (previous == testId) {
      return false;
    }
    await prefs.setString(_lastDailyAlertKey, testId);
    return true;
  }

  Future<int?> loadLastDailyRank() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_lastLeaderboardRankKey)) {
      return null;
    }
    return prefs.getInt(_lastLeaderboardRankKey);
  }

  Future<void> saveLastDailyRank(int? rank) async {
    final prefs = await SharedPreferences.getInstance();
    if (rank == null || rank <= 0) {
      await prefs.remove(_lastLeaderboardRankKey);
      return;
    }
    await prefs.setInt(_lastLeaderboardRankKey, rank);
  }
}
