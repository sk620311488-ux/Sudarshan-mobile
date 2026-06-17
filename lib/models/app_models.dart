class AppQuestion {
  const AppQuestion({
    required this.question,
    required this.options,
    required this.correct,
    required this.topic,
    required this.questionType,
    this.explanation = '',
  });

  final String question;
  final List<String> options;
  final String correct;
  final String topic;
  final String questionType;
  final String explanation;

  bool get isObjective => options.isNotEmpty;

  String get answerText => correct;

  int get answerIndex {
    if (options.isEmpty) {
      return -1;
    }
    return options.indexWhere((item) => item.trim() == correct.trim());
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correct': correct,
      'topic': topic,
      'question_type': questionType,
      'explanation': explanation,
    };
  }

  factory AppQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList()
        : <String>[];
    final correctIndex = int.tryParse(
            (json['answer_index'] ?? json['answerIndex'] ?? '').toString()) ??
        -1;
    String correct = (json['correct'] ??
            json['model_answer'] ??
            json['answer'] ??
            json['correct_answer'] ??
            json['answerText'] ??
            '')
        .toString();
    if (correct.trim().isEmpty && correctIndex >= 0 && correctIndex < options.length) {
      correct = options[correctIndex];
    }
    return AppQuestion(
      question: (json['question'] ?? '').toString(),
      options: options,
      correct: correct,
      topic: (json['topic'] ?? 'general').toString(),
      questionType: (json['question_type'] ?? json['questionType'] ?? 'MCQ').toString(),
      explanation: (json['explanation'] ?? '').toString(),
    );
  }
}

class AppTest {
  const AppTest({
    required this.id,
    required this.title,
    required this.subject,
    required this.chapter,
    required this.level,
    required this.timeLimitMin,
    required this.questions,
    this.book = '',
    this.testType = 'MCQ',
    this.isPublished = false,
    this.isDaily = false,
    this.pyqYear = '',
  });

  final String id;
  final String title;
  final String subject;
  final String chapter;
  final String level;
  final int timeLimitMin;
  final List<AppQuestion> questions;
  final String book;
  final String testType;
  final bool isPublished;
  final bool isDaily;
  final String pyqYear;

  int get questionCount => questions.length;

  AppTest copyWith({
    String? id,
    String? title,
    String? subject,
    String? chapter,
    String? level,
    int? timeLimitMin,
    List<AppQuestion>? questions,
    String? book,
    String? testType,
    bool? isPublished,
    bool? isDaily,
    String? pyqYear,
  }) {
    return AppTest(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      level: level ?? this.level,
      timeLimitMin: timeLimitMin ?? this.timeLimitMin,
      questions: questions ?? this.questions,
      book: book ?? this.book,
      testType: testType ?? this.testType,
      isPublished: isPublished ?? this.isPublished,
      isDaily: isDaily ?? this.isDaily,
      pyqYear: pyqYear ?? this.pyqYear,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'chapter': chapter,
      'level': level,
      'timeLimitMin': timeLimitMin,
      'book': book,
      'testType': testType,
      'isPublished': isPublished,
      'isDaily': isDaily,
      'pyqYear': pyqYear,
      'questions': questions.map((item) => item.toJson()).toList(),
    };
  }

  factory AppTest.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    return AppTest(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? '').toString(),
      subject: (json['subject'] ?? 'General').toString(),
      chapter: (json['chapter'] ?? json['chapter_name'] ?? '').toString(),
      level: (json['level'] ?? 'Level 1').toString(),
      timeLimitMin: int.tryParse(
              (json['timeLimitMin'] ?? json['time_limit_min'] ?? 0)
                  .toString()) ??
          0,
      book: (json['book'] ?? '').toString(),
      testType: (json['testType'] ?? json['test_type'] ?? 'MCQ').toString(),
      pyqYear: (json['pyqYear'] ?? json['pyq_year'] ?? '').toString(),
      isPublished:
          json['isPublished'] == true || json['visibility'] == 'public',
      isDaily: json['isDaily'] == true || json['active'] == true,
      questions: rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map((item) => AppQuestion.fromJson(item.cast<String, dynamic>()))
              .toList()
          : <AppQuestion>[],
    );
  }
}

class NotebookCard {
  const NotebookCard({
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.question,
    required this.answer,
    required this.scheduleLabel,
    required this.dueAtIso,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitionCount = 0,
    this.mistakeCount = 0,
    this.options = const [],
    this.questionType = 'MCQ',
  });

  final String subject;
  final String chapter;
  final String topic;
  final String question;
  final String answer;
  final String scheduleLabel;
  final String dueAtIso;
  final int interval;
  final double easeFactor;
  final int repetitionCount;
  final int mistakeCount;
  final List<String> options;
  final String questionType;

