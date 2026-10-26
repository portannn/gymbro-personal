class UserModel {
  final String id;
  final String fullName;
  final String email;
  final double? weight;
  final String role;
  final String? gender;
  final List<String>? goals;
  final double? targetWeight;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.weight,
    required this.role,
    this.gender,
    this.goals,
    this.targetWeight,
    this.onboardingCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      weight: _parseDouble(json['weight']),
      role: json['role'],
      gender: json['gender'],
      goals: json['goals'] != null ? List<String>.from(json['goals']) : null,
      targetWeight: _parseDouble(json['target_weight']),
      onboardingCompleted: json['onboarding_completed'] == 1 || json['onboarding_completed'] == true,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    double? weight,
    String? role,
    String? gender,
    List<String>? goals,
    double? targetWeight,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      weight: weight ?? this.weight,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      targetWeight: targetWeight ?? this.targetWeight,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}