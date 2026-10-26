import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/history_model.dart';
import 'api_constants.dart';

/// Hasil dari [HistoryService.getHistory] — berisi data dan info pagination
class HistoryResult {
  final List<WorkoutHistory> data;
  final int total;
  final bool hasMore;

  const HistoryResult({
    required this.data,
    required this.total,
    required this.hasMore,
  });
}

class HistoryService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static const int pageLimit = 10; // harus sama dengan PAGE_LIMIT di backend

  Future<String?> _getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// [PKCTB-247] Integrasi Frontend API: Mengambil riwayat latihan.
  /// Menangani pemanggilan API dinamis berdasarkan user login (menggunakan token JWT),
  /// lengkap dengan manajemen state untuk loading, error handling, dan pagination.
  /// [page] adalah halaman yang diinginkan (dimulai dari 1).
  Future<HistoryResult> getHistory({int page = 1}) async {
    final token = await _getToken();
    if (token == null) {
      return const HistoryResult(data: [], total: 0, hasMore: false);
    }

    try {
      final uri = Uri.parse(ApiConstants.history).replace(queryParameters: {
        'limit': '$pageLimit',
        'page': '$page',
      });

      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> raw = body['data'];
          final pagination = body['pagination'];
          return HistoryResult(
            data: raw.map((j) => WorkoutHistory.fromJson(j)).toList(),
            total: pagination['totalData'] ?? 0,
            hasMore: pagination['hasMore'] ?? false,
          );
        }
      }
      return const HistoryResult(data: [], total: 0, hasMore: false);
    } catch (e) {
      return const HistoryResult(data: [], total: 0, hasMore: false);
    }
  }

  Future<bool> addHistory({
    required String workoutName,
    required int durationMinutes,
    required int caloriesBurned,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.history),
        headers: _headers(token),
        body: jsonEncode({
          'workout_name': workoutName,
          'duration_minutes': durationMinutes,
          'calories_burned': caloriesBurned,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}
