import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DailyMission {
  final String id;
  final String title;
  final int goal;
  final int progress;
  final int rewardExp;
  final bool isCompleted;

  DailyMission({
    required this.id,
    required this.title,
    required this.goal,
    this.progress = 0,
    this.rewardExp = 50,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'goal': goal,
    'progress': progress,
    'rewardExp': rewardExp,
    'isCompleted': isCompleted,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) => DailyMission(
    id: json['id'],
    title: json['title'],
    goal: json['goal'],
    progress: json['progress'] ?? 0,
    rewardExp: json['rewardExp'] ?? 50,
    isCompleted: json['isCompleted'] ?? false,
  );

  DailyMission copyWith({int? progress, bool? isCompleted}) {
    return DailyMission(
      id: id,
      title: title,
      goal: goal,
      progress: progress ?? this.progress,
      rewardExp: rewardExp,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class MissionService {
  static const _key = 'sudarshan_daily_missions';
  static const _dateKey = 'sudarshan_missions_date';

  Future<List<DailyMission>> getMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();
    final savedDate = prefs.getString(_dateKey);

    if (savedDate != today) {
      return _generateNewMissions(prefs, today);
    }

    final raw = prefs.getString(_key);
    if (raw == null) return _generateNewMissions(prefs, today);

    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => DailyMission.fromJson(e)).toList();
  }

  Future<void> updateProgress(String id, int increment) async {
    final missions = await getMissions();
    final index = missions.indexWhere((m) => m.id == id);
    if (index == -1 || missions[index].isCompleted) return;

    final mission = missions[index];
    final newProgress = (mission.progress + increment).clamp(0, mission.goal);
    final completed = newProgress >= mission.goal;

    missions[index] = mission.copyWith(
      progress: newProgress,
      isCompleted: completed,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(missions.map((m) => m.toJson()).toList()));
  }

  Future<List<DailyMission>> _generateNewMissions(SharedPreferences prefs, String today) async {
    final newMissions = [
      DailyMission(id: 'tests', title: 'Take 2 Tests', goal: 2, rewardExp: 100),
      DailyMission(id: 'cards', title: 'Revise 5 Cards', goal: 5, rewardExp: 50),
      DailyMission(id: 'streak', title: 'Start Today\'s Streak', goal: 1, rewardExp: 30),
    ];

    await prefs.setString(_dateKey, today);
    await prefs.setString(_key, jsonEncode(newMissions.map((m) => m.toJson()).toList()));
    return newMissions;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
