import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthService {
  static String get baseUrl => '${AppConfig.apiBase}/auth';
  static const String tokenKey = 'auth_token';

  final storage = FlutterSecureStorage(
    webOptions: kIsWeb
        ? const WebOptions(dbName: 'quitcare_storage', publicKey: 'quitcare')
        : const WebOptions(),
  );

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String fullname,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullname,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        // Save token to secure storage
        await storage.write(key: tokenKey, value: data['data']['token']);
        return {
          'success': true,
          'message': data['message'],
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        // Save token to secure storage
        await storage.write(key: tokenKey, value: data['data']['token']);
        return {
          'success': true,
          'message': data['message'],
          'user': data['data']['user'],
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Đăng nhập thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await storage.read(key: tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'user': data['data']};
      } else {
        return {'success': false, 'message': 'Không thể tải thông tin tài khoản'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    required String fullname,
    required String phone,
    Map<String, dynamic>? smokingProfile,
  }) async {
    try {
      final token = await storage.read(key: tokenKey);

      if (token == null) {
        return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullname': fullname,
          'phone': phone,
          'smokingProfile': ?smokingProfile,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Cập nhật thông tin thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Upload user avatar
  Future<Map<String, dynamic>> uploadAvatar(XFile imageFile) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) {
        return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};
      }

      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.name;
      final ext = filename.split('.').last.toLowerCase();
      final mimeType = const {
        'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
        'png': 'image/png', 'gif': 'image/gif', 'webp': 'image/webp',
      }[ext] ?? 'image/jpeg';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'avatar', bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        return {'success': true, 'avatar': data['data']['avatar']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Tải ảnh lên thất bại'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Change user password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'Phiên đăng nhập đã hết hạn'};

      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);
      return {'success': data['success'] ?? false, 'message': data['message']};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối, vui lòng kiểm tra mạng'};
    }
  }

  /// Get stored token
  Future<String?> getToken() async {
    return await storage.read(key: tokenKey);
  }

  /// Logout user
  Future<void> logout() async {
    await storage.delete(key: tokenKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
