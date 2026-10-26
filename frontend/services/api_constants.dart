class ApiConstants {
  // 10.0.2.2 untuk Android emulator, localhost untuk iOS simulator
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String profile = '$baseUrl/users/profile';
}