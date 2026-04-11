import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';

class MentorProfile extends StatefulWidget {
  const MentorProfile({super.key});

  @override
  State<MentorProfile> createState() => _MentorProfileState();
}

class _MentorProfileState extends State<MentorProfile> {
  final MentorService _apiService = MentorService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _apiService.getMyProfile();
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ UI Load Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog() {
    final expertiseController = TextEditingController(text: _profileData?['expertise'] ?? "");
    final bioController = TextEditingController(text: _profileData?['bio'] ?? "");
    final expController = TextEditingController(text: _profileData?['years_experience']?.toString() ?? "0");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Update Professional Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: expertiseController, decoration: const InputDecoration(labelText: "Role/Expertise")),
            TextField(controller: bioController, decoration: const InputDecoration(labelText: "Biography"), maxLines: 3),
            TextField(controller: expController, decoration: const InputDecoration(labelText: "Years of Experience"), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              onPressed: () async {
                final success = await _apiService.updateProfile({
                  "expertise": expertiseController.text.trim(),
                  "bio": bioController.text.trim(),
                  "years_experience": int.tryParse(expController.text.trim()) ?? 0,
                });

                if (success) {
                  if (mounted) {
                    Navigator.pop(context);
                    _loadProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile updated successfully!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to update profile. Please try again."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.mentor)));

    // 1. Name from Backend
    final name = _profileData?['full_name'] ?? "Mentor Name";

    // 2. Specialty/Role from Backend (The text under the name)
    final backendSpecialty = _profileData?['expertise'] ?? "Professional Mentor";

    // 3. Biography from Backend
    final bio = _profileData?['bio'] ?? "Biography not provided.";

    // 4. Experience from Backend
    final yearsExp = _profileData?['years_experience']?.toString() ?? "0";

    final rating = _profileData?['rating']?.toString() ?? "0.0";

    // ✅ HARDCODED Core Specialties (As requested)
    final List<String> hardcodedSkills = [
      "UI/UX Design",
      "System Architecture",
      "Career Strategy",
      "Public Speaking",
      "Technical Leadership"
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Professional Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit_note_rounded, color: AppTheme.mentor, size: 28)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header uses Name and Backend Specialty
            _buildMentorHeader(name, backendSpecialty),

            const SizedBox(height: 30),
            _buildImpactBar(rating, yearsExp),

            const SizedBox(height: 32),
            _buildSectionHeader("Biography"),
            _buildProfileCard([
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(bio, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
              ),
            ]),

            const SizedBox(height: 25),
            _buildSectionHeader("Core Specialties"),

            // ✅ This section is now purely hardcoded as requested
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: hardcodedSkills.map<Widget>((skill) => _buildTechChip(skill)).toList(),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader("Account Settings"),
            _buildProfileCard([
              _buildInfoTile(Icons.verified_user_outlined, "Verification Status",
                  _profileData?['is_verified'] == true ? "Verified Expert" : "Pending",
                  textColor: AppTheme.mentor),
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

  // --- UI Helpers ---

  Widget _buildMentorHeader(String name, String role) {
    return Column(children: [
      const CircleAvatar(
        radius: 60,
        backgroundColor: Color(0xFFE0E0E0),
        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32'),
      ),
      const SizedBox(height: 16),
      Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -1)),
      const SizedBox(height: 4),
      Text(role, style: const TextStyle(color: AppTheme.mentor, fontWeight: FontWeight.bold, fontSize: 14)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => const Icon(Icons.star_rounded, color: Colors.orange, size: 18))),
    ]);
  }

  Widget _buildImpactBar(String rating, String exp) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _buildStatColumn("120", "Students"),
        _buildVerticalDivider(),
        _buildStatColumn(rating, "Rating"),
        _buildVerticalDivider(),
        _buildStatColumn("${exp}yrs", "Exp."),
      ]),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
    ]);
  }

  Widget _buildVerticalDivider() => Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.mentor.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppTheme.mentor.withOpacity(0.1))),
      child: Text(label, style: const TextStyle(color: AppTheme.mentor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2))),
    );
  }

  Widget _buildProfileCard(List<Widget> children) => Container(width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)), child: Column(children: children));

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.mentor, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
      subtitle: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor ?? Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDivider() => Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.withOpacity(0.1));
}