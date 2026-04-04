import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? "";

  String get cleanBaseUrl => baseUrl.replaceAll(RegExp(r'/$'), '');

  String _mapRole(String role) {
    switch (role.toLowerCase().trim()) {
      case "student": return "student";
      case "parent":  return "parent";
      case "mentor":  return "mentor";
      default:        return "student";
    }
  }

  // ✅ Safely parses ANY FastAPI error format
  // Backend can return detail as: String, List (validation), or Map
  String _extractDetail(String responseBody) {
    try {
      final data = json.decode(responseBody);
      if (data == null) return "Something went wrong";
      final detail = data['detail'];
      if (detail == null) return "Something went wrong";

      // FastAPI Pydantic validation errors → List
      if (detail is List) {
        return detail.map((e) {
          final loc = e['loc'] as List?;
          final field = loc != null && loc.length > 1 ? loc.last.toString() : '';
          final msg = e['msg']?.toString() ?? '';
          return field.isNotEmpty ? "$field: $msg" : msg;
        }).join(", ");
      }

      if (detail is String) return detail;
      return detail.toString();
    } catch (_) {
      return "Something went wrong. Please try again.";
    }
  }

  // ✅ REGISTER — unchanged, still returns String
  Future<String> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final url = "$cleanBaseUrl/api/v1/auth/register";

    final body = {
      "email": email.trim(),
      "password": password.trim(),
      "full_name": fullName.trim(),
      "role": _mapRole(role),
    };

    debugPrint("📤 REGISTER URL: $url");
    debugPrint("📤 REGISTER BODY: $body");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      debugPrint("📥 REGISTER STATUS: ${response.statusCode}");
      debugPrint("📥 REGISTER RESPONSE: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "SUCCESS";
      } else if (response.statusCode == 400) {
        return _extractDetail(response.body);
      } else if (response.statusCode == 422) {
        return _extractDetail(response.body);
      } else if (response.statusCode >= 500) {
        return "Server error. Please try again later.";
      } else {
        return _extractDetail(response.body);
      }
    } on SocketException {
      debugPrint("❌ REGISTER SocketException");
      return "Cannot reach server. Check your internet connection.";
    } on HttpException {
      debugPrint("❌ REGISTER HttpException");
      return "Server error. Please try again.";
    } on FormatException {
      debugPrint("❌ REGISTER FormatException");
      return "Unexpected response from server.";
    } catch (e) {
      debugPrint("❌ REGISTER ERROR [${e.runtimeType}]: $e");
      return "Error: ${e.toString()}";
    }
  }

  // ✅ LOGIN — now returns Map<String, dynamic> instead of String.
  //
  //   ON SUCCESS:  { 'access_token': '...', ...rest of backend response }
  //   ON FAILURE:  { 'error': 'human readable message' }
  //
  //   This lets LoginScreen both show the real error AND store the token.
  //   The map NEVER contains both keys — check 'error' first.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    final url = "$cleanBaseUrl/api/v1/auth/login";
    debugPrint("📤 LOGIN URL: $url");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": email.trim(),
          "password": password.trim(),
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint("📥 LOGIN STATUS: ${response.statusCode}");
      debugPrint("📥 LOGIN RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Guard: backend returned 200 but no token
        if (!data.containsKey('access_token') || data['access_token'] == null) {
          return {"error": "Server returned an invalid response. Please try again."};
        }

        final String token = data['access_token'];

        // ✅ Role validation via JWT
        try {
          final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          debugPrint("🔑 DECODED TOKEN: $decodedToken");

          String roleInToken = decodedToken['role']?.toString() ?? "";
          String cleanRole = roleInToken.contains('.')
              ? roleInToken.split('.').last.toLowerCase()
              : roleInToken.toLowerCase();

          if (cleanRole.isNotEmpty && cleanRole != selectedRole.toLowerCase()) {
            String displayRole = cleanRole[0].toUpperCase() + cleanRole.substring(1);
            return {"error": "Access Denied: This account is registered as a $displayRole."};
          }
        } catch (e) {
          debugPrint("❌ JWT DECODE ERROR: $e");
          return {"error": "Authentication failed: received a malformed token."};
        }

        // ✅ All good — return the full response (includes access_token)
        return data;

      } else if (response.statusCode == 401) {
        return {"error": "Incorrect email or password"};
      } else if (response.statusCode == 422) {
        return {"error": _extractDetail(response.body)};
      } else if (response.statusCode >= 500) {
        return {"error": "Server error. Please try again later."};
      } else {
        final String msg = _extractDetail(response.body).toLowerCase();
        if (msg.contains("not found") || msg.contains("no user")) {
          return {"error": "User not registered"};
        } else if (msg.contains("credential") || msg.contains("password")) {
          return {"error": "Incorrect email or password"};
        }
        return {"error": msg.isNotEmpty ? msg : "Login failed"};
      }

    } on SocketException {
      debugPrint("❌ LOGIN SocketException");
      return {"error": "Cannot reach server. Check your internet connection."};
    } on HttpException {
      debugPrint("❌ LOGIN HttpException");
      return {"error": "Server error. Please try again."};
    } on FormatException {
      debugPrint("❌ LOGIN FormatException");
      return {"error": "Unexpected response from server."};
    } catch (e) {
      debugPrint("❌ LOGIN ERROR [${e.runtimeType}]: $e");
      return {"error": "Error: ${e.toString()}"};
    }
  }
}