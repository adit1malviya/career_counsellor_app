import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'token_service.dart';

class MentorService {
  String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8000")
          .replaceAll(RegExp(r'/$'), '');

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    final url = Uri.parse('$baseUrl/api/v1/profiles/mentors/me');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception("Profile not found: ${response.statusCode}");
    } on SocketException {
      throw Exception("Server unreachable. Check your network.");
    } catch (e) {
      debugPrint("❌ getMyProfile Error: $e");
      rethrow;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    final url = Uri.parse('$baseUrl/api/v1/profiles/mentors/');
    try {
      final response = await http.post(url, headers: await _getHeaders(), body: json.encode(profileData)).timeout(const Duration(seconds: 15));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Broadcast Sessions (NEW ARCHITECTURE) ────────────────────────────────

  Future<Map<String, dynamic>?> broadcastSession(String topic, int delayMinutes) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/broadcast');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({"topic": topic, "delay_minutes": delayMinutes}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      }
      debugPrint("❌ broadcastSession Error: ${response.body}");
      return null;
    } catch (e) {
      debugPrint("❌ broadcastSession Exception: $e");
      return null;
    }
  }

  // ── Delete Broadcast ──────────────────────────────────────────────────────
  Future<bool> deleteBroadcast(String sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId');
    try {
      final response = await http.delete(url, headers: await _getHeaders()).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ deleteBroadcast Error: $e");
      return false;
    }
  }

  // ── Connection Requests (NEW ARCHITECTURE) ───────────────────────────────

  // Used by STUDENTS to send a request to a Mentor
  Future<bool> sendConnectionRequest(String mentorId, String message) async {
    final url = Uri.parse('$baseUrl/api/v1/connections/request');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          "mentor_id": mentorId,
          "message": message.isEmpty ? "I would like to connect and join your sessions!" : message,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ sendConnectionRequest Error: $e");
      return false;
    }
  }

  // Used by MENTORS to view their pending requests
  Future<List<dynamic>> getPendingConnectionRequests() async {
    final url = Uri.parse('$baseUrl/api/v1/mentors/requests/pending');
    try {
      final response = await http.get(url, headers: await _getHeaders()).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      debugPrint("❌ getPendingConnectionRequests Error: $e");
      return [];
    }
  }

  // Used by MENTORS to accept a student's request
  Future<bool> acceptConnectionRequest(String requestId) async {
    final url = Uri.parse('$baseUrl/api/v1/connections/$requestId/accept');
    try {
      final response = await http.patch(url, headers: await _getHeaders()).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Used by MENTORS to reject a student's request
  Future<bool> rejectConnectionRequest(String requestId) async {
    final url = Uri.parse('$baseUrl/api/v1/connections/$requestId/reject');
    try {
      final response = await http.patch(url, headers: await _getHeaders()).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── Video Sessions ────────────────────────────────────────────────────────

  Future<List<dynamic>> getUpcomingSessions() async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/upcoming');
    debugPrint("📡 Fetching Broadcasts from: $url");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));

      debugPrint("📥 UpcomingSessions Status Code: ${response.statusCode}");
      debugPrint("📥 UpcomingSessions Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("❌ SERVER ERROR: Server refused to send sessions.");
        return [];
      }
    } catch (e) {
      debugPrint("❌ APP CRASH/EXCEPTION in getUpcomingSessions: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> joinVideoSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/join-video');
    try {
      final response = await http.post(url, headers: await _getHeaders()).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> endVideoSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/end');
    try {
      final response = await http.post(url, headers: await _getHeaders()).timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
}