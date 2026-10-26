class Exercise {
  final String id;
  final String name;
  final String instructions;
  final String equipmentRequired;
  final double? baseCaloriesBurn;
  final int? sequenceOrder;
  final String repsOrDuration;
  final String workoutId;
  final String workoutTitle;
  final String location;
  final String difficulty;
  final String category;
  final int? durationMinutes;

  const Exercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.equipmentRequired,
    this.baseCaloriesBurn,
    this.sequenceOrder,
    required this.repsOrDuration,
    required this.workoutId,
    required this.workoutTitle,
    required this.location,
    required this.difficulty,
    required this.category,
    this.durationMinutes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final name = _readString(json, ['nama_latihan', 'name', 'exercise_name']);
    final id = _readString(json, ['id', 'exercise_id']);

    return Exercise(
      id: id.isEmpty ? name : id,
      name: name,
      instructions:
          _readString(json, ['instructions', 'deskripsi_teknis', 'description']),
      equipmentRequired: _readString(json, ['equipment_required']),
      baseCaloriesBurn: _readDouble(json, ['base_calories_burn']),
      sequenceOrder: _readInt(json, ['sequence_order']),
      repsOrDuration: _readString(json, ['reps_or_duration']),
      workoutId: _readString(json, ['workout_id']),
      workoutTitle: _readString(json, ['workout_title', 'title']),
      location: _readString(json, ['location_type', 'location']),
      difficulty:
          _readString(json, ['difficulty', 'level', 'tingkat_kesulitan']),
      category: _readString(json, ['category']),
      durationMinutes: _readInt(json, ['duration_minutes']),
    );
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value.isEmpty) return null;
    return int.tryParse(value);
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }
}
