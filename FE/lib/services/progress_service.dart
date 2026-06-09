import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ProgressService {
  static String get baseUrl => '${AppConfig.apiBase}/progress';
  static const String tokenKey = 'auth_token';

  final storage = FlutterSecureStorage(
    webOptions: kIsWeb
        ? const WebOptions(dbName: 'quitcare_storage', publicKey: 'quitcare')
        : const WebOptions(),
  );

  Future<Map<String, dynamic>> checkIn({
    required int cigarettesSmoked,
    String cravingLevel = '',
    String mood = '',
    List<String> symptoms = const [],
    String note = '',
  }) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.post(
        Uri.parse('$baseUrl/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cigarettesSmoked': cigarettesSmoked,
          'cravingLevel': cravingLevel,
          'mood': mood,
          'symptoms': symptoms,
          'note': note,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getProgressStats() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> getHistory() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> forceSimulate() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.post(
        Uri.parse('$baseUrl/force-simulate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> completePlan() async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.post(
        Uri.parse('$baseUrl/complete-plan'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
