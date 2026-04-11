import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'token_service.dart';

class ChatService {
  // Use http://10.0.2.2:8000 for Android Emulator
  final String baseUrl = "http://10.0.2.2:8000";

  // Helper to get consistent headers with Auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await TokenService.getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ✅ Required for WebSocket handshake
  Future<String?> getAuthToken() async {
    return await TokenService.getToken();
  }

  // ✅ Fetch last 24-hour message history for a specific student [cite: 49]
  Future<List<dynamic>> getChatMessages(String otherUserId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/v1/chat/messages/$otherUserId"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("❌ ChatService History Error: $e");
      return [];
    }
  }

  // ✅ Fetch active student connections (accepted/approved) [cite: 41]
  Future<List<dynamic>> getChatConnections() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/v1/chat/connections"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body); // Returns list of {user_id, full_name, role, request_type}
      }
      return [];
    } catch (e) {
      debugPrint("❌ ChatService Connections Error: $e");
      return [];
    }
  }

  // ✅ Fetch pending mentorship requests for the mentor dashboard [cite: 94, 111]
  Future<List<dynamic>> getPendingRequests() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/api/v1/mentors/requests/pending"),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("❌ ChatService Pending Requests Error: $e");
      return [];
    }
  }

  // ✅ Accept a connection request [cite: 117]
  Future<bool> acceptRequest(String requestId) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/api/v1/connections/$requestId/accept"),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("❌ Accept Error: $e");
      return false;
    }
  }

  // ✅ Reject a connection request [cite: 120]
  Future<bool> rejectRequest(String requestId) async {
    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/api/v1/connections/$requestId/reject"),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("❌ Reject Error: $e");
      return false;
    }
  }
}