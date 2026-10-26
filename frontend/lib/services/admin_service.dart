import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/workout_model.dart';
import 'api_constants.dart';

class AdminService {
  // Menggunakan FlutterSecureStorage yang sama dengan AuthService
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Users ─────────────────────────────────────────────────────────────────

  /// GET /api/admin/users
  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan. Silakan login.'};

      final response = await http.get(
        Uri.parse(ApiConstants.adminUsers),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil data user'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // ── Workouts ──────────────────────────────────────────────────────────────

  /// GET /api/admin/workouts
  Future<Map<String, dynamic>> getWorkouts() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan. Silakan login.'};

      final response = await http.get(
        Uri.parse(ApiConstants.adminWorkouts),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> raw = data['data'] ?? [];
        final workouts = raw
            .whereType<Map<String, dynamic>>()
            .map(Workout.fromJson)
            .toList();
        return {'success': true, 'data': workouts};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal mengambil data workout'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  /// POST /api/admin/workouts
  Future<Map<String, dynamic>> createWorkout(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan. Silakan login.'};

      final response = await http.post(
        Uri.parse(ApiConstants.adminWorkouts),
        headers: _authHeaders(token),
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': Workout.fromJson(data['data'] as Map<String, dynamic>)};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal membuat workout'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  /// PUT /api/admin/workouts/:id
  Future<Map<String, dynamic>> updateWorkout(String id, Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan. Silakan login.'};

      final response = await http.put(
        Uri.parse('${ApiConstants.adminWorkouts}/$id'),
        headers: _authHeaders(token),
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': Workout.fromJson(data['data'] as Map<String, dynamic>)};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal memperbarui workout'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  /// DELETE /api/admin/workouts/:id
  Future<Map<String, dynamic>> deleteWorkout(String id) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan. Silakan login.'};

      final response = await http.delete(
        Uri.parse('${ApiConstants.adminWorkouts}/$id'),
        headers: _authHeaders(token),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'Gagal menghapus workout'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // ─── Supplements ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSupplements() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.get(Uri.parse(ApiConstants.adminSupplements), headers: _authHeaders(token));
      final data = json.decode(response.body);
      if (response.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> createSupplement(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.post(
        Uri.parse(ApiConstants.adminSupplements),
        headers: _authHeaders(token),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSupplement(int id, Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.put(
        Uri.parse('${ApiConstants.adminSupplements}/$id'),
        headers: _authHeaders(token),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSupplement(int id) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.delete(Uri.parse('${ApiConstants.adminSupplements}/$id'), headers: _authHeaders(token));
      if (response.statusCode == 200) return {'success': true};
      return {'success': false, 'message': 'Gagal menghapus suplemen'};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  // ─── Exercises ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getExercises() async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.get(Uri.parse(ApiConstants.adminExercises), headers: _authHeaders(token));
      final data = json.decode(response.body);
      if (response.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> createExercise(Map<String, dynamic> body) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final response = await http.post(
        Uri.parse(ApiConstants.adminExercises),
        headers: _authHeaders(token),
        body: json.encode(body),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 201) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> uploadExerciseMedia(int id, String filePath) async {
    try {
      final token = await _getToken();
      if (token == null) return {'success': false, 'message': 'Token tidak ditemukan'};

      final uri = Uri.parse('${ApiConstants.adminExercises}/$id/media');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('media_file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200) return {'success': true, 'data': data['data']};
      return {'success': false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan upload: $e'};
    }
  }
}
