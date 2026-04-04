import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../profiles/student_profile.dart';
import '../screens/student_setting_screen.dart';
import '../screens/mentor_list_screen.dart';
import '../screens/student_test_screen.dart'; // Import the new screen

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const StudentTestScreen(); // Now shows the Road to Discovery
      case 2:
        return const MentorListScreen();
      case 3:
        return const StudentProfile();
      default:
        return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('homeScroll'),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const SizedBox(height: 24),
            GestureDetector(
              // UPDATED: Now switches tab index to 1 instead of pushing a new page
              onTap: () => setState(() => _currentIndex = 1),
              child: _buildJourneyCard(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem("3", "MENTORS", Icons.people_outline_rounded),
                _buildStatItem("5", "VC SESSIONS", Icons.videocam_outlined),
                _buildStatItem("18", "CHATS", Icons.chat_bubble_outline_rounded),
              ],
            ),
            const SizedBox(height: 32),
            const Text("Your Superpowers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            _buildStrengthPreview(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recommended Mentors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: Text("SEE ALL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.student.withOpacity(0.6))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 195,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  _buildMentorCard("Dr. Sarah James", "Software Engineering", 'https://i.pravatar.cc/150?img=32'),
                  const SizedBox(width: 16),
                  _buildMentorCard("John Smith", "Cybersecurity Expert", 'https://i.pravatar.cc/150?img=60'),
                  const SizedBox(width: 16),
                  _buildMentorCard("Maria Garcia", "UI/UX Designer", 'https://i.pravatar.cc/150?img=45'),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

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
          _buildNavItem(Icons.home_rounded, "HOME", 0),
          _buildNavItem(Icons.quiz_outlined, "TESTS", 1),
          _buildNavItem(Icons.people_outline, "MENTORS", 2),
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
                decoration: BoxDecoration(color: isActive ? AppTheme.student : Colors.transparent, shape: BoxShape.circle),
                child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 24)
            ),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? AppTheme.student : Colors.grey.shade400))
          ]
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(radius: 22, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,", style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                Text("Alex", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.student)),
              ],
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: _buildCircleIcon(Icons.notifications_none_rounded),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentSettingScreen())),
              child: _buildCircleIcon(Icons.settings_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Icon(icon, size: 24, color: Colors.black87),
    );
  }

  Widget _buildJourneyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0056D2), Color(0xFF003D96)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: const Color(0xFF0056D2).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CAREER DISCOVERY", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Explore Your Career\nPathways", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
          const SizedBox(height: 20),
          Row(children: List.generate(5, (index) => Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
              decoration: BoxDecoration(color: index < 1 ? const Color(0xFF00FFC2) : Colors.white24, borderRadius: BorderRadius.circular(10)),
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.student.withOpacity(0.05), shape: BoxShape.circle), child: Icon(icon, color: AppTheme.student, size: 20)),
          const SizedBox(height: 12),
          Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.blueGrey.shade300, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildStrengthPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        children: [
          _buildStrengthBar("Logical Reasoning", 0.9, Colors.blue),
          const SizedBox(height: 14),
          _buildStrengthBar("Creative Thinking", 0.7, Colors.purple),
          const SizedBox(height: 14),
          _buildStrengthBar("Verbal Ability", 0.5, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStrengthBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          Text("${(progress * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color))),
      ],
    );
  }

  Widget _buildMentorCard(String name, String role, String img) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(img)),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.center, maxLines: 1),
          Text(role, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
          const Spacer(),
          ElevatedButton(
              onPressed: () => setState(() => _currentIndex = 2),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5F7FA), foregroundColor: Colors.black, elevation: 0, minimumSize: const Size(double.infinity, 38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("View Profile", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
}