import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../profiles/parent_profile.dart';
import '../screens/parent_report_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;

  // 1. SHARED DATA SOURCE
  final List<Map<String, dynamic>> allReports = [
    {
      "title": "Career Pathing",
      "subtitle": "Backend Systems Focus",
      "date": "2026-03-28",
      "displayDate": "28 Mar",
      "mentor": "Dr. Sarah James",
      "avatar": "https://i.pravatar.cc/150?img=32",
      "category": "Technical",
      "duration": "45 min"
    },
    {
      "title": "Aptitude Review",
      "subtitle": "Logical Reasoning",
      "date": "2026-03-22",
      "displayDate": "22 Mar",
      "mentor": "Prof. Mike Wheeler",
      "avatar": "https://i.pravatar.cc/150?img=12",
      "category": "Aptitude",
      "duration": "60 min"
    },
  ];

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildHomeContent();
      case 1: return const ParentReportScreen();
      case 2: return const Center(child: Text("Chat with Mentors"));
      case 3: return const ParentProfile();
      default: return _buildHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F9),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    // 2. LOGIC: PICK ONLY THE SINGLE LATEST REPORT
    final latestReport = allReports.first;

    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('parentHomeScroll'),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildTopBar(),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 32),
            const Text("Alex's Top Strengths",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            _buildStrengthRadar(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Latest Session Report", // Updated label
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: Text("VIEW ALL",
                      style: TextStyle(fontSize: 12, color: AppTheme.parentTheme.withOpacity(0.6), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SHOWING ONLY THE ONE LATEST CARD
            _buildPremiumReportCard(latestReport),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE PREMIUM CARD UI ---
  Widget _buildPremiumReportCard(Map<String, dynamic> report) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: AppTheme.parentTheme.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 12)),
        ],
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.parentTheme.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        report['category'].toUpperCase(),
                        style: const TextStyle(color: AppTheme.parentTheme, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(report['displayDate'],
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(report['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(report['subtitle'], style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(report['avatar'])),
                    const SizedBox(width: 12),
                    Expanded(child: Text(report['mentor'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _currentIndex = 1),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EFFF),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                border: Border(top: BorderSide(color: AppTheme.parentTheme.withOpacity(0.1), width: 1.5)),
              ),
              child: const Center(
                child: Text("VIEW FULL EVALUATION",
                    style: TextStyle(color: AppTheme.parentTheme, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              ),
            ),
          ),
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.analytics_rounded, "OVERVIEW", 0),
          _buildNavItem(Icons.history_edu_rounded, "REPORTS", 1),
          _buildNavItem(Icons.chat_bubble_outline_rounded, "CHATS", 2),
          _buildNavItem(Icons.person_outline, "ME", 3),
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
            decoration: BoxDecoration(color: isActive ? AppTheme.parentTheme : Colors.transparent, shape: BoxShape.circle),
            child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 24),
          ),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? AppTheme.parentTheme : Colors.grey.shade400)),
        ],
      ),
    );
  }

  // --- TOP BAR & OTHER HELPERS (UNCHANGED) ---
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PARENTAL MONITORING", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Row(
              children: [
                const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
                const SizedBox(width: 10),
                const Text("Alex's Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.parentTheme),
              ],
            ),
          ],
        ),
        _buildCircleIcon(Icons.notifications_active_outlined),
      ],
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Icon(icon, size: 22, color: AppTheme.parentTheme),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.parentTheme, Color(0xFF6554C0)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppTheme.parentTheme.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCircularStat("88%", "Score"),
          _buildCircularStat("12", "Tests"),
          _buildCircularStat("4", "Badges"),
        ],
      ),
    );
  }

  Widget _buildCircularStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStrengthRadar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Column(
        children: [
          _buildProgressBar("Logic & Reasoning", 0.9, Colors.blue),
          const SizedBox(height: 16),
          _buildProgressBar("Creative Thinking", 0.6, Colors.purple),
          const SizedBox(height: 16),
          _buildProgressBar("Technical Knowledge", 0.85, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
          Text("${(val * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: val, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color), minHeight: 6)),
      ],
    );
  }
}