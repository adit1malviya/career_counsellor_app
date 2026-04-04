import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../profiles/mentor_profile.dart';
import '../screens/mentor_schedule_screen.dart'; // Ensure this is imported

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  // 1. TRACK THE ACTIVE TAB
  int _currentIndex = 0;

  // 2. WIDGET SWITCHER LOGIC
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const MentorScheduleScreen(); // Your new high-end Schedule UI
      case 2:
        return const Center(child: Text("Messages & Chats", style: TextStyle(fontWeight: FontWeight.bold)));
      case 3:
        return const MentorProfile();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      // AnimatedSwitcher for smooth transitions between tabs
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- HOME CONTENT (Original Dashboard View) ---
  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('mentorHomeScroll'),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 25),
            const Text("Impact Metrics",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF172B4D))),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildImpactCard("24", "Active Students", Icons.people_alt_rounded, Colors.blue),
                const SizedBox(width: 12),
                _buildImpactCard("140+", "Hrs Mentored", Icons.timer_rounded, Colors.orange),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Today's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                GestureDetector(
                  // UPDATED: Now switches the tab index to 1
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Text("VIEW CALENDAR",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.mentor.withOpacity(0.7))),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Interaction: Tapping the live session also takes you to the schedule
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: _buildScheduleTile("04:30 PM", "Alex", "Career Pathing - Session 3", isLive: true),
            ),
            _buildScheduleTile("06:00 PM", "Priya Sharma", "Resume Review", isLive: false),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("My Students", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Icon(Icons.search, size: 20, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            _buildStudentListTile("Alex", "UI/UX Design", 0.85, 'https://i.pravatar.cc/150?img=11'),
            _buildStudentListTile("Rohan Das", "Cybersecurity", 0.40, 'https://i.pravatar.cc/150?img=12'),
            _buildStudentListTile("Sara Khan", "Data Science", 0.65, 'https://i.pravatar.cc/150?img=45'),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- PERSISTENT BOTTOM NAVIGATION ---
  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, "HOME", 0),
          _buildNavItem(Icons.calendar_month_rounded, "SCHEDULE", 1),
          _buildNavItem(Icons.forum_rounded, "CHATS", 2),
          _buildNavItem(Icons.person_outline, "PROFILE", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: isActive ? AppTheme.mentor : Colors.transparent,
                shape: BoxShape.circle
            ),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 24),
          ),
          Text(label, style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.mentor : Colors.grey.shade400
          )),
        ],
      ),
    );
  }

  // --- HEADER & COMPONENT HELPERS ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 24, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=32')),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Good Morning,", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                Text("Dr. Sarah James", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.1))),
          child: const Icon(Icons.settings_suggest_outlined, size: 22, color: AppTheme.mentor),
        ),
      ],
    );
  }

  Widget _buildImpactCard(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(val, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTile(String time, String student, String topic, {bool isLive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.mentor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isLive ? [BoxShadow(color: AppTheme.mentor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))] : [],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(time, style: TextStyle(color: isLive ? Colors.white70 : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (isLive) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student, style: TextStyle(color: isLive ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(topic, style: TextStyle(color: isLive ? Colors.white70 : Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: isLive ? Colors.white : Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildStudentListTile(String name, String goal, double progress, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundImage: NetworkImage(img)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(goal, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            width: 40, height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.mentor)
                ),
                Center(child: Text("${(progress * 100).toInt()}%",
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}