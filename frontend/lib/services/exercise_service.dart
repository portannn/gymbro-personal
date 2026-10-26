import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/exercise_model.dart';
import 'api_constants.dart';

class ExerciseService {
  Future<List<Exercise>> getExercises({
    String? workoutId,
    String? location,
    String? workoutType,
  }) async {
    try {
      final queryParameters = <String, String>{};
      if (workoutId != null && workoutId.isNotEmpty) {
        queryParameters['workout_id'] = workoutId;
      }
      if (location != null && location.isNotEmpty) {
        queryParameters['location'] = location;
      }
      if (workoutType != null && workoutType.isNotEmpty) {
        queryParameters['workout_type'] = workoutType;
      }

      final uri = Uri.parse(ApiConstants.exerciseCatalogue).replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body);
      final raw = body is List ? body : body['data'];
      if (raw is! List) return [];

      return raw
          .whereType<Map<String, dynamic>>()
          .map(Exercise.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
