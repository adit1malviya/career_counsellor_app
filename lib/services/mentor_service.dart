import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'token_service.dart';

class MentorService {
  // baseUrl remains root: e.g., "http://10.0.2.2:8000"
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8000";

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// ✅ Fetch Profile - Appending /api/v1 manually
  Future<Map<String, dynamic>> getMyProfile() async {
    final url = Uri.parse('$baseUrl/api/v1/profiles/mentors/me');
    try {
      final response = await http.get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Profile not found or error: ${response.statusCode}");
      }
    } on SocketException {
      throw Exception("Server unreachable. Check your network.");
    } catch (e) {
      debugPrint("❌ getMyProfile Error: $e");
      rethrow;
    }
  }

  /// ✅ Update Profile - Appending /api/v1 manually
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    final url = Uri.parse('$baseUrl/api/v1/profiles/mentors/');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(profileData),
      ).timeout(const Duration(seconds: 15));

      debugPrint("📥 API Response: ${response.statusCode} - ${response.body}");
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ updateProfile Error: $e");
      return false;
    }
  }
}