import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_constants.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Map<String, String> _headers({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: _headers(),
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Registrasi gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final token = body['data']['token'];
        final user = UserModel.fromJson(body['data']['user']);
        await saveToken(token);
        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'code': 'TOKEN_EXPIRED'};
      }
      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: _headers(token: token),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body['data']);
        return {'success': true, 'user': user};
      } else if (response.statusCode == 401) {
        await deleteToken();
        return {'success': false, 'code': 'TOKEN_EXPIRED'};
      } else {
        return {'success': false, 'message': body['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateWeight(double weight, DateTime date) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi telah habis. Silakan login kembali.'};
      }
      final response = await http.post(
        Uri.parse(ApiConstants.weight),
        headers: _headers(token: token),
        body: jsonEncode({
          'weight': weight,
          'recorded_date': date.toIso8601String(),
        }),
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': body['message']};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Gagal memperbarui berat badan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      debugPrint('AuthService - Updating profile with data: $profileData');
      
      final token = await getToken();
      if (token == null) {
        debugPrint('AuthService - No token found');
        return {'success': false, 'message': 'Sesi telah habis. Silakan login kembali.'};
      }
      
      debugPrint('AuthService - Making PUT request to ${ApiConstants.profile}');
      
      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: _headers(token: token),
        body: jsonEncode(profileData),
      );
      
      debugPrint('AuthService - Response status: ${response.statusCode}');
      debugPrint('AuthService - Response body: ${response.body}');
      
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body['data']);
        debugPrint('AuthService - Profile updated successfully');
        return {'success': true, 'user': user, 'message': body['message']};
      } else {
        debugPrint('AuthService - Profile update failed: ${body['message']}');
        return {'success': false, 'message': body['message'] ?? 'Gagal memperbarui profil'};
      }
    } catch (e) {
      debugPrint('AuthService - Exception during profile update: $e');
      return {'success': false, 'message': 'Tidak dapat terhubung ke server'};
    }
  }

  Future<void> logout() async {
    await deleteToken();
  }
}