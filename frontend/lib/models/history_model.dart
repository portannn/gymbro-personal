class WorkoutHistory {
  final int id;
  final String userId;
  final String workoutName;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime date;

  WorkoutHistory({
    required this.id,
    required this.userId,
    required this.workoutName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.date,
  });

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) {
    return WorkoutHistory(
      id: json['id'],
      userId: json['user_id'],
      workoutName: json['workout_name'],
      durationMinutes: json['duration_minutes'],
      caloriesBurned: json['calories_burned'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'workout_name': workoutName,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'date': date.toIso8601String(),
    };
  }
}
