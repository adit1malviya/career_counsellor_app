import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../profiles/parent_profile.dart';
import '../screens/parent_report_screen.dart';
import '../services/assessment_service.dart';
import '../dashboards/roadmap_dashboard.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;
  final AssessmentService _apiService = AssessmentService();

  // Dynamic State Variables
  String _wardName = "Ward";
  String _wardId = "";
  double _logicalScore = 0.0;
  double _quantScore = 0.0;
  double _verbalScore = 0.0;

  Map<String, dynamic>? _roadmapData;
  bool _isLoading = true; // ✅ Track global loading state

  // Mock reports - in a real app, fetch these from an API
  final List<Map<String, dynamic>> allReports = [
    {
      "title": "Career Pathing",
      "subtitle": "Backend Systems Focus",
      "date": "2026-03-28",
      "displayDate": "28 Mar",
      "mentor": "Dr. Sarah James",
      "avatar": "https://i.pravatar.cc/150?img=32",
      "category": "Technical",
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  /// ✅ Orchestrator: Fetches all necessary ward data
  Future<void> _loadAllData() async {
    try {
      final status = await _apiService.getLinkedStudentStatus();

      if (status['is_linked'] == true) {
        _wardId = status['student']['id'];
        _wardName = status['student']['full_name'] ?? "Ward";

        // Fetch scores and roadmap in parallel for speed
        final results = await Future.wait([
          _apiService.getProfileById(_wardId),
          _apiService.getWardRoadmap(_wardId),
        ]);

        final profileData = results[0] as Map<String, dynamic>;
        final roadmap = results[1] as Map<String, dynamic>?;

        final Map<String, dynamic> apti = profileData['apti_data'] ?? {};
        final Map<String, dynamic> scores = apti['scores'] ?? {};
        final double max = (scores['max_score'] ?? 15).toDouble();

        if (mounted) {
          setState(() {
            _logicalScore = ((scores['logical'] ?? 0).toDouble()) / max;
            _quantScore = ((scores['quantitative'] ?? 0).toDouble()) / max;
            _verbalScore = ((scores['verbal'] ?? 0).toDouble()) / max;
            _roadmapData = roadmap;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F9),
      // Using AnimatedSwitcher for smooth tab transitions
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0: return _buildHomeContent();
      case 1: return const ParentReportScreen();
      case 2: return const Center(child: Text("Chat with Mentors"));
      case 3: return const ParentProfile();
      default: return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.parentTheme));
    }

    final firstName = _wardName.split(' ')[0];

    return SafeArea(
      child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // Always use Clamping to prevent that "pulling away from the top" look
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisSize: MainAxisSize.min is crucial to prevent extra height
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(firstName),
                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        if (_wardId.isNotEmpty) {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RoadmapDashboard(studentId: _wardId))
                          );
                        }
                      },
                      child: _buildRoadmapTrackerCard(firstName),
                    ),

                    const SizedBox(height: 32),
                    Text("$firstName's Top Strengths",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 16),
                    _buildStrengthRadar(),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Latest Session Report",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 1),
                          child: Text("VIEW ALL",
                              style: TextStyle(fontSize: 12, color: AppTheme.parentTheme.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPremiumReportCard(allReports.first),

                    // ✅ The "Smart Stopper"
                    // This ensures the scroll ends right after the card,
                    // but gives it enough room to clear the nav bar.
                    // If it's still scrolling too much, reduce 110 to 90.
                    const SizedBox(height: 55),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _buildRoadmapTrackerCard(String name) {
    // ✅ Improved Logic: Check if roadmap data exists at all
    bool hasRoadmap = _roadmapData != null && _roadmapData!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5141B3), Color(0xFF6554C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF5141B3).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(hasRoadmap ? "ROADMAP ACTIVE" : "JOURNEY STATUS",
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Text(
            // ✅ Updated Dynamic Text
            hasRoadmap
                ? "Track $name's\nRoadmap & Progress"
                : "$name's journey\nhas not started yet",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.2),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              // If data exists but progress isn't defined, default to a small visual start (0.1)
              value: hasRoadmap ? ((_roadmapData!['progress_percentage'] ?? 0.0) / 100.0) : 0.0,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00FFC2)),
            ),
          ),
        ],
      ),
    );
  }

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
                    Text(report['date'] ?? "28 Mar", style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(report['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(report['subtitle'], style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(report['avatar'] ?? 'https://i.pravatar.cc/150')),
                    const SizedBox(width: 12),
                    Expanded(child: Text(report['mentor'] ?? "Mentor", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
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
              decoration: const BoxDecoration(
                color: Color(0xFFF0EFFF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
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

  Widget _buildTopBar(String name) {
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
                Text("$name's Progress", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.parentTheme),
              ],
            ),
          ],
        ),
        _buildCircleIcon(Icons.notifications_active_outlined),
      ],
    );
  }

  Widget _buildStrengthRadar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)]),
      child: Column(
        children: [
          _buildProgressBar("Logical Reasoning", _logicalScore, Colors.blue),
          const SizedBox(height: 16),
          _buildProgressBar("Quantitative Aptitude", _quantScore, Colors.purple),
          const SizedBox(height: 16),
          _buildProgressBar("Verbal Ability", _verbalScore, Colors.orange),
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

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
          ]
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

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 22, color: AppTheme.parentTheme),
    );
  }
}