  DateTime get dueAt =>
      DateTime.tryParse(dueAtIso)?.toLocal() ?? DateTime.now();

  bool get isDue => !dueAt.isAfter(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'question': question,
      'answer': answer,
      'scheduleLabel': scheduleLabel,
      'dueAtIso': dueAtIso,
      'interval': interval,
      'easeFactor': easeFactor,
      'repetitionCount': repetitionCount,
      'mistakeCount': mistakeCount,
      'options': options,
      'questionType': questionType,
    };
  }

  factory NotebookCard.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList()
        : <String>[];
    return NotebookCard(
      subject: (json['subject'] ?? 'General').toString(),
      chapter: (json['chapter'] ?? '').toString(),
      topic: (json['topic'] ?? 'general').toString(),
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      scheduleLabel: (json['scheduleLabel'] ?? 'Due now').toString(),
      dueAtIso:
          (json['dueAtIso'] ?? DateTime.now().toIso8601String()).toString(),
      interval: int.tryParse((json['interval'] ?? 0).toString()) ?? 0,
      easeFactor: double.tryParse((json['easeFactor'] ?? 2.5).toString()) ?? 2.5,
      repetitionCount: int.tryParse((json['repetitionCount'] ?? 0).toString()) ?? 0,
      mistakeCount: int.tryParse((json['mistakeCount'] ?? 0).toString()) ?? 0,
      options: options,
      questionType: (json['questionType'] ?? 'MCQ').toString(),
    );
  }

  NotebookCard copyWith({
    String? scheduleLabel,
    String? dueAtIso,
    int? interval,
    double? easeFactor,
    int? repetitionCount,
    int? mistakeCount,
    List<String>? options,
    String? questionType,
  }) {
    return NotebookCard(
      subject: subject,
      chapter: chapter,
      topic: topic,
      question: question,
      answer: answer,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      dueAtIso: dueAtIso ?? this.dueAtIso,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      options: options ?? this.options,
      questionType: questionType ?? this.questionType,
    );
  }
}

class QuestionReview {
  const QuestionReview({
    required this.index,
    required this.question,
    required this.correctAnswer,
    required this.isCorrect,
    this.isScored = true,
    this.selectedAnswer = '',
    this.explanation = '',
    this.options = const [],
    this.questionType = 'MCQ',
    this.topic = '',
  });

  final int index;
  final String question;
  final String selectedAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool isScored;
  final String explanation;
  final List<String> options;
  final String questionType;
  final String topic;
}

class AppSession {
  const AppSession({
    required this.mode,
    required this.uid,
    required this.name,
    required this.email,
    this.idToken = '',
    this.signedIn = false,
    this.customStudentId = '',
  });

  final String mode;
  final String uid;
  final String name;
  final String email;
  final String idToken;
  final bool signedIn;
  final String customStudentId;

  String get studentId => customStudentId.isNotEmpty
      ? customStudentId
      : (uid.length > 6 ? uid.substring(uid.length - 6).toUpperCase() : uid.toUpperCase());

  bool get isGuest => mode == 'guest';

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'uid': uid,
      'name': name,
      'email': email,
      'idToken': idToken,
      'signedIn': signedIn,
      'customStudentId': customStudentId,
    };
  }

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      mode: (json['mode'] ?? 'guest').toString(),
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      idToken: (json['idToken'] ?? '').toString(),
      signedIn: json['signedIn'] == true,
      customStudentId: (json['customStudentId'] ?? '').toString(),
    );
  }

  AppSession copyWith({
    String? name,
    String? email,
    String? customStudentId,
  }) {
    return AppSession(
      mode: mode,
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      idToken: idToken,
      signedIn: signedIn,
      customStudentId: customStudentId ?? this.customStudentId,
    );
  }
}

class TrialStatus {
  const TrialStatus({
    required this.daysLeft,
    required this.planName,
  });

  final int daysLeft;
  final String planName;
}

class ResultSummary {
  const ResultSummary({
    required this.correct,
    required this.total,
    required this.percent,
    required this.timeSpentSec,
    required this.timedOut,
    required this.weakTopics,
    this.subjectiveAnswers = const {},
    this.questionReviews = const [],
    this.earnedExp = 0,
    this.dailyPoints = 0,
  });

  final int correct;
  final int total;
  final int percent;
  final int timeSpentSec;
  final bool timedOut;
  final Map<String, int> weakTopics;
  final Map<int, String> subjectiveAnswers;
  final List<QuestionReview> questionReviews;
  final int earnedExp;
  final int dailyPoints;
}

class AppAttempt {
  const AppAttempt({
    required this.testId,
    required this.testTitle,
    required this.subject,
    required this.chapter,
    required this.dateKey,
    required this.score,
    required this.total,
    required this.percent,
    required this.timeSpentSec,
    required this.isDaily,
    required this.isPublished,
    required this.savedAtIso,
  });

