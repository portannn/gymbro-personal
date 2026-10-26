class Workout {
  final String id;
  final String title;
  final String difficulty;
  final String locationType;
  final String category;
  final String description;
  final int? durationMinutes;
  final int exerciseCount;
  final String equipmentSummary;
  final String? fitnessGoal;
  final double? caloriesBurned;

  const Workout({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.locationType,
    required this.category,
    required this.description,
    this.durationMinutes,
    required this.exerciseCount,
    required this.equipmentSummary,
    this.fitnessGoal,
    this.caloriesBurned,
  });

  Workout copyWith({
    String? id,
    String? title,
    String? difficulty,
    String? locationType,
    String? category,
    String? description,
    int? durationMinutes,
    int? exerciseCount,
    String? equipmentSummary,
    String? fitnessGoal,
    double? caloriesBurned,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      difficulty: difficulty ?? this.difficulty,
      locationType: locationType ?? this.locationType,
      category: category ?? this.category,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exerciseCount: exerciseCount ?? this.exerciseCount,
      equipmentSummary: equipmentSummary ?? this.equipmentSummary,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    
    return Workout(
      id: _readString(json, 'id'),
      title: _readString(json, 'title'),
      difficulty: _readString(json, 'difficulty'),
      locationType: _readString(json, 'location_type'),
      category: _readString(json, 'category'),
      description: _readString(json, 'description'),
      durationMinutes: _readInt(json, 'duration_minutes'),
      exerciseCount: _readInt(json, 'exercise_count') ?? 0,
      equipmentSummary: _readString(json, 'equipment_summary'),
      fitnessGoal: _readString(json, 'fitness_goal'),
      caloriesBurned: _readDouble(json, 'calories_burned'),
    );
  }

  static String _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return '';
    return value.toString();
  }

  static int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
