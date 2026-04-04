import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'token_service.dart';

class AssessmentService {
  String get baseUrl => (dotenv.env['API_BASE_URL'] ?? "").replaceAll(RegExp(r'/$'), '');

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
    if (classLower.contains("6") || classLower.contains("7") || classLower.contains("8")) return "6-8";
    if (classLower.contains("9") || classLower.contains("10") || classLower.contains("11")) return "9-11";
    return "9-11";
  }
// --- FETCH USER PROFILE & PROGRESS ---
  Future<Map<String, dynamic>> getUserProfile() async {
    // 1. Build the URL.
    // IMPORTANT: Keep the trailing slash '/' at the end to prevent FastAPI 307 redirects!
    final url = "$baseUrl/api/v1/auth/users/me/";

    try {
      // 2. Fetch the token (assuming you have your TokenService set up)
      final token = await TokenService.getToken();

      // 3. Make the GET request
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 15));

      // 4. Handle the response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // Print the exact backend error to the console to help with debugging
        debugPrint("Backend Error (${response.statusCode}): ${response.body}");
        throw Exception("Failed to load profile: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Network Exception: $e");
      throw Exception("Connection error: $e");
    }
  }

  // --- 2. AI RECOMMENDATIONS ---
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
        throw Exception(error['detail'] ?? "AI Recommendation failed: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("AI Engine Error: $e");
    }
  }

  // --- 3. SELECT CAREER ---
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

  // --- 4. FETCH QUESTIONS ---
  Future<Map<String, dynamic>> fetchQuestions(String uiTitle, {String? grade, String? currentClass}) async {
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

      if (response.statusCode == 200) return json.decode(response.body);
      else throw Exception(json.decode(response.body)['detail'] ?? "Fetch failed");
    } catch (e) {
      throw Exception("Connection error: $e");
    }
  }

  // --- 5. SUBMIT ANSWERS ---
  Future<bool> submitAnswers(String uiTitle, Map<String, dynamic> answers) async {
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
      final response = await http.post(
          Uri.parse(url),
          headers: await _getHeaders(),
          body: json.encode(requestBody)
      ).timeout(const Duration(seconds: 15));

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      return false;
    }
  }
}