  final String testId;
  final String testTitle;
  final String subject;
  final String chapter;
  final String dateKey;
  final int score;
  final int total;
  final int percent;
  final int timeSpentSec;
  final bool isDaily;
  final bool isPublished;
  final String savedAtIso;

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testTitle': testTitle,
      'subject': subject,
      'chapter': chapter,
      'dateKey': dateKey,
      'score': score,
      'total': total,
      'percent': percent,
      'timeSpentSec': timeSpentSec,
      'isDaily': isDaily,
      'isPublished': isPublished,
      'savedAtIso': savedAtIso,
    };
  }

  factory AppAttempt.fromJson(Map<String, dynamic> json) {
    return AppAttempt(
      testId: (json['testId'] ?? '').toString(),
      testTitle: (json['testTitle'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      chapter: (json['chapter'] ?? '').toString(),
      dateKey: (json['dateKey'] ?? '').toString(),
      score: int.tryParse((json['score'] ?? 0).toString()) ?? 0,
      total: int.tryParse((json['total'] ?? 0).toString()) ?? 0,
      percent: int.tryParse((json['percent'] ?? 0).toString()) ?? 0,
      timeSpentSec: int.tryParse((json['timeSpentSec'] ?? 0).toString()) ?? 0,
      isDaily: json['isDaily'] == true,
      isPublished: json['isPublished'] == true,
      savedAtIso: (json['savedAtIso'] ?? '').toString(),
    );
  }
}

class DailyLeaderboardEntry {
  const DailyLeaderboardEntry({
    required this.uid,
    required this.name,
    required this.percent,
    required this.score,
    required this.total,
    required this.timeTakenSec,
    this.attemptCount = 1,
    this.rank = 0,
    this.email = '',
    this.dateKey = '',
    this.leaderboardEligible = true,
    this.customStudentId = '',
    this.totalExp = 0,
  });

  final String uid;
  final String name;
  final String email;
  final String dateKey;
  final int percent;
  final int score;
  final int total;
  final int timeTakenSec;
  final int attemptCount;
  final int rank;
  final bool leaderboardEligible;
  final String customStudentId;
  final int totalExp;

  String get studentId => customStudentId.isNotEmpty
      ? customStudentId
      : (uid.length > 6 ? uid.substring(uid.length - 6).toUpperCase() : uid.toUpperCase());

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Student';
  }

  // Points based on EXP for leaderboard sorting
  int get points => totalExp > 0 ? totalExp : (score * 10) + (percent * 2) - (timeTakenSec ~/ 60);

  DailyLeaderboardEntry copyWith({int? rank}) {
    return DailyLeaderboardEntry(
      uid: uid,
      name: name,
      email: email,
      dateKey: dateKey,
      percent: percent,
      score: score,
      total: total,
      timeTakenSec: timeTakenSec,
      attemptCount: attemptCount,
      rank: rank ?? this.rank,
      leaderboardEligible: leaderboardEligible,
      customStudentId: customStudentId,
      totalExp: totalExp,
    );
  }

  factory DailyLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return DailyLeaderboardEntry(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      dateKey: (json['date'] ?? json['dateKey'] ?? '').toString(),
      percent: int.tryParse((json['percent'] ?? 0).toString()) ?? 0,
      score: int.tryParse((json['score'] ?? 0).toString()) ?? 0,
      total: int.tryParse((json['total'] ?? 0).toString()) ?? 0,
      attemptCount:
          int.tryParse((json['attempt_count'] ?? json['attemptCount'] ?? 1).toString()) ?? 1,
      timeTakenSec:
          int.tryParse((json['time_taken_sec'] ?? json['timeTakenSec'] ?? 0).toString()) ??
              0,
      rank: int.tryParse((json['rank'] ?? 0).toString()) ?? 0,
      leaderboardEligible: json['leaderboard_eligible'] != false,
      customStudentId: (json['customStudentId'] ?? '').toString(),
      totalExp: int.tryParse((json['totalExp'] ?? 0).toString()) ?? 0,
    );
  }
}

enum LeaderboardPeriod { daily, weekly, monthly }

extension LeaderboardPeriodX on LeaderboardPeriod {
  String get label {
    switch (this) {
      case LeaderboardPeriod.daily:
        return 'Daily';
      case LeaderboardPeriod.weekly:
        return 'Weekly';
      case LeaderboardPeriod.monthly:
        return 'Monthly';
    }
  }
}

class LeaderboardView {
  const LeaderboardView({
    required this.period,
    required this.entries,
    required this.totalParticipants,
    this.currentUser,
  });

