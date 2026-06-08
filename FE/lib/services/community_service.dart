import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class CommunityService {
  static String get baseUrl => '${AppConfig.apiBase}/community';
  static const String tokenKey = 'auth_token';

  final storage = FlutterSecureStorage(
    webOptions: kIsWeb
        ? const WebOptions(dbName: 'quitcare_storage', publicKey: 'quitcare')
        : const WebOptions(),
  );

  Future<Map<String, dynamic>> getPosts({int page = 1, int limit = 10}) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.get(
        Uri.parse('$baseUrl/posts?page=$page&limit=$limit'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> createPost(String content) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> getComments(String postId) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> addComment(String postId, String content) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteComment(String commentId) async {
    try {
      final token = await storage.read(key: tokenKey);
      if (token == null) return {'success': false, 'message': 'No token found'};
      final response = await http.delete(
        Uri.parse('$baseUrl/comments/$commentId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }
}
