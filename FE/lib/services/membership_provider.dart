import 'package:flutter/material.dart';
import '../services/membership_service.dart';

class MembershipProvider extends ChangeNotifier {
  final membershipService = MembershipService();

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _packages = [];
  Map<String, dynamic>? _currentMembership;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get packages => _packages;
  Map<String, dynamic>? get currentMembership => _currentMembership;

  /// Fetch available packages
  Future<bool> fetchPackages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await membershipService.getPackages();

      if (result['success']) {
        _packages = result['packages'] ?? [];
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

  /// Register for membership
  Future<bool> registerMembership(String packageId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await membershipService.registerMembership(packageId);

      if (result['success']) {
        _currentMembership = result['data']?['user']?['membership'];
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

  /// Get current membership
  Future<bool> fetchCurrentMembership() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await membershipService.getCurrentMembership();

      if (result['success']) {
        _currentMembership = result['membership'];
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

  /// Get package details by ID
  Map<String, dynamic>? getPackageById(String packageId) {
    try {
      return _packages.firstWhere(
        (pkg) => pkg['id'] == packageId,
      );
    } catch (e) {
      return null;
    }
  }
}
