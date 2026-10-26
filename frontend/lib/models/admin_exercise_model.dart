class AdminExercise {
  final String id;
  final String name;
  final String instructions;
  final String equipmentRequired;
  final double baseCaloriesBurn;
  final double metValue;
  final String? mediaUrl;

  const AdminExercise({
    required this.id,
    required this.name,
    required this.instructions,
    required this.equipmentRequired,
    required this.baseCaloriesBurn,
    required this.metValue,
    this.mediaUrl,
  });

  factory AdminExercise.fromJson(Map<String, dynamic> json) {
    return AdminExercise(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      equipmentRequired: (json['equipment_required'] ?? '').toString(),
      baseCaloriesBurn: double.tryParse('${json['base_calories_burn']}') ?? 0,
      // MySQL DECIMAL datang sebagai String lewat mysql2, jadi parse dari string
      metValue: double.tryParse('${json['met_value']}') ?? 1.0,
      mediaUrl: json['media_url']?.toString(),
    );
  }
}
