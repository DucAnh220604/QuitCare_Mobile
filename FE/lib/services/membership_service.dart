import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class MembershipService {
  static String get baseUrl => '${AppConfig.apiBase}/membership';
  static const String tokenKey = 'auth_token';

  final storage = const FlutterSecureStorage();

  /// Get available membership packages
  Future<Map<String, dynamic>> getPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/packages'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout after 15 seconds'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'packages': data['data'],
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch packages'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Register for membership
  Future<Map<String, dynamic>> registerMembership(String packageId) async {
    try {
      final token = await storage.read(key: tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'packageId': packageId}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout after 30 seconds'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to register membership',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Get current user membership
  Future<Map<String, dynamic>> getCurrentMembership() async {
    try {
      final token = await storage.read(key: tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/current'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Request timeout after 15 seconds'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'membership': data['data'],
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch membership'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
