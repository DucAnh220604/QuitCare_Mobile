import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final authService = AuthService();

  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;
  Map<String, dynamic>? _user;
  bool _isLoggedIn = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  /// Register user
  Future<bool> register({
    required String fullname,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.register(
        fullname: fullname,
        email: email,
        password: password,
        phone: phone,
      );

      if (result['success']) {
        _user = result['user'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.login(email: email, password: password);

      if (result['success']) {
        _user = result['user'];
        _isLoggedIn = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    await authService.logout();
    _user = null;
    _isLoggedIn = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Check if user is logged in
  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    final isLoggedIn = await authService.isLoggedIn();
    _isLoggedIn = isLoggedIn;

    if (isLoggedIn) {
      final result = await authService.getProfile();
      if (result['success']) {
        _user = result['user'];
      }
    }

    _isCheckingAuth = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
