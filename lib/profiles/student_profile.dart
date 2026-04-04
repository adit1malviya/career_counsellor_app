import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StudentProfile extends StatefulWidget {
  const StudentProfile({super.key});

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> {
  // 1. DATA MODEL (In a real app, this comes from a Database/Provider)
  final Map<String, String> _profileData = {
    "Full Name": "Alex",
    "Email": "alex.design@email.com",
    "Phone": "+91 98765 43210",
    "Address": "Indore, MP, India",
    "School": "St. Paul’s Institute",
    "Grade": "12th Standard (PCM)",
    "Volunteer": "", // Empty field
    "Interests": "UI/UX, Graphic Design",
  };

  // 2. CALCULATION LOGIC
  double _calculateCompletion() {
    int totalFields = _profileData.length;
    int filledFields = _profileData.values.where((value) => value.isNotEmpty).length;
    return filledFields / totalFields;
  }

  @override
  Widget build(BuildContext context) {
    double completionPercent = _calculateCompletion();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text("My Profile", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          IconButton(
              onPressed: () {
                // Simulating an edit: Clear the 'Volunteer' field and see the ring change!
                setState(() {
                  _profileData["Volunteer"] = "";
                });
              },
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.student, size: 28)
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // DYNAMIC HEADER
            _buildProfileHeader(completionPercent),

            const SizedBox(height: 30),

            // PERSONAL INFO
            _buildSectionHeader("Personal Information"),
            _buildProfileCard([
              _buildInfoTile(Icons.person_outline, "Full Name", _profileData["Full Name"]!),
              _buildDivider(),
              _buildInfoTile(Icons.email_outlined, "Email Address", _profileData["Email"]!),
              _buildDivider(),
              _buildInfoTile(Icons.location_on_outlined, "Address", _profileData["Address"]!),
            ]),

            const SizedBox(height: 25),

            // ACADEMIC
            _buildSectionHeader("Academic Details"),
            _buildProfileCard([
              _buildInfoTile(Icons.school_outlined, "Current School/College", _profileData["School"]!),
              _buildDivider(),
              _buildInfoTile(Icons.grade_outlined, "Current Grade", _profileData["Grade"]!),
            ]),

            const SizedBox(height: 25),

            // EXPERIENCE (Will show "Not Added" if empty)
            _buildSectionHeader("Experience & Interests"),
            _buildProfileCard([
              _buildInfoTile(
                Icons.volunteer_activism_outlined,
                "Volunteer Experience",
                _profileData["Volunteer"]!.isEmpty ? "Not Added Yet" : _profileData["Volunteer"]!,
                textColor: _profileData["Volunteer"]!.isEmpty ? Colors.orange.shade700 : Colors.black87,
              ),
              _buildDivider(),
              _buildInfoTile(Icons.psychology_outlined, "Top Interests", _profileData["Interests"]!),
            ]),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildProfileHeader(double percent) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120, height: 120,
              child: CircularProgressIndicator(
                value: percent, // DYNAMIC VALUE
                strokeWidth: 8,
                backgroundColor: Colors.grey.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.student),
              ),
            ),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.student,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                    "${(percent * 100).toInt()}%",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        Text(_profileData["Full Name"]!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text("UI/UX Design Aspirant", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ... (Keep the rest of your _buildSectionHeader, _buildProfileCard, _buildInfoTile, and _buildDivider helpers from before)

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildProfileCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? textColor, bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.student.withOpacity(0.05), shape: BoxShape.circle),
            child: Icon(icon, color: textColor ?? AppTheme.student, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor ?? Colors.black87)),
              ],
            ),
          ),
          Icon(isCopyable ? Icons.copy_rounded : Icons.chevron_right_rounded, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 20, color: Colors.grey.withOpacity(0.1));
  }
}