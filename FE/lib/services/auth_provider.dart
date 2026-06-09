import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
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
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
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

  /// Get user profile
  Future<bool> fetchProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.getProfile();

      if (result['success']) {
        _user = result['user'];
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
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String fullname,
    required String phone,
    Map<String, dynamic>? smokingProfile,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.updateProfile(
        fullname: fullname,
        phone: phone,
        smokingProfile: smokingProfile,
      );

      if (result['success']) {
        _user = result['user'];
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
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      if (!result['success']) _errorMessage = result['message'];
      notifyListeners();
      return result['success'] as bool;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Upload user avatar
  Future<bool> uploadAvatar(XFile imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await authService.uploadAvatar(imageFile);

      if (result['success']) {
        _user = {...?_user, 'avatar': result['avatar']};
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
      _errorMessage = 'Đã xảy ra lỗi, vui lòng thử lại';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
