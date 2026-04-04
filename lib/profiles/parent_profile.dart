import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ParentProfile extends StatefulWidget {
  const ParentProfile({super.key});

  @override
  State<ParentProfile> createState() => _ParentProfileState();
}

class _ParentProfileState extends State<ParentProfile> {
  // Mock data for the parent
  final Map<String, String> _parentData = {
    "Full Name": "Rajesh",
    "Email": "rajesh.m@email.com",
    "Phone": "+91 98260 12345",
    "Linked Ward": "Alex",
    "Relationship": "Father",
    "Member Since": "March 2026",
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Guardian Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined, color: AppTheme.parent, size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. PROFILE HEADER
            _buildProfileHeader(),

            const SizedBox(height: 35),

            // 2. PERSONAL DETAILS
            _buildSectionHeader("Account Details"),
            _buildInfoCard([
              _buildInfoTile(Icons.person_outline, "Name", _parentData["Full Name"]!),
              _buildDivider(),
              _buildInfoTile(Icons.email_outlined, "Email", _parentData["Email"]!),
              _buildDivider(),
              _buildInfoTile(Icons.phone_outlined, "Phone", _parentData["Phone"]!),
            ]),

            const SizedBox(height: 25),

            // 3. FAMILY LINK SECTION
            _buildSectionHeader("Family Link"),
            _buildInfoCard([
              _buildInfoTile(
                Icons.child_care_rounded,
                "Linked Ward",
                _parentData["Linked Ward"]!,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.parent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text("ACTIVE", style: TextStyle(color: AppTheme.parent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              _buildDivider(),
              _buildInfoTile(Icons.family_restroom_rounded, "Relationship", _parentData["Relationship"]!),
            ]),

            const SizedBox(height: 25),

            // 4. SUBSCRIPTION / PLAN
            _buildSectionHeader("Plan & Billing"),
            _buildInfoCard([
              _buildInfoTile(Icons.stars_rounded, "Current Plan", "Premium Guardian", textColor: AppTheme.parent),
              _buildDivider(),
              _buildInfoTile(Icons.calendar_today_rounded, "Joined On", _parentData["Member Since"]!),
            ]),

            const SizedBox(height: 40),

            // LOGOUT
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              label: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.parent.withOpacity(0.2), width: 2),
          ),
          child: const CircleAvatar(
            radius: 55,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Father figure avatar
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _parentData["Full Name"]!,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          "Primary Guardian",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueGrey, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? textColor, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.parent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.parent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor ?? Colors.black87),
                ),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.withOpacity(0.08));
  }
}