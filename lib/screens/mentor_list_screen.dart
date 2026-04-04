import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MentorListScreen extends StatelessWidget {
  const MentorListScreen({super.key});

  final List<Map<String, String>> assignedMentors = const [
    {
      "name": "Dr. Sarah James",
      "role": "Software Engineering Expert",
      "image": "https://i.pravatar.cc/150?img=32",
      "rating": "4.9",
      "sessions": "12 Sessions"
    },
    {
      "name": "Prof. Mike Wheeler",
      "role": "Cybersecurity Specialist",
      "image": "https://i.pravatar.cc/150?img=60",
      "rating": "4.8",
      "sessions": "8 Sessions"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Mentors",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ), // Fixed: Removed the extra ], that was here
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        itemCount: assignedMentors.length,
        itemBuilder: (context, index) {
          final mentor = assignedMentors[index];
          return _buildMentorProfessionalCard(context, mentor);
        },
      ),
    );
  }

  Widget _buildMentorProfessionalCard(BuildContext context, Map<String, String> mentor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(mentor['image']!),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FFC2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentor['role']!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            mentor['rating']!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.history_edu_rounded, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            mentor['sessions']!,
                            style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F9FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.calendar_today_outlined,
                    label: "Request Session",
                    color: AppTheme.student,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: "Chat Now",
                    color: Colors.white,
                    textColor: AppTheme.student,
                    isOutlined: true,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined ? Border.all(color: color.withOpacity(0.2)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}