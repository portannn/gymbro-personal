import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _user?.role == 'admin';

  Future<void> checkAuthStatus() async {
    _setLoading(true);
    final result = await _authService.getProfile();
    debugPrint('AuthProvider - Profile result: $result');
    
    if (result['success'] == true) {
      _user = result['user'];
      debugPrint('AuthProvider - User set: ${_user?.fullName}, onboardingCompleted: ${_user?.onboardingCompleted}');
      _status = AuthStatus.authenticated;
    } else {
      debugPrint('AuthProvider - Auth failed: ${result['message']}');
      _status = AuthStatus.unauthenticated;
    }
    _setLoading(false);
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();
    final result = await _authService.register(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
    _setLoading(false);
    if (result['success'] == true) {
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    debugPrint('AuthProvider - Attempting login for: $email');
    
    final result = await _authService.login(email: email, password: password);
    debugPrint('AuthProvider - Login result: $result');
    
    _setLoading(false);
    if (result['success'] == true) {
      // After successful login, fetch the complete profile to get onboarding status
      debugPrint('AuthProvider - Fetching updated profile after login...');
      final profileResult = await _authService.getProfile();
      
      if (profileResult['success'] == true) {
        _user = profileResult['user'];
        debugPrint('AuthProvider - Profile updated, user: ${_user?.fullName}, onboardingCompleted: ${_user?.onboardingCompleted}');
      } else {
        // Fallback to login user data if profile fetch fails
        _user = result['user'];
        debugPrint('AuthProvider - Using login user data as fallback: ${_user?.fullName}, onboardingCompleted: ${_user?.onboardingCompleted}');
      }
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      debugPrint('AuthProvider - Login failed: ${result['message']}');
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  Future<bool> completeOnboarding(Map<String, dynamic> onboardingData) async {
    _setLoading(true);
    _clearError();
    
    debugPrint('AuthProvider - Completing onboarding with data: $onboardingData');
    
    final result = await _authService.updateProfile(onboardingData);
    
    debugPrint('AuthProvider - Update profile result: $result');
    
    _setLoading(false);
    if (result['success'] == true) {
      // Update user with new data
      _user = _user?.copyWith(
        gender: onboardingData['gender'],
        goals: onboardingData['goals'],
        weight: onboardingData['currentWeight'],
        targetWeight: onboardingData['targetWeight'],
        onboardingCompleted: true,
      );
      debugPrint('AuthProvider - User updated successfully');
      notifyListeners();
      return true;
    } else {
      debugPrint('AuthProvider - Update profile failed: ${result['message']}');
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}