  final LeaderboardPeriod period;
  final List<DailyLeaderboardEntry> entries;
  final int totalParticipants;
  final DailyLeaderboardEntry? currentUser;

  List<DailyLeaderboardEntry> get topTen =>
      entries.length <= 10 ? entries : entries.take(10).toList();

  int? get currentUserRank => currentUser?.rank;

  int? get currentUserTopPercent {
    final rank = currentUserRank;
    if (rank == null || totalParticipants <= 0) {
      return null;
    }
    final rawPercent = ((rank / totalParticipants) * 100).ceil();
    final normalized = ((rawPercent + 9) ~/ 10) * 10;
    return normalized.clamp(10, 100);
  }

  LeaderboardView copyWith({
    LeaderboardPeriod? period,
    List<DailyLeaderboardEntry>? entries,
    int? totalParticipants,
    DailyLeaderboardEntry? currentUser,
  }) {
    return LeaderboardView(
      period: period ?? this.period,
      entries: entries ?? this.entries,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}

class PublicStudentProfile {
  const PublicStudentProfile({
    required this.uid,
    required this.name,
    required this.customStudentId,
    required this.rankTitle,
    required this.level,
    required this.totalExp,
    required this.dailyStreak,
    required this.attemptCount,
    required this.notebookCount,
    required this.achievements,
    this.email = '',
    this.bio = '',
    this.updatedAtIso = '',
  });

  final String uid;
  final String name;
  final String email;
  final String customStudentId;
  final String rankTitle;
  final int level;
  final int totalExp;
  final int dailyStreak;
  final int attemptCount;
  final int notebookCount;
  final List<String> achievements;
  final String bio;
  final String updatedAtIso;

  String get displayName => name.trim().isEmpty ? 'Student' : name.trim();

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'customStudentId': customStudentId,
      'rankTitle': rankTitle,
      'level': level,
      'totalExp': totalExp,
      'dailyStreak': dailyStreak,
      'attemptCount': attemptCount,
      'notebookCount': notebookCount,
      'achievements': achievements,
      'bio': bio,
      'updatedAtIso': updatedAtIso,
    };
  }

  factory PublicStudentProfile.fromJson(Map<String, dynamic> json) {
    final rawAchievements = json['achievements'];
    return PublicStudentProfile(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      customStudentId: (json['customStudentId'] ?? '').toString(),
      rankTitle: (json['rankTitle'] ?? 'Novice').toString(),
      level: int.tryParse((json['level'] ?? 1).toString()) ?? 1,
      totalExp: int.tryParse((json['totalExp'] ?? 0).toString()) ?? 0,
      dailyStreak: int.tryParse((json['dailyStreak'] ?? 0).toString()) ?? 0,
      attemptCount: int.tryParse((json['attemptCount'] ?? 0).toString()) ?? 0,
      notebookCount: int.tryParse((json['notebookCount'] ?? 0).toString()) ?? 0,
      achievements: rawAchievements is List
          ? rawAchievements.map((item) => item.toString()).toList()
          : const <String>[],
      bio: (json['bio'] ?? '').toString(),
      updatedAtIso: (json['updatedAtIso'] ?? '').toString(),
    );
  }
}

class FriendLink {
  const FriendLink({
    required this.uid,
    required this.name,
    required this.customStudentId,
    this.rankTitle = '',
    this.level = 1,
    this.addedAtIso = '',
  });

  final String uid;
  final String name;
  final String customStudentId;
  final String rankTitle;
  final int level;
  final String addedAtIso;

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'customStudentId': customStudentId,
      'rankTitle': rankTitle,
      'level': level,
      'addedAtIso': addedAtIso,
    };
  }

  factory FriendLink.fromJson(Map<String, dynamic> json) {
    return FriendLink(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      customStudentId: (json['customStudentId'] ?? '').toString(),
      rankTitle: (json['rankTitle'] ?? '').toString(),
      level: int.tryParse((json['level'] ?? 1).toString()) ?? 1,
      addedAtIso: (json['addedAtIso'] ?? '').toString(),
    );
  }
}

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.status,
    this.message = '',
    this.createdAtIso = '',
  });

  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final FriendRequestStatus status;
  final String message;
  final String createdAtIso;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUid': fromUid,
      'fromName': fromName,
      'toUid': toUid,
      'status': status.name,
      'message': message,
      'createdAtIso': createdAtIso,
    };
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: (json['id'] ?? '').toString(),
      fromUid: (json['fromUid'] ?? '').toString(),
      fromName: (json['fromName'] ?? '').toString(),
      toUid: (json['toUid'] ?? '').toString(),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      message: (json['message'] ?? '').toString(),
      createdAtIso: (json['createdAtIso'] ?? '').toString(),
    );
  }
}
