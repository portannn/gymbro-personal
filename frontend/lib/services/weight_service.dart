import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/weight_log_model.dart';
import 'api_constants.dart';

class WeightService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const int pageLimit = 10;

  Future<String?> _getToken() async => await _storage.read(key: _tokenKey);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// [PKCTB-317] Mengambil riwayat berat badan dengan pagination.
  Future<WeightHistoryResult> getWeightHistory({int page = 1}) async {
    final token = await _getToken();
    if (token == null) {
      return const WeightHistoryResult(
          data: [], totalData: 0, totalPages: 1, currentPage: 1, hasMore: false);
    }

    try {
      final uri =
          Uri.parse(ApiConstants.weightHistory).replace(queryParameters: {
        'page': '$page',
        'limit': '$pageLimit',
      });

      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> raw = body['data'];
          final p = body['pagination'];
          final currentPage = p['currentPage'] as int;
          final totalPages = p['totalPages'] as int;
          return WeightHistoryResult(
            data: raw.map((j) => WeightLog.fromJson(j)).toList(),
            totalData: p['totalData'] as int,
            totalPages: totalPages,
            currentPage: currentPage,
            hasMore: currentPage < totalPages,
          );
        }
      }
    } catch (_) {}
    return const WeightHistoryResult(
        data: [], totalData: 0, totalPages: 1, currentPage: 1, hasMore: false);
  }
}
