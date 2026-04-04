import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MentorProfile extends StatelessWidget {
  const MentorProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Professional Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined, color: AppTheme.mentor, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. MENTOR IDENTITY HEADER
            _buildMentorHeader(),

            const SizedBox(height: 30),

            // 2. PERFORMANCE STATS (Quick Impact numbers)
            _buildImpactBar(),

            const SizedBox(height: 32),

            // 3. ABOUT / BIO
            _buildSectionHeader("Biography"),
            _buildProfileCard([
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Senior Software Architect with 10+ years of experience in Silicon Valley. Passionate about guiding students toward fulfilling careers in UI/UX and Backend Systems.",
                  style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                ),
              ),
            ]),

            const SizedBox(height: 25),

            // 4. EXPERTISE TAGS
            _buildSectionHeader("Core Specialties"),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTechChip("UI/UX Design"),
                _buildTechChip("System Architecture"),
                _buildTechChip("Career Strategy"),
                _buildTechChip("Public Speaking"),
              ],
            ),

            const SizedBox(height: 32),

            // 5. ACCOUNT & SETTINGS
            _buildSectionHeader("Account Settings"),
            _buildProfileCard([
              _buildInfoTile(Icons.verified_user_outlined, "Verification Status", "Verified Expert", textColor: AppTheme.mentor),
              _buildDivider(),
              _buildInfoTile(Icons.payment_rounded, "Payout Settings", "Bank Account Linked"),
              _buildDivider(),
              _buildInfoTile(Icons.logout_rounded, "Logout", "Sign out", textColor: Colors.redAccent),
            ]),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildMentorHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'),
        ),
        const SizedBox(height: 16),
        const Text(
          "Dr. Sarah James",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1),
        ),
        const SizedBox(height: 4),
        const Text(
          "Senior Career Strategist",
          style: TextStyle(color: AppTheme.mentor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.orange, size: 18)),
        ),
      ],
    );
  }

  Widget _buildImpactBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn("120", "Students"),
          _buildVerticalDivider(),
          _buildStatColumn("4.9", "Rating"),
          _buildVerticalDivider(),
          _buildStatColumn("8yrs", "Exp."),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.mentor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.mentor.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.mentor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.mentor, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor ?? Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.withOpacity(0.1));
  }
}