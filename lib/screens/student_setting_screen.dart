import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/token_service.dart';
import '../routes/app_routes.dart';      // <-- ADD THIS
class StudentSettingScreen extends StatelessWidget {
  const StudentSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. SECURITY & ACCESS
            _buildSectionLabel("SECURITY & ACCESS"),
            _buildSettingsCard([
              _buildSettingTile(
                Icons.family_restroom_rounded,
                "Family Link",
                "Access Code: 655 420",
                onTap: () {},
                trailing: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
              ),
              _buildDivider(),
              _buildSettingTile(
                  Icons.lock_outline_rounded,
                  "Privacy Policy",
                  "How we protect your data",
                  onTap: () {}
              ),
            ]),

            const SizedBox(height: 30),

            // 2. PREFERENCES
            _buildSectionLabel("PREFERENCES"),
            _buildSettingsCard([
              _buildSettingTile(Icons.notifications_none_rounded, "Notifications", "Alerts and reminders", onTap: () {}),
              _buildDivider(),
              _buildSettingTile(Icons.language_rounded, "Language", "English (US)", onTap: () {}),
              _buildDivider(),
              _buildSettingTile(Icons.dark_mode_outlined, "Appearance", "Light Mode", onTap: () {}),
            ]),

            const SizedBox(height: 30),

            // 3. SUPPORT
            _buildSectionLabel("SUPPORT"),
            _buildSettingsCard([
              _buildSettingTile(Icons.help_outline_rounded, "Help Center", "FAQs and chat support", onTap: () {}),
              _buildDivider(),
              _buildSettingTile(Icons.info_outline_rounded, "About App", "Version 1.0.4", onTap: () {}),
            ]),

            const SizedBox(height: 40),

            // 4. LOGOUT ACTION
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                onTap: () async {
                  await TokenService.clearToken();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.landing, (route) => false);
                  }
                },
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle, {required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.student.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.student, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.withOpacity(0.1));
  }
}