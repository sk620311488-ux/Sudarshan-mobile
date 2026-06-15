import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show AppLifecycleState;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/daily_result_service.dart';
import '../services/export_service.dart';
import '../services/leaderboard_service.dart';
import '../services/local_store_service.dart';
import '../services/mission_service.dart';
import '../services/notification_service.dart';
import '../services/progress_cloud_service.dart';
import '../services/social_service.dart';
import '../services/test_service.dart';
import '../services/user_cloud_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    AuthService? authService,
    DailyResultService? dailyResultService,
    UserCloudService? userCloudService,
    TestService? testService,
    LocalStoreService? localStoreService,
    NotificationService? notificationService,
    LeaderboardService? leaderboardService,
    ProgressCloudService? progressCloudService,
    SocialService? socialService,
    AiService? aiService,
    MissionService? missionService,
    ExportService? exportService,
  })  : _authService = authService ?? AuthService(),
        _dailyResultService = dailyResultService ?? DailyResultService(),
        _userCloudService = userCloudService ?? UserCloudService(),
        _testService = testService ?? TestService(),
        _localStoreService = localStoreService ?? LocalStoreService(),
        _notificationService = notificationService ?? NotificationService(),
        _leaderboardService = leaderboardService ?? LeaderboardService(),
        _progressCloudService = progressCloudService ?? ProgressCloudService(),
        _socialService = socialService ?? SocialService(),
        _aiService = aiService ?? AiService(),
        _missionService = missionService ?? MissionService(),
        _exportService = exportService ?? ExportService();

  final AuthService _authService;
  final DailyResultService _dailyResultService;
  final UserCloudService _userCloudService;
  final TestService _testService;
  final LocalStoreService _localStoreService;
  final NotificationService _notificationService;
  final LeaderboardService _leaderboardService;
  final ProgressCloudService _progressCloudService;
  final SocialService _socialService;
  final AiService _aiService;
  final MissionService _missionService;
  final ExportService _exportService;

  AppSession? _session;
  List<AppTest> _liveTests = const [];
  List<AppTest> _customTests = const [];
  List<NotebookCard> _notebookCards = const [];
  List<AppAttempt> _attempts = const [];
  List<DailyMission> _missions = const [];
  int _totalExp = 0;
  bool _booting = true;
  bool _busy = false;
  bool _isRefreshingTests = false;
  String _message = '';
  bool _isAppInForeground = true;

  AppSession? get session => _session;
  List<AppTest> get tests => [..._liveTests, ..._customTests];
  List<AppAttempt> get attempts => [..._attempts];
  List<DailyMission> get missions => [..._missions];
  bool get isBooting => _booting;
  bool get isBusy => _busy;
  bool get isRefreshingTests => _isRefreshingTests;
  String get message => _message;
  bool get hasSession => _session?.signedIn == true;
  bool get isGuestMode => _session?.isGuest == true;
  bool get canUseCloudFeatures => _session != null && !_session!.isGuest;
  TrialStatus get trialStatus =>
      const TrialStatus(daysLeft: 7, planName: 'Starter Trial');

  List<NotebookCard> get notebookCards {
    final items = [..._notebookCards];
    items.sort((a, b) {
      if (a.isDue != b.isDue) {
        return a.isDue ? -1 : 1;
      }
      return a.dueAt.compareTo(b.dueAt);
    });
    return items;
  }

  List<NotebookCard> get dueCards =>
      notebookCards.where((item) => item.isDue).toList();
  int get dailyAttemptCount => _attempts.where((item) => item.isDaily).length;
  int get practiceAttemptCount =>
      _attempts.where((item) => !item.isDaily).length;
  int get publishedTestCount =>
      _liveTests.where((item) => item.isPublished).length;
  int get dailyTestCount => _liveTests.where((item) => item.isDaily).length;
  int get customTestCount => _customTests.length;
  int get cachedCloudTestCount => _liveTests.length;
  int get totalQuestionCount =>
      tests.fold(0, (sum, item) => sum + item.questionCount);
  AppAttempt? get latestAttempt => _attempts.isEmpty ? null : _attempts.last;
  DailyLeaderboardEntry? _dailyLeaderboardEntry;
  DailyLeaderboardEntry? get dailyLeaderboardEntry => _dailyLeaderboardEntry;

  static const _themeKey = 'sudarshan_mobile_theme_dark';
  static const _onboardingKey = 'sudarshan_mobile_onboarding_done';
  static const _expKey = 'sudarshan_mobile_total_exp';

  bool _isDarkMode = false;
  bool _onboardingDone = false;

  bool get isDarkMode => _isDarkMode;
  bool get onboardingDone => _onboardingDone;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      _booting = true;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      _onboardingDone = prefs.getBool(_onboardingKey) ?? false;
      _totalExp = prefs.getInt(_expKey) ?? 0;
      _idChangeCount = prefs.getInt(_idChangeCountKey) ?? 0;
      _lastIdChangeDate = prefs.getString(_idChangeDateKey) ?? '';

      await _notificationService.initialize();

      // 1. Load critical local data first for instant UI
      _session = await _authService.loadSession();
      final results = await Future.wait([
        _localStoreService.loadNotebookCards(),
        _localStoreService.loadCustomTests(),
        _localStoreService.loadAttempts(),
        _localStoreService.loadCachedCloudTests(),
      ]);

      _notebookCards = results[0] as List<NotebookCard>;
      _customTests = results[1] as List<AppTest>;
      _attempts = results[2] as List<AppAttempt>;
      _liveTests = results[3] as List<AppTest>;
      _missions = await _missionService.getMissions();
    } catch (e) {
      debugPrint('Initialization error: $e');
    } finally {
      // 2. De-prioritize cloud hydration to let UI render
      _booting = false;
      notifyListeners();
    }

    try {
      await _notificationService.scheduleDailyReminder();
      _backgroundInit();
    } catch (e) {
      debugPrint('Post-init background tasks error: $e');
    }
  }

  Future<void> _backgroundInit() async {
    if (_session != null && !_session!.isGuest) {
      try {
        _session = await _userCloudService.hydrateSessionProfile(_session!);
        await _authService.saveSession(_session!);

        // Always ensure the profile (and ID) is synced on boot for logged in users
        await _userCloudService.ensureUserProfile(_session!);

        // Parallel non-critical cloud tasks
        await Future.wait([
          _loadCloudProgressIfAvailable(),
          _syncPublicProfileIfAvailable(),
          refreshTests(),
        ]);
      } catch (e) {
        debugPrint('Background init error: $e');
      }
    } else {
      await refreshTests();
    }

    await _refreshDailyLeaderboard(silent: true);
    notifyListeners();
  }

  Future<void> refreshTests() async {
    _isRefreshingTests = true;
    notifyListeners();
    try {
      final fetched = await _testService.loadTests();
      if (fetched.isNotEmpty) {
        _liveTests = fetched;
        await _localStoreService.saveCachedCloudTests(fetched);
        _message = 'Live tests loaded';
      } else {
        final cached = await _localStoreService.loadCachedCloudTests();
        _liveTests = cached.isNotEmpty ? cached : _fallbackTests;
        _message = cached.isNotEmpty
            ? 'Cloud tests cache se loaded'
            : 'Live tests not found, demo fallback loaded';
      }
    } catch (_) {
      final cached = await _localStoreService.loadCachedCloudTests();
      _liveTests = cached.isNotEmpty ? cached : _fallbackTests;
      _message = cached.isNotEmpty
          ? 'Offline mode: cached cloud tests loaded'
          : 'Cloud fetch fail hua, demo fallback loaded';
    } finally {
      _isRefreshingTests = false;
      notifyListeners();
    }
    await _maybeNotifyForDailyTest();
    await _refreshDailyLeaderboard(silent: true);
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    _busy = true;
    _message = '';
    notifyListeners();
    try {
      _session = await _authService.continueAsGuest();
      await refreshTests();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _busy = true;
    _message = '';
    notifyListeners();
    try {
      final previousGuest = _session?.isGuest == true ? _session : null;
      _session =
          await _authService.signInWithEmail(email: email, password: password);
      await _handlePostAuthSync(previousGuest: previousGuest);
      await refreshTests();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    _busy = true;
    _message = '';
    notifyListeners();
    try {
      final previousGuest = _session?.isGuest == true ? _session : null;
      _session = await _authService.signUpWithEmail(
          name: name, email: email, password: password);
      await _handlePostAuthSync(previousGuest: previousGuest);
      await refreshTests();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _busy = true;
    _message = '';
    notifyListeners();
    try {
      final previousGuest = _session?.isGuest == true ? _session : null;
      _session = await _authService.signInWithGoogle();
      await _handlePostAuthSync(previousGuest: previousGuest);
      await refreshTests();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _session = null;
    _dailyLeaderboardEntry = null;
    notifyListeners();
  }

  Future<void> _handlePostAuthSync({AppSession? previousGuest}) async {
    if (_session == null) {
      return;
    }
    if (!_session!.isGuest) {
      _session = await _userCloudService.hydrateSessionProfile(_session!);
      if (previousGuest != null &&
          _session!.customStudentId.trim().isEmpty &&
          previousGuest.customStudentId.trim().isNotEmpty) {
        _session = _session!.copyWith(
          customStudentId: previousGuest.customStudentId.trim(),
        );
      }
      await _authService.saveSession(_session!);
    }
    await _userCloudService.ensureUserProfile(_session!);
    await _loadCloudProgressIfAvailable();
    await _syncPublicProfileIfAvailable();
    if (previousGuest != null &&
        previousGuest.uid != _session!.uid &&
        !(_session?.isGuest ?? true)) {
      final migrated = await _userCloudService.migrateGuestDataToUser(
        guestSession: previousGuest,
        userSession: _session!,
        attempts: _attempts,
      );
      _message = migrated > 0
          ? 'Guest daily data account me merge ho gaya.'
          : 'Account upgrade complete. Local progress safe hai.';
      await _syncCloudProgressIfAvailable();
      await _syncPublicProfileIfAvailable();
      await _refreshDailyLeaderboard(silent: true);
      notifyListeners();
      return;
    }
    await _syncCloudProgressIfAvailable();
    await _syncPublicProfileIfAvailable();
  }

  Future<void> handleAppResume() async {
    await refreshTests();
  }

  void updateAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (_isAppInForeground) {
      // ऐप फिर से फोरग्राउंड में आया - लीडरबोर्ड अपडेट करें
      _refreshDailyLeaderboard(silent: true);
    }
  }

  Future<void> updateFlashcard(NotebookCard updatedCard) async {
    final index = _notebookCards.indexWhere(
      (item) =>
          item.question == updatedCard.question &&
          item.chapter == updatedCard.chapter &&
          item.topic == updatedCard.topic,
    );
    if (index >= 0) {
      final merged = [..._notebookCards];
      merged[index] = updatedCard;
      _notebookCards = merged;
      await _localStoreService.saveNotebookCards(_notebookCards);
      await _syncCloudProgressIfAvailable();
      notifyListeners();
    }
  }

  // SM-2 Algorithm for Spaced Repetition
  Future<void> recordFlashcardFeedback(
      NotebookCard card, String quality) async {
    int interval = card.interval;
    double ease = card.easeFactor;
    int reps = card.repetitionCount;
    int mistakes = card.mistakeCount;

    if (quality == 'again') {
      reps = 0;
      interval = 1;
      mistakes += 1;
    } else if (quality == 'good') {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
      reps++;
    } else if (quality == 'easy') {
      if (reps == 0) {
        interval = 4;
      } else {
        interval = (interval * ease * 1.3).round();
      }
      reps++;
      ease += 0.15;
    }

    // Constraints
    if (ease < 1.3) ease = 1.3;
    if (interval < 1) interval = 1;

    final nextDue = DateTime.now().add(Duration(days: interval));

    final updatedCard = card.copyWith(
      interval: interval,
      easeFactor: ease,
      repetitionCount: reps,
      mistakeCount: mistakes,
      dueAtIso: nextDue.toIso8601String(),
      scheduleLabel: interval == 1 ? '1 day' : '$interval days',
    );

    await updateFlashcard(updatedCard);
    await updateMissionProgress('cards', 1);
    await updateMissionProgress('streak', 1);
  }

  int get dailyStreak {
    if (_attempts.isEmpty) return 0;

    final dates = _attempts
        .where((item) => item.isDaily)
        .map((e) => e.dateKey)
        .toSet()
        .toList();
    if (dates.isEmpty) return 0;
    dates.sort((a, b) => b.compareTo(a)); // Newest first

    int streak = 0;
    DateTime current = DateTime.now();

    for (String dateStr in dates) {
      try {
        final date = DateTime.parse(dateStr);
        final diff = DateTime(current.year, current.month, current.day)
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;

        if (diff == streak) {
          streak++;
        } else if (diff > streak) {
          break;
        }
      } catch (_) {
        continue;
      }
    }
    return streak;
  }

  // Level System Logic
  int get totalExp => _totalExp;

  int get userLevel {
    // Quadratic scaling for levels: Level L ends at 300 * L^2 EXP
    // This makes early levels (1-3) reachable in 2-3 tests each.
    // Late levels become significantly harder.
    // Level 1: 0 to 300
    // Level 2: 300 to 1200 (Total diff 900)
    // Level 3: 1200 to 2700
    if (_totalExp < 300) return 1;
    int level = (math.sqrt(_totalExp / 300)).floor() + 1;
    return level.clamp(1, 100);
  }

  double get levelProgress {
    int currentLvl = userLevel;
    int currentLevelStartExp = 300 * (currentLvl - 1) * (currentLvl - 1);
    int nextLevelStartExp = 300 * currentLvl * currentLvl;

    int expInCurrentLevel = _totalExp - currentLevelStartExp;
    int totalNeededForNext = nextLevelStartExp - currentLevelStartExp;

    if (totalNeededForNext <= 0) return 1.0;

    return (expInCurrentLevel / totalNeededForNext).clamp(0.0, 1.0);
  }

  int get nextLevelExp => 300 * userLevel * userLevel;

  String get rankTitle {
    final lvl = userLevel;
    if (lvl >= 40) return 'Sudarshan Immortal';
    if (lvl >= 30) return 'Divine Sage';
    if (lvl >= 20) return 'Grandmaster';
    if (lvl >= 15) return 'Expert Mentor';
    if (lvl >= 10) return 'Advanced Learner';
    if (lvl >= 5) return 'Rising Star';
    return 'Novice';
  }

  static const _idChangeCountKey = 'sudarshan_mobile_id_change_count';
  static const _idChangeDateKey = 'sudarshan_mobile_id_change_date';

  int _idChangeCount = 0;
  String _lastIdChangeDate = '';

  Future<void> updateStudentId(String newId) async {
    if (_session == null || newId.trim().isEmpty) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastIdChangeDate != today) {
      _idChangeCount = 0;
      _lastIdChangeDate = today;
    }

    if (_idChangeCount >= 2) {
      _message = 'Daily limit reached! Bas din mein 2 baar hi ID change kar sakte hain.';
      notifyListeners();
      return;
    }

    _busy = true;
    notifyListeners();
    try {
      final updated = _session!.copyWith(customStudentId: newId.trim().toUpperCase());
      _session = updated;
      await _authService.saveSession(_session!);
      if (!_session!.isGuest) {
        await _userCloudService.ensureUserProfile(_session!);
        await _syncPublicProfileIfAvailable();
      }
      
      _idChangeCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_idChangeCountKey, _idChangeCount);
      await prefs.setString(_idChangeDateKey, _lastIdChangeDate);

      _message = 'Student ID updated successfully!';
    } catch (e) {
      _message = 'Failed to update Student ID.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  List<String> get achievements {
    final list = <String>[];
    if (dailyStreak >= 3) list.add('🔥 3 Day Streak');
    if (dailyStreak >= 7) list.add('👑 Weekly Warrior');
    if (dailyStreak >= 30) list.add('💎 Monthly Legend');

    if (_attempts.length >= 10) list.add('📚 10 Tests Done');
    if (_attempts.length >= 50) list.add('🏛️ Century of Knowledge');

    if (_notebookCards.length >= 20) list.add('🧠 Memory Master');
    if (_notebookCards.length >= 100) list.add('🦾 Cyborg Brain');

    if (userLevel >= 5) list.add('🎖️ Elite Tier');
    if (userLevel >= 10) list.add('🏆 Max Level Reached');

    final bestPercent = _attempts.isEmpty ? 0 : _attempts.map((e) => e.percent).reduce((a, b) => a > b ? a : b);
    if (bestPercent == 100) list.add('🎯 Perfectionist');

    return list;
  }

  PublicStudentProfile? get publicProfile {
    final session = _session;
    if (session == null || session.isGuest) {
      return null;
    }
    return PublicStudentProfile(
      uid: session.uid,
      name: session.name,
      email: session.email,
      customStudentId: session.customStudentId,
      rankTitle: rankTitle,
      level: userLevel,
      totalExp: _totalExp,
      dailyStreak: dailyStreak,
      attemptCount: _attempts.length,
      notebookCount: _notebookCards.length,
      achievements: achievements,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  Future<void> deleteNotebookCard(NotebookCard card) async {
    _notebookCards = _notebookCards
        .where((item) =>
            item.question != card.question ||
            item.topic != card.topic ||
            item.chapter != card.chapter)
        .toList();
    await _localStoreService.saveNotebookCards(_notebookCards);
    await _syncCloudProgressIfAvailable();
    await _syncPublicProfileIfAvailable();
    notifyListeners();
  }

  Future<void> exportNotebookAsPdf() async {
    await _exportService.exportNotebookToPdf(_notebookCards);
  }

  Future<void> updateMissionProgress(String id, int increment) async {
    await _missionService.updateProgress(id, increment);
    _missions = await _missionService.getMissions();
    notifyListeners();
  }

  Future<void> addManualFlashcard({
    required String subject,
    required String chapter,
    required String topic,
    required String question,
    required String answer,
  }) async {
    final card = NotebookCard(
      subject: subject.trim().isEmpty ? 'General' : subject.trim(),
      chapter: chapter.trim(),
      topic: topic.trim().isEmpty ? 'general' : topic.trim(),
      question: question.trim(),
      answer: answer.trim(),
      options: const [],
      questionType: 'Subjective',
      scheduleLabel: 'Due now',
      dueAtIso: DateTime.now().toIso8601String(),
      mistakeCount: 0,
    );
    final merged = [..._notebookCards];
    final index = merged.indexWhere(
      (item) =>
          item.question == card.question &&
          item.chapter == card.chapter &&
          item.topic == card.topic,
    );
    if (index >= 0) {
      merged[index] = card;
    } else {
      merged.add(card);
    }
    _notebookCards = merged;
    await _localStoreService.saveNotebookCards(_notebookCards);
    await _syncCloudProgressIfAvailable();
    await _syncPublicProfileIfAvailable();
    notifyListeners();
  }

  Future<void> addCustomTest(AppTest test) async {
    final merged = [..._customTests];
    final index = merged.indexWhere((item) => item.id == test.id);
    if (index >= 0) {
      merged[index] = test;
    } else {
      merged.add(test);
    }
    _customTests = merged;
    await _localStoreService.saveCustomTests(_customTests);
    notifyListeners();
  }

  Future<bool> finalizeResult({
    required AppTest test,
    required ResultSummary summary,
  }) async {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final attempt = AppAttempt(
      testId: test.id,
      testTitle: test.title,
      subject: test.subject,
      chapter: test.chapter,
      dateKey: dateKey,
      score: summary.correct,
      total: summary.total,
      percent: summary.percent,
      timeSpentSec: summary.timeSpentSec,
      isDaily: test.isDaily,
      isPublished: test.isPublished,
      savedAtIso: now.toIso8601String(),
    );
    _attempts = [..._attempts, attempt];
    await _localStoreService.saveAttempts(_attempts);

    _totalExp += summary.earnedExp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expKey, _totalExp);

    await updateMissionProgress('tests', 1);
    await updateMissionProgress('streak', 1);

    // Always sync EXP and progress to cloud after any test
    await _syncCloudProgressIfAvailable();
    await _syncPublicProfileIfAvailable();

    if (test.isDaily && _session != null) {
      try {
        if (_session!.isGuest) {
          final saved = await _userCloudService.saveGuestDailyAttempt(
            session: _session!,
            test: test,
            summary: summary,
          );
          _message = saved
              ? 'Guest daily score cloud par safe ho gaya. Leaderboard ke liye login karein.'
              : 'Daily score local me save hua.';
          notifyListeners();
          return saved;
        }

        // authoritative Daily Points check from server
        final cloudResult = await _dailyResultService.saveFirstAttempt(
          session: _session!,
          test: test,
          summary: summary,
        );

        if (cloudResult.success) {
          if (cloudResult.isFirstAttempt) {
            _message = 'पहली कोशिश बोनस: ${cloudResult.pointsAwarded} लीडरबोर्ड अंक जोड़े गए!';
            // We update the summary object (locally) to reflect server's confirmation
            // This is handled in the UI by passing the modified summary or message
          } else {
            _message = 'दैनिक परिणाम सिंक किया गया (पहली कोशिश के लिए अंक पहले से दिए जा चुके हैं)।';
          }
        }
        await _refreshDailyLeaderboard(silent: true);
        notifyListeners();
        return cloudResult.isFirstAttempt;
      } catch (_) {
        _message = 'दैनिक परिणाम स्थानीय रूप से सहेजा गया, क्लाउड सिंक विफल हुआ।';
        notifyListeners();
      }
    } else {
      _message = 'प्रगति क्लाउड में सिंक की गई।';
      notifyListeners();
    }
    return false;
  }

  Future<void> _maybeNotifyForDailyTest() async {
    AppTest? daily;
    for (final item in _liveTests) {
      if (item.isDaily) {
        daily = item;
        break;
      }
    }
    if (daily == null) {
      return;
    }
    final shouldNotify =
        await _localStoreService.shouldNotifyDailyTest(daily.id);
    if (!shouldNotify) {
      return;
    }
    await _notificationService.showDailyTestNotification(
      title: 'New daily test is ready',
      body: '${daily.title} ko sabse pehle try karo.',
    );
  }

  Future<void> _refreshDailyLeaderboard({required bool silent}) async {
    if (!_isAppInForeground) {
      // ऐप बैकग्राउंड में है, लीडरबोर्ड refresh न करें
      return;
    }

    if (_session == null || _session!.isGuest) {
      _dailyLeaderboardEntry = null;
      await _localStoreService.saveLastDailyRank(null);
      return;
    }

    try {
      final board = await _leaderboardService.loadLeaderboard(
        period: LeaderboardPeriod.daily,
        currentUid: _session!.uid,
      );
      final previousRank = await _localStoreService.loadLastDailyRank();
      _dailyLeaderboardEntry = board.currentUser;
      final currentRank = board.currentUser?.rank;
      if (previousRank != null &&
          currentRank != null &&
          currentRank > previousRank) {
        await _notificationService.showLeaderboardDropNotification(
          newRank: currentRank,
        );
      }
      await _localStoreService.saveLastDailyRank(currentRank);
      if (!silent) {
        notifyListeners();
      }
    } catch (_) {
      if (!silent) {
        notifyListeners();
      }
    }
  }

  ResultSummary recordResult({
    required AppTest test,
    required List<int?> answers,
    required int timeSpentSec,
    required bool timedOut,
    Map<int, String> subjectiveAnswers = const {},
  }) {
    var correct = 0;
    final weakTopics = <String, int>{};
    final freshCards = <NotebookCard>[];
    final questionReviews = <QuestionReview>[];
    final nowIso = DateTime.now().toIso8601String();

    for (var i = 0; i < test.questions.length; i++) {
      final question = test.questions[i];
      final selectedAnswer = question.isObjective
          ? (answers[i] != null && answers[i]! >= 0 && answers[i]! < question.options.length
              ? question.options[answers[i]!]
              : '')
          : (subjectiveAnswers[i] ?? '').trim();
      if (question.isObjective) {
        final isCorrect = answers[i] == question.answerIndex;
        questionReviews.add(
          QuestionReview(
            index: i,
            question: question.question,
            selectedAnswer: selectedAnswer,
            correctAnswer: question.answerText,
            isCorrect: isCorrect,
            explanation: question.explanation,
            options: question.options,
            questionType: question.questionType,
            topic: question.topic,
          ),
        );
        if (isCorrect) {
          correct += 1;
          continue;
        }
      } else {
        // Subjective: For now, we consider them "correct" for EXP if answered,
        // or maybe just tracked. User asked for "check rubric".
        // Let's assume subjective answers gain base EXP if not empty.
        if (subjectiveAnswers[i]?.trim().isNotEmpty == true) {
          // Subjective answers don't automatically count as "correct" in score
          // but we track them.
        }
        questionReviews.add(
          QuestionReview(
            index: i,
            question: question.question,
            selectedAnswer: selectedAnswer,
            correctAnswer: question.answerText,
            isCorrect: false,
            isScored: false,
            explanation: question.explanation,
            options: question.options,
            questionType: question.questionType,
            topic: question.topic,
          ),
        );
        continue;
      }

      weakTopics[question.topic] = (weakTopics[question.topic] ?? 0) + 1;
      freshCards.add(
        NotebookCard(
          subject: test.subject,
          chapter: test.chapter,
          topic: question.topic,
          question: question.question,
          answer: question.answerText,
          options: question.options,
          questionType: question.questionType,
          scheduleLabel: 'Due now',
          dueAtIso: nowIso,
          mistakeCount: 1,
        ),
      );
    }

    _mergeNotebookCards(freshCards);
    final total = test.questions.length;
    final scoredTotal = questionReviews.where((item) => item.isScored).length;
    final percent = scoredTotal == 0 ? 0 : ((correct / scoredTotal) * 100).round();

    // Balanced EXP Calculation
    final earnedExp = (correct * 5) + (percent ~/ 2) + (subjectiveAnswers.length * 10);

    return ResultSummary(
      correct: correct,
      total: total,
      percent: percent,
      timeSpentSec: timeSpentSec,
      timedOut: timedOut,
      weakTopics: weakTopics,
      subjectiveAnswers: subjectiveAnswers,
      questionReviews: questionReviews,
      earnedExp: earnedExp,
    );
  }

  List<NotebookCard> get last10WrongQuestions {
    final cards = _notebookCards.where((item) => item.mistakeCount > 0).toList();
    // Sort by added date (dueAtIso roughly correlates if fresh) or just take last 10
    // Actually, fresh cards from recordResult are added to the end.
    if (cards.length <= 10) return cards.reversed.toList();
    return cards.sublist(cards.length - 10).reversed.toList();
  }

  AppTest createRetryTest(List<NotebookCard> cards) {
    return AppTest(
      id: 'retry-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Retry: Wrong Questions',
      subject: cards.isNotEmpty ? cards.first.subject : 'Revision',
      chapter: 'Mixed Topics',
      level: 'Revision',
      timeLimitMin: (cards.length * 1.5).ceil(),
      questions: cards.map((c) => AppQuestion(
        question: c.question,
        options: c.options,
        correct: c.answer,
        topic: c.topic,
        questionType: c.questionType,
      )).toList(),
    );
  }

  Future<void> _mergeNotebookCards(List<NotebookCard> freshCards) async {
    if (freshCards.isEmpty) {
      return;
    }
    final merged = [..._notebookCards];
    for (final card in freshCards) {
      final index = merged.indexWhere(
        (item) =>
            item.question == card.question &&
            item.chapter == card.chapter &&
            item.topic == card.topic,
      );
      if (index >= 0) {
        final existing = merged[index];
        merged[index] = existing.copyWith(
          scheduleLabel: card.scheduleLabel,
          dueAtIso: card.dueAtIso,
          interval: card.interval > existing.interval ? card.interval : existing.interval,
          easeFactor: card.easeFactor > existing.easeFactor ? card.easeFactor : existing.easeFactor,
          repetitionCount: card.repetitionCount > existing.repetitionCount ? card.repetitionCount : existing.repetitionCount,
          mistakeCount: existing.mistakeCount + card.mistakeCount,
          options: card.options.isNotEmpty ? card.options : existing.options,
          questionType: card.questionType.isNotEmpty ? card.questionType : existing.questionType,
        );
      } else {
        merged.add(card);
      }
    }
    _notebookCards = merged;
    await _localStoreService.saveNotebookCards(_notebookCards);
    await _syncPublicProfileIfAvailable();
    notifyListeners();
  }

  Future<void> _loadCloudProgressIfAvailable() async {
    final session = _session;
    if (session == null || session.isGuest) {
      return;
    }

    final snapshot = await _progressCloudService.loadProgress(session.uid);
    if (snapshot == null) {
      return;
    }

    _attempts = _mergeAttempts(_attempts, snapshot.attempts);
    _notebookCards = _mergeNotebookCardsFromSources(
      _notebookCards,
      snapshot.notebookCards,
    );
    _totalExp = math.max(_totalExp, snapshot.totalExp);

    // If we have more fields in progress, we could load them here.
    // Derived fields like achievements and rankTitle will naturally update
    // because _attempts and _totalExp are now updated.

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expKey, _totalExp);
    await _localStoreService.saveAttempts(_attempts);
    await _localStoreService.saveNotebookCards(_notebookCards);
  }

  Future<void> _syncCloudProgressIfAvailable() async {
    final session = _session;
    if (session == null || session.isGuest) {
      return;
    }

    try {
      await _progressCloudService.saveProgress(
        session: session,
        attempts: _attempts,
        notebookCards: _notebookCards,
        totalExp: _totalExp,
        achievements: achievements,
        rankTitle: rankTitle,
      );
    } catch (_) {
      // Local state remains the source of truth; sync can retry later.
    }
  }

  Future<void> _syncPublicProfileIfAvailable() async {
    final profile = publicProfile;
    if (profile == null) {
      return;
    }

    try {
      await _socialService.upsertPublicProfile(profile);
    } catch (_) {
      // Public profile sync is best-effort.
    }
  }

  Future<PublicStudentProfile?> searchProfileByStudentId(String studentId) {
    return _socialService.findProfileByStudentId(studentId);
  }

  Stream<List<PublicStudentProfile>> watchFriendProfiles() {
    final session = _session;
    if (session == null || session.isGuest) {
      return const Stream<List<PublicStudentProfile>>.empty();
    }
    return _socialService.watchFriendProfiles(session.uid);
  }

  Future<List<PublicStudentProfile>> loadFriendProfiles() async {
    final session = _session;
    if (session == null || session.isGuest) {
      return const [];
    }
    return _socialService.getFriendProfiles(session.uid);
  }

  Future<void> addFriend(PublicStudentProfile friend) async {
    final session = _session;
    if (session == null || session.isGuest) {
      return;
    }
    await _socialService.addFriend(owner: session, friend: friend);
  }

  Future<void> sendFriendRequest(String toUid, {String message = ''}) async {
    final session = _session;
    if (session == null || session.isGuest) return;
    await _socialService.sendFriendRequest(
      fromUid: session.uid,
      fromName: session.name.isEmpty ? 'Student' : session.name,
      toUid: toUid,
      message: message,
    );
  }

  Future<void> respondToFriendRequest(FriendRequest request, FriendRequestStatus status) async {
    final session = _session;
    if (session == null || session.isGuest) return;
    await _socialService.respondToFriendRequest(
      request: request,
      status: status,
      currentSession: session,
    );
  }

  Stream<List<FriendRequest>> watchIncomingRequests() {
    final session = _session;
    if (session == null || session.isGuest) return const Stream.empty();
    return _socialService.watchIncomingRequests(session.uid);
  }

  Future<List<PublicStudentProfile>> getMutualFriends(String otherUid) async {
    final session = _session;
    if (session == null || session.isGuest) return const [];
    return _socialService.getMutualFriends(session.uid, otherUid);
  }

  Future<void> removeFriend(String friendUid) async {
    final session = _session;
    if (session == null || session.isGuest) {
      return;
    }
    await _socialService.removeFriend(
      ownerUid: session.uid,
      friendUid: friendUid,
    );
  }

  // Local Analytics Logic
  Map<String, double> get subjectMastery {
    if (_attempts.isEmpty) return {};
    final totals = <String, List<int>>{};
    for (final a in _attempts) {
      totals.putIfAbsent(a.subject, () => []).add(a.percent);
    }
    return totals.map((sub, list) => MapEntry(sub, list.reduce((a, b) => a + b) / list.length));
  }

  List<int> get weeklyActivity {
    final counts = List.filled(7, 0);
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      counts[i] = _attempts.where((a) => a.dateKey == key).length;
    }
    return counts;
  }

  Map<String, int> get topWeakTopics {
    final topics = <String, int>{};
    for (final card in _notebookCards) {
      // Repetition count is low or interval is small implies it's a weak area
      if (card.repetitionCount < 3) {
        topics[card.topic] = (topics[card.topic] ?? 0) + 1;
      }
    }
    final sortedEntries = topics.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries.take(5));
  }

  // AI Features
  Future<Map<String, dynamic>> aiEvaluateSubjective({
    required String question,
    required String modelAnswer,
    required String studentAnswer,
  }) async {
    return _aiService.evaluateSubjectiveAnswer(
      question: question,
      modelAnswer: modelAnswer,
      studentAnswer: studentAnswer,
    );
  }

  Future<String> aiExplainQuestion({
    required String question,
    required String answer,
    String explanation = '',
  }) async {
    return _aiService.explainQuestion(
      question: question,
      answer: answer,
      explanation: explanation,
    );
  }

  Future<String> aiAnalyzePerformance() async {
    return _aiService.analyzePerformance(
      attempts: _attempts,
      mastery: subjectMastery,
    );
  }

  List<AppAttempt> _mergeAttempts(
    List<AppAttempt> primary,
    List<AppAttempt> secondary,
  ) {
    final merged = <String, AppAttempt>{};
    for (final item in [...primary, ...secondary]) {
      final key = '${item.testId}|${item.dateKey}|${item.savedAtIso}';
      final existing = merged[key];
      if (existing == null || item.savedAtIso.compareTo(existing.savedAtIso) > 0) {
        merged[key] = item;
      }
    }
    final items = merged.values.toList()
      ..sort((a, b) => a.savedAtIso.compareTo(b.savedAtIso));
    return items;
  }

  List<NotebookCard> _mergeNotebookCardsFromSources(
    List<NotebookCard> primary,
    List<NotebookCard> secondary,
  ) {
    final merged = <String, NotebookCard>{};
    for (final card in [...primary, ...secondary]) {
      final key = '${card.chapter}|${card.topic}|${card.question}';
      final existing = merged[key];
      if (existing == null) {
        merged[key] = card;
        continue;
      }
      merged[key] = _preferNotebookCard(existing, card);
    }
    return merged.values.toList();
  }

  NotebookCard _preferNotebookCard(NotebookCard a, NotebookCard b) {
    if (b.mistakeCount != a.mistakeCount) {
      return b.mistakeCount > a.mistakeCount ? b : a;
    }
    if (b.repetitionCount != a.repetitionCount) {
      return b.repetitionCount > a.repetitionCount ? b : a;
    }
    if (b.interval != a.interval) {
      return b.interval > a.interval ? b : a;
    }
    return b.dueAt.isAfter(a.dueAt) ? b : a;
  }
}

final _fallbackTests = <AppTest>[
  const AppTest(
    id: 'fallback-daily',
    title: 'Daily Weak Topic Drill',
    subject: 'Science',
    chapter: 'Chemical Reactions',
    level: 'Level 1',
    timeLimitMin: 12,
    isPublished: true,
    isDaily: true,
    questions: [
      AppQuestion(
        question:
            'Neutralization reaction me acid aur base milkar kya banate hain?',
        options: ['Salt and water', 'Only oxygen', 'Only gas', 'Only metal'],
        correct: 'Salt and water',
        topic: 'Acids and Bases',
        questionType: 'MCQ',
        explanation:
            'Acid aur base ke reaction se generally salt aur water banta hai.',
      ),
      AppQuestion(
        question: 'pH value 7 kis solution ko dikhati hai?',
        options: ['Acidic', 'Basic', 'Neutral', 'Salty'],
        correct: 'Neutral',
        topic: 'Acids and Bases',
        questionType: 'MCQ',
      ),
    ],
  ),
];
