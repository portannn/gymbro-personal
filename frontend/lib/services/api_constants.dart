class ApiConstants {
  // 10.0.2.2 untuk Android emulator, localhost untuk iOS simulator / web
  static const String baseUrl = 'http://localhost:3000/api';

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // User
  static const String profile = '$baseUrl/users/profile';
  static const String history = '$baseUrl/users/history';
  static const String weight = '$baseUrl/users/weight';
  static const String weightHistory = '$baseUrl/users/weight/history';

  // Calories
  static const String calculateCalories = '$baseUrl/calories/calculate';

  // Public workouts & exercises
  static const String workouts = '$baseUrl/workouts';
  static const String exerciseCatalogue = '$baseUrl/exercises/exercise-catalogue';

  // Admin
  static const String adminUsers = '$baseUrl/admin/users';
  static const String adminWorkouts = '$baseUrl/admin/workouts';
  static const String adminSupplements = '$baseUrl/admin/supplements';
  static const String adminExercises = '$baseUrl/admin/exercises';
}
