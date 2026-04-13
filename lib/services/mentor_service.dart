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
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

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
      final response = await http
          .post(url,
          headers: await _getHeaders(), body: json.encode(profileData))
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ updateProfile Error: $e");
      return false;
    }
  }

  // ── Availability ──────────────────────────────────────────────────────────

  /// POST /api/v1/availability/
  /// slots: [{ day_of_week: 1-7, start_time: "HH:MM:SS", end_time: "HH:MM:SS" }]
  Future<bool> setAvailability(List<Map<String, dynamic>> slots) async {
    final url = Uri.parse('$baseUrl/api/v1/availability/');
    try {
      final response = await http
          .post(url,
          headers: await _getHeaders(),
          body: json.encode({"slots": slots}))
          .timeout(const Duration(seconds: 15));

      debugPrint(
          "📥 setAvailability ${response.statusCode}: ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ setAvailability Error: $e");
      return false;
    }
  }

  /// GET /api/v1/availability/{mentor_id}
  ///
  /// IMPORTANT: mentor_id here is the Mentor TABLE primary key (Mentor.id),
  /// NOT the user's UUID. Pass "me" to fetch the logged-in mentor's own slots.
  Future<List<dynamic>> getMentorAvailability(String mentorProfileId) async {
    try {
      if (mentorProfileId.isEmpty || mentorProfileId == "null") {
        debugPrint("⚠️ getMentorAvailability: empty/null id — aborting");
        return [];
      }

      String idToQuery = mentorProfileId;

      // Special case: when the mentor views their OWN schedule screen
      if (mentorProfileId == "me") {
        final profile = await getMyProfile();
        idToQuery = profile['id']?.toString() ?? '';
        if (idToQuery.isEmpty) {
          debugPrint("❌ getMentorAvailability: could not resolve 'me' profile id");
          return [];
        }
      }

      final url = Uri.parse('$baseUrl/api/v1/availability/$idToQuery');
      debugPrint("📡 GET $url");

      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("✅ getMentorAvailability: ${data.length} slots");
        return data;
      } else {
        debugPrint(
            "❌ getMentorAvailability ${response.statusCode}: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ getMentorAvailability exception: $e");
      return [];
    }
  }

  // ── Session Requests ──────────────────────────────────────────────────────

  /// GET /api/v1/requests/pending/
  /// Mentor-only. Returns pending SESSION requests (not connection requests).
  Future<List<dynamic>> getPendingSessionRequests() async {
    final url = Uri.parse('$baseUrl/api/v1/requests/pending/');
    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) return json.decode(response.body);
      debugPrint(
          "❌ getPendingSessionRequests ${response.statusCode}: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("❌ getPendingSessionRequests Error: $e");
      return [];
    }
  }

  /// POST /api/v1/requests/create
  /// mentorId must be the Mentor TABLE primary key (Mentor.id), NOT user_id.
  /// availabilityId is the MentorAvailability UUID.
  Future<bool> requestSession({
    required String mentorId,
    required String availabilityId,
    String message = "",
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/requests/create');
    debugPrint(
        "📡 requestSession mentor_id=$mentorId, slot_id=$availabilityId");
    try {
      final response = await http
          .post(url,
          headers: await _getHeaders(),
          body: json.encode({
            "mentor_id":       mentorId,
            "availability_id": availabilityId,
            "message":         message,
          }))
          .timeout(const Duration(seconds: 15));

      debugPrint("📥 requestSession ${response.statusCode}: ${response.body}");
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ requestSession Error: $e");
      return false;
    }
  }

  /// POST /api/v1/requests/{request_id}/approve
  /// Mentor approves a session request → creates SessionLog + Dyte meeting.
  Future<Map<String, dynamic>?> approveSessionRequest(
      String requestId) async {
    final url =
    Uri.parse('$baseUrl/api/v1/requests/$requestId/approve');
    try {
      final response = await http
          .post(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      debugPrint(
          "❌ approveSessionRequest ${response.statusCode}: ${response.body}");
      return null;
    } catch (e) {
      debugPrint("❌ approveSessionRequest Error: $e");
      return null;
    }
  }

  // ── Sessions ──────────────────────────────────────────────────────────────

  /// GET /api/v1/sessions/upcoming
  /// Works for both mentor and student (backend auto-detects role).
  Future<List<dynamic>> getUpcomingSessions() async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/upcoming');
    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      debugPrint("❌ getUpcomingSessions Error: $e");
      return [];
    }
  }

  /// POST /api/v1/sessions/{session_id}/join-video
  /// Returns { token: <dyte_participant_token>, meeting_id }
  Future<Map<String, dynamic>?> joinVideoSession(String sessionId) async {
    final url =
    Uri.parse('$baseUrl/api/v1/sessions/$sessionId/join-video');
    try {
      final response = await http
          .post(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) return json.decode(response.body);
      debugPrint(
          "❌ joinVideoSession ${response.statusCode}: ${response.body}");
      return null;
    } catch (e) {
      debugPrint("❌ joinVideoSession Error: $e");
      return null;
    }
  }

  /// POST /api/v1/sessions/{session_id}/end
  /// Marks the session as completed in the backend after the video call ends.
  Future<bool> endVideoSession(String sessionId) async {
    final url = Uri.parse('$baseUrl/api/v1/sessions/$sessionId/end');
    try {
      // ✅ Correctly using the existing _getHeaders() method
      final response = await http.post(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Session $sessionId successfully ended in backend.");
        return true;
      }
      debugPrint("❌ endVideoSession ${response.statusCode}: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("❌ Error ending session: $e");
      return false;
    }
  }
}