import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart'; // For jsonEncode, jsonDecode

class ExercisePerformance {
  String actionName;
  int targetReps;
  int completedReps;
  int failedAttempts;

  ExercisePerformance({
    required this.actionName,
    required this.targetReps,
    this.completedReps = 0,
    this.failedAttempts = 0,
  });

  void recordAttempt(String resultType) {
    if (resultType == "Sempurna") {
      completedReps++;
    } else {
      failedAttempts++;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "action_name": actionName,
      "target_reps": targetReps,
      "completed_reps": completedReps,
      "failed_attempts": failedAttempts,
    };
  }

  factory ExercisePerformance.fromJson(Map<String, dynamic> json) {
    return ExercisePerformance(
      actionName: json["action_name"] as String,
      targetReps: json["target_reps"] as int,
      completedReps: json["completed_reps"] as int,
      failedAttempts: json["failed_attempts"] as int,
    );
  }
}

// Untuk menyimpan/memuat history


const String HISTORY_KEY = 'rehab_history';

Future<List<ExercisePerformance>> loadHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final String? historyString = prefs.getString(HISTORY_KEY);
  if (historyString == null) {
    return [];
  }
  try {
    final List<dynamic> jsonList = jsonDecode(historyString);
    return jsonList.map((e) => ExercisePerformance.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    print("Error decoding history: $e");
    return [];
  }
}

Future<void> saveHistory(List<ExercisePerformance> historyData) async {
  final prefs = await SharedPreferences.getInstance();
  final List<Map<String, dynamic>> jsonList = historyData.map((e) => e.toJson()).toList();
  await prefs.setString(HISTORY_KEY, jsonEncode(jsonList));
}