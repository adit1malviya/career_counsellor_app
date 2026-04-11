import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'token_service.dart';

class AssessmentService {
  String get baseUrl =>
      (dotenv.env['API_BASE_URL'] ?? "").replaceAll(RegExp(r'/$'), '');

  static const Map<String, String> moduleMapping = {
    "Basic Assessment": "profile",
    "Personality": "personality",
    "Passion": "passion",
    "Lifestyle": "lifestyle",
    "Family Link": "financial",
    "Interests": "interests",
    "Dreams": "aspiration",
    "Aptitude": "aptitude",
    "Academic": "academic",
  };

  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static String mapClassToGradeBand(String? currentClass) {
    if (currentClass == null || currentClass.isEmpty) return "6-8";
    final classLower = currentClass.toLowerCase().trim();
    if (classLower.contains("6") || classLower.contains("7") ||
        classLower.contains("8")) return "6-8";
    if (classLower.contains("9") || classLower.contains("10") ||
        classLower.contains("11")) return "9-11";
    return "9-11";
  }

  // --- FETCH USER PROFILE & PROGRESS ---
  Future<Map<String, dynamic>> getUserProfile() async {
    final url = "$baseUrl/api/v1/auth/users/me/";
    try {
      final token = await TokenService.getToken();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("Backend Error (${response.statusCode}): ${response.body}");
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Network Exception: $e");
      throw Exception("Connection error: $e");
    }
  }

