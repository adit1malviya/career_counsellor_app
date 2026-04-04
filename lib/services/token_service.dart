import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TokenService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Retrieves the raw JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Decodes the token and extracts the user ID
  static Future<String?> getUserId() async {
    final token = await getToken();

    if (token != null && !JwtDecoder.isExpired(token)) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // ✅ FIX: The backend puts the UUID in 'user_id'.
      // We must grab this specific field so the database doesn't crash.
      return decodedToken['user_id']?.toString();
    }

    return null; // Token is missing or expired
  }

  /// Clears the token (use for Logout)
  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }
}