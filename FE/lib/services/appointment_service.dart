import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AppointmentService {
  final _storage = FlutterSecureStorage(
    webOptions: kIsWeb
        ? const WebOptions(dbName: 'quitcare_storage', publicKey: 'quitcare')
        : const WebOptions(),
  );
  final String baseUrl = '${AppConfig.apiBase}/appointments';

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>> bookAppointment(DateTime startTime) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'startTime': startTime.toIso8601String(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi đặt lịch');
    }
  }

  Future<List<dynamic>> getAppointments() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải danh sách lịch hẹn');
    }
  }

  Future<List<String>> getBookedSlots(DateTime date) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Vui lòng đăng nhập lại');
    }

    final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final response = await http.get(
      Uri.parse('$baseUrl/booked-slots?date=$dateString'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<String>.from(data['data']);
    } else {
      throw Exception(data['message'] ?? 'Lỗi khi tải danh sách khung giờ đã đặt');
    }
  }
}
