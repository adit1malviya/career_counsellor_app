// ============================================================
// TOKEN CHECK SCREEN — DEBUG/VERIFICATION TOOL
// ------------------------------------------------------------
// HOW TO USE:
//   Temporarily point your app's home to this screen in main.dart:
//
//     home: const TokenCheckScreen(),
//
//   Run the app AFTER logging in. This screen will show whether
//   the token exists in secure storage and display its full value.
//   Remove or revert before releasing to production.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenCheckScreen extends StatefulWidget {
  const TokenCheckScreen({super.key});

  @override
  State<TokenCheckScreen> createState() => _TokenCheckScreenState();
}

class _TokenCheckScreenState extends State<TokenCheckScreen> {
  // ✅ Secure Storage — Updated to use EncryptedSharedPreferences to match login
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // State variables
  bool _isLoading = true;
  String? _token;
  String _status = "Checking...";
  Color _statusColor = Colors.grey;
  Map<String, String> _allKeys = {};

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    setState(() {
      _isLoading = true;
      _status = "Checking secure storage...";
    });

    try {
      // ✅ Read the specific auth token
      final String? token = await _storage.read(key: 'auth_token');

      // ✅ Also dump ALL keys in storage so you can see everything stored
      final Map<String, String> allKeys = await _storage.readAll();

      // ✅ Console log — visible in IDE debug output regardless of UI
      debugPrint("━━━━━━━━━━━━━━ TOKEN CHECK RESULT ━━━━━━━━━━━━━━");
      if (token != null && token.isNotEmpty) {
        debugPrint("✅ TOKEN EXISTS IN SECURE STORAGE");
        debugPrint("🔑 KEY   : auth_token");
        debugPrint("📄 VALUE : $token");
      } else {
        debugPrint("❌ NO TOKEN FOUND — storage key 'auth_token' is empty or missing");
        debugPrint("💡 Have you logged in yet?");
      }
      debugPrint("📦 ALL KEYS IN STORAGE: ${allKeys.keys.toList()}");
      debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

      setState(() {
        _token = token;
        _allKeys = allKeys;
        _isLoading = false;

        if (token != null && token.isNotEmpty) {
          _status = "✅ Token Found in Secure Storage";
          _statusColor = const Color(0xFF00C48C);
        } else {
          _status = "❌ No Token Found";
          _statusColor = Colors.redAccent;
        }
      });
    } catch (e) {
      debugPrint("❌ ERROR READING SECURE STORAGE: $e");
      setState(() {
        _isLoading = false;
        _status = "❌ Error reading storage: $e";
        _statusColor = Colors.red;
      });
    }
  }

  Future<void> _clearToken() async {
    await _storage.delete(key: 'auth_token');
    debugPrint("🗑️ TOKEN DELETED FROM SECURE STORAGE");
    await _checkToken(); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text(
          "🔐 Token Debug Check",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A2138),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkToken,
            tooltip: "Re-check storage",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATUS CARD ──────────────────────────────
            _buildCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _statusColor.withOpacity(0.15),
                    child: Icon(
                      _token != null ? Icons.check_circle : Icons.cancel,
                      color: _statusColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── TOKEN VALUE ──────────────────────────────
            _buildSectionLabel("Token Value (auth_token)"),
            _buildCard(
              child: _token != null
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    _token!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Color(0xFF1A2138),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _token!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Token copied to clipboard"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text("Copy Token"),
                    ),
                  ),
                ],
              )
                  : const Text(
                "No token stored. Log in first, then re-check.",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),

            const SizedBox(height: 16),

            // ── ALL KEYS IN STORAGE ──────────────────────
            _buildSectionLabel("All Keys in Secure Storage (${_allKeys.length})"),
            _buildCard(
              child: _allKeys.isEmpty
                  ? const Text(
                "Storage is completely empty.",
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _allKeys.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.vpn_key, size: 14, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1A2138)),
                              children: [
                                TextSpan(
                                  text: "${entry.key}: ",
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                TextSpan(
                                  text: entry.value.length > 40
                                      ? "${entry.value.substring(0, 40)}..."
                                      : entry.value,
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ── ACTIONS ──────────────────────────────────
            _buildSectionLabel("Actions"),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _checkToken,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Re-Check"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2138),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _token != null ? _clearToken : null,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text("Clear Token"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── INSTRUCTIONS ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📋 How to use this screen",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  SizedBox(height: 8),
                  Text(
                    "1. Login via the login screen first\n"
                        "2. Navigate here (or set as home temporarily)\n"
                        "3. Tap Re-Check if you don't see the token\n"
                        "4. Watch the debug console for detailed logs\n"
                        "5. Remove this screen before production release",
                    style: TextStyle(fontSize: 12, height: 1.7, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Color(0xFF8E99AF),
        ),
      ),
    );
  }
}