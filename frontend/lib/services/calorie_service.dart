import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_constants.dart';

class CalorieService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Memanggil API untuk menghitung estimasi kalori yang terbakar (PBI-1 Subtask 5)
  Future<double?> calculateCalories({
    required String workoutId,
    required int durationMinutes,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.calculateCalories),
        headers: _headers(token),
        body: jsonEncode({
          'workout_id': workoutId,
          'duration_minutes': durationMinutes,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          // Parse as double to handle decimal values
          return (body['data']['calories_burned'] as num).toDouble();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