  // --- GET AUTH TOKEN (used by ChatScreen for WebSocket handshake) ---
  Future<String> getAuthToken() async {
    final token = await TokenService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception("No auth token found. Please log in again.");
    }
    return token;
  }

  // --- GET CHAT MESSAGES (24h history for a given other user) ---
  Future<List<dynamic>> getChatMessages(String otherUserId) async {
    final url = Uri.parse("$baseUrl/api/v1/chat/messages/$otherUserId");
    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      debugPrint("getChatMessages error ${response.statusCode}: ${response.body}");
      return [];
    } catch (e) {
      debugPrint("❌ getChatMessages exception: $e");
      return [];
    }
  }

  // --- AI RECOMMENDATIONS ---
  Future<Map<String, dynamic>> getAIRecommendations() async {
    final url = "$baseUrl/api/v1/ai/recommend";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['detail'] ??
            "AI Recommendation failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("AI Engine Error: $e");
    }
  }

  // --- SELECT CAREER ---
  Future<bool> selectCareer(String careerTitle) async {
    final url = "$baseUrl/api/v1/ai/select-career";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode({"career_title": careerTitle}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ SELECTION ERROR: $e");
      return false;
    }
  }

  // --- FETCH QUESTIONS ---
  Future<Map<String, dynamic>> fetchQuestions(String uiTitle,
      {String? grade, String? currentClass}) async {
    final moduleName = moduleMapping[uiTitle] ?? uiTitle.toLowerCase();
    String url = "$baseUrl/api/v1/assessments/questions/$moduleName";

    if (moduleName == "aptitude") {
      final targetGrade = grade ?? mapClassToGradeBand(currentClass);
      url += "?target_grade=$targetGrade";
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            json.decode(response.body)['detail'] ?? "Fetch failed");
      }
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // --- SUBMIT ANSWERS ---
  Future<bool> submitAnswers(
      String uiTitle, Map<String, dynamic> answers) async {
    final moduleKey = moduleMapping[uiTitle] ?? uiTitle.toLowerCase();
    final url = "$baseUrl/api/v1/assessments/submit-generic";

    final userId = await TokenService.getUserId();
    if (userId == null) {
      debugPrint("❌ User ID is null. Token might be expired.");
      return false;
    }

    final Map<String, dynamic> requestBody = {
      "user_id": userId,
      "module_key": moduleKey,
      "payload": answers,
    };

    try {
      final response = await http
          .post(Uri.parse(url),
          headers: await _getHeaders(),
          body: json.encode(requestBody))
          .timeout(const Duration(seconds: 15));

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }

  // --- GENERATE AND SAVE ROADMAP ---
  Future<Map<String, dynamic>> generateAndSaveRoadmap(
      String careerTitle) async {
    final headers = await _getHeaders();
    try {
      final genUrl = Uri.parse(
          '$baseUrl/api/v1/roadmaps/generate?career=${Uri.encodeComponent(careerTitle)}');
      final genRes = await http
          .get(genUrl, headers: headers)
          .timeout(const Duration(seconds: 60));

      if (genRes.statusCode != 200) {
        throw Exception("Failed to generate roadmap: ${genRes.body}");
      }
      final roadmapData = json.decode(genRes.body);

      final saveUrl = Uri.parse('$baseUrl/api/v1/roadmaps/save');
      final saveRes = await http
          .post(saveUrl, headers: headers, body: json.encode(roadmapData))
          .timeout(const Duration(seconds: 15));

      if (saveRes.statusCode != 201) {
        throw Exception("Failed to save roadmap: ${saveRes.body}");
      }

      final startUrl = Uri.parse('$baseUrl/api/v1/roadmaps/start');
      await http
          .post(startUrl, headers: headers)
          .timeout(const Duration(seconds: 10));

      return roadmapData;
    } catch (e) {
      debugPrint("❌ Roadmap Error: $e");
      rethrow;
    }
  }

  // --- GET CURRENT ROADMAP ---
  Future<Map<String, dynamic>?> getCurrentRoadmap() async {
    final url = "$baseUrl/api/v1/roadmaps/current";
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      if (response.statusCode == 404) return null;
      throw Exception("Failed to load roadmap");
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // --- TOGGLE TASK COMPLETION ---
  Future<Map<String, dynamic>> toggleTaskCompletion(String taskId) async {
    final url = "$baseUrl/api/v1/roadmaps/tasks/$taskId/complete";
    try {
      final response = await http
          .patch(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception("Failed to update task");
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // --- PARENT/STUDENT LINKING ---
  Future<String?> getStudentInviteCode() async {
    final url = "$baseUrl/api/v1/students/invite-code";
    try {
      final response =
      await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return json.decode(response.body)['invite_code'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> linkStudentToParent(String code) async {
    final url = "$baseUrl/api/v1/parents/link-student";
    try {
      final response = await http.post(Uri.parse(url),
          headers: await _getHeaders(),
          body: json.encode({"invite_code": code}));
      return {
        "success": response.statusCode == 201 || response.statusCode == 200,
        "message": json.decode(response.body)['detail'] ??
            json.decode(response.body)['message'],
      };
    } catch (e) {
      return {"success": false, "message": "Connection error: $e"};
    }
  }

  Future<Map<String, dynamic>> getLinkedStudentStatus() async {
    final url = "$baseUrl/api/v1/parents/linked-student";
    try {
      final response = await http
          .get(Uri.parse(url), headers: await _getHeaders())
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200
          ? json.decode(response.body)
          : {"is_linked": false, "student": null};
    } catch (e) {
      return {"is_linked": false, "error": e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfileById(String userId) async {
    final url = "$baseUrl/api/v1/auth/users/me?user_id=$userId";
    final token = await TokenService.getToken();
    final response = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token"
    });
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception("Failed to load profile");
  }

  Future<Map<String, dynamic>?> getWardRoadmap(String studentId) async {
    final url = "$baseUrl/api/v1/parent/roadmaps/$studentId";
    final token = await TokenService.getToken();
    try {
      final response = await http.get(Uri.parse(url), headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token"
      });
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- MENTORSHIP ---

  Future<List<dynamic>> searchMentors(
      {String careerGoal = "technology"}) async {
    final url = Uri.parse(
        '$baseUrl/api/v1/mentorship/search/?career_goal=${Uri.encodeComponent(careerGoal)}');
    final response = await http.get(url, headers: await _getHeaders());
    return response.statusCode == 200
        ? json.decode(response.body)
        : throw Exception('Failed to fetch mentors');
  }

  Future<List<dynamic>> getAcceptedConnections() async {
    final url = Uri.parse("$baseUrl/api/v1/chat/connections");
    try {
      final response = await http
          .get(url, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("❌ Error fetching accepted mentors: $e");
      return [];
    }
  }

  Future<List<dynamic>> getSentRequests() async {
    final url = Uri.parse('$baseUrl/api/v1/mentorship/requests/pending');
    try {
      final response =
      await http.get(url, headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(response.body) : [];
    } catch (e) {
      debugPrint("❌ Error fetching sent requests: $e");
      return [];
    }
  }

  Future<bool> requestMentorship(String mentorId) async {
    final url = Uri.parse('$baseUrl/api/v1/connections/request');
    try {
      final response = await http
          .post(
        url,
        headers: await _getHeaders(),
        body: json.encode({
          "mentor_id": mentorId,
          "message": "I would like to request mentorship from you."
        }),
      )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Mentorship Request Error: $e");
      return false;
    }
  }
}