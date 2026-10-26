import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout_model.dart';
import 'api_constants.dart';

class WorkoutService {
  Future<List<Workout>> getWorkouts({
    String location = 'all',
    String category = 'all',
  }) async {
    try {
      final uri = Uri.parse(ApiConstants.workouts).replace(
        queryParameters: {
          'location': location,
          'category': category,
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final raw = body is List ? body : body['data'];
      if (raw is! List) return [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(Workout.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
