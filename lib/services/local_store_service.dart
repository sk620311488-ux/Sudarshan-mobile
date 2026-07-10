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

  String _key(String base, String? userId) {
    if (userId == null || userId.trim().isEmpty) return base;
    return '${userId}_$base';
  }

  Future<List<NotebookCard>> loadNotebookCards(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_notebookKey, userId));
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

  Future<void> saveNotebookCards(List<NotebookCard> cards, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cards.map((item) => item.toJson()).toList());
    await prefs.setString(_key(_notebookKey, userId), encoded);
  }

  Future<List<AppTest>> loadCustomTests(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_customTestsKey, userId));
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

  Future<void> saveCustomTests(List<AppTest> tests, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tests.map((item) => item.toJson()).toList());
    await prefs.setString(_key(_customTestsKey, userId), encoded);
  }

  Future<List<AppAttempt>> loadAttempts(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_attemptsKey, userId));
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

  Future<void> saveAttempts(List<AppAttempt> attempts, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(attempts.map((item) => item.toJson()).toList());
    await prefs.setString(_key(_attemptsKey, userId), encoded);
  }

  Future<List<AppTest>> loadCachedCloudTests(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(_cloudTestsKey, userId));
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

  Future<void> saveCachedCloudTests(List<AppTest> tests, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tests.map((item) => item.toJson()).toList());
    await prefs.setString(_key(_cloudTestsKey, userId), encoded);
  }

  Future<bool> shouldNotifyDailyTest(String testId, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_key(_lastDailyAlertKey, userId)) ?? '';
    if (previous == testId) {
      return false;
    }
    await prefs.setString(_key(_lastDailyAlertKey, userId), testId);
    return true;
  }

  Future<int?> loadLastDailyRank(String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key(_lastLeaderboardRankKey, userId))) {
      return null;
    }
    return prefs.getInt(_key(_lastLeaderboardRankKey, userId));
  }

  Future<void> saveLastDailyRank(int? rank, String? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (rank == null || rank <= 0) {
      await prefs.remove(_key(_lastLeaderboardRankKey, userId));
      return;
    }
    await prefs.setInt(_key(_lastLeaderboardRankKey, userId), rank);
  }
}
