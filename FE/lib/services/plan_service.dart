import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class PlanService {
  static String get baseUrl => '${AppConfig.apiBase}/plans';
  static const String tokenKey = 'auth_token';

  final storage = FlutterSecureStorage(
    webOptions: kIsWeb
        ? const WebOptions(dbName: 'quitcare_storage', publicKey: 'quitcare')
        : const WebOptions(),
  );

  Future<Map<String, dynamic>> getRecommendedPlan() async {
    try {
      final token = await storage.read(key: tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/recommend'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true, 
          'recommendedPlan': data['data']['recommendedPlan'],
          'otherOptions': data['data']['otherOptions']
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to fetch recommended plan'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> selectPlan(String planId) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};

      final response = await http.post(
        Uri.parse('$baseUrl/select'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'planId': planId}),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getMyPlan() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};

      final response = await http.get(
        Uri.parse('$baseUrl/my-plan'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static String get quitPlanBase => '${AppConfig.apiBase}/quit-plan';

  Future<Map<String, dynamic>> generateSuggestedPlan() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};

      final response = await http.get(
        Uri.parse('$quitPlanBase/generate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> confirmPlan(Map<String, dynamic> planData) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};

      final response = await http.post(
        Uri.parse('$quitPlanBase/confirm'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(planData),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getCurrentQuitPlan() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};

      final response = await http.get(
        Uri.parse('$quitPlanBase/current'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
