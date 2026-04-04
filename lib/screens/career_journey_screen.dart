import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CareerJourneyScreen extends StatefulWidget {
  const CareerJourneyScreen({super.key});

  @override
  State<CareerJourneyScreen> createState() => _CareerJourneyScreenState();
}

class _CareerJourneyScreenState extends State<CareerJourneyScreen> {
  int completedIndex = -1; // -1 to 8 are the tests
  String? selectedCareer; // Stores the choice for the final roadmap

  @override
  Widget build(BuildContext context) {
    bool allTestsDone = completedIndex >= 8;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: Stack(
        children: [
          Positioned(
            top: -100, right: -50,
            child: CircleAvatar(radius: 150, backgroundColor: AppTheme.student.withOpacity(0.03)),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(context),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildHeaderInfo(),
                        const SizedBox(height: 30),

                        _buildPhaseSection("PHASE 1: FOUNDATION", [
                          _testData(0, "Basic Assessment", "The Starting Point", Icons.explore_rounded),
                        ]),

                        _buildPhaseSection("PHASE 2: THE DISCOVERY", [
                          _testData(1, "Personality", "Who are you truly?", Icons.psychology_rounded),
                          _testData(2, "Passion", "Fuel for your career", Icons.auto_awesome_rounded),
                          _testData(3, "Lifestyle", "Your ideal environment", Icons.wb_sunny_rounded),
                          _testData(4, "Family Link", "Support & Heritage", Icons.family_restroom_rounded),
                          _testData(5, "Interests", "Natural inclinations", Icons.interests_rounded),
                          _testData(6, "Dreams", "Vision for the future", Icons.rocket_launch_rounded),
                        ]),

                        _buildPhaseSection("PHASE 3: PERFORMANCE", [
                          _testData(7, "Aptitude", "Logic & Mental agility", Icons.biotech_rounded),
                          _testData(8, "Academic", "Current scholastic standing", Icons.school_rounded),
                        ]),

                        // --- NEW PHASE 4: CAREER SELECTION ---
                        const SizedBox(height: 30),
                        _buildPhaseHeader("PHASE 4: TARGET SELECTION"),
                        _buildCareerSelectionTile(allTestsDone),

                        const SizedBox(height: 40),
                        _buildFinalAction(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW COMPONENT: CAREER SELECTION TILE ---
  Widget _buildCareerSelectionTile(bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          // INDICATOR
          Container(
            width: 68,
            alignment: Alignment.center,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selectedCareer != null ? const Color(0xFF00C2FF) : (isUnlocked ? Colors.white : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: Border.all(color: isUnlocked ? AppTheme.student.withOpacity(0.1) : Colors.transparent, width: 4),
              ),
              child: Icon(
                selectedCareer != null ? Icons.check : (isUnlocked ? Icons.ads_click_rounded : Icons.lock_rounded),
                size: 18,
                color: selectedCareer != null ? Colors.white : (isUnlocked ? AppTheme.student : Colors.grey.shade400),
              ),
            ),
          ),

          // CONTENT
          Expanded(
            child: GestureDetector(
              onTap: isUnlocked ? () => _showCareerOptions() : null,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: selectedCareer != null ? const Color(0xFF00C2FF).withOpacity(0.3) : Colors.white),
                  boxShadow: isUnlocked ? [BoxShadow(color: AppTheme.student.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Career Options",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isUnlocked ? Colors.black : Colors.grey.shade400)
                    ),
                    const SizedBox(height: 4),
                    Text(selectedCareer ?? (isUnlocked ? "Select your target career path" : "Unlock by completing Phase 3"),
                        style: TextStyle(fontSize: 12, color: isUnlocked ? AppTheme.student : Colors.grey.shade300, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CAREER SELECTION MODAL ---
  void _showCareerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Top AI Recommendations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text("Based on your 9-layer assessment scores.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              _optionItem("Software Architect", "Matches your Aptitude & Academic score"),
              _optionItem("UI/UX Product Designer", "Matches your Dreams & Passion score"),
              _optionItem("Cybersecurity Analyst", "Matches your Lifestyle & Logic score"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _optionItem(String title, String matchReason) {
    return ListTile(
      onTap: () {
        setState(() => selectedCareer = title);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.student.withOpacity(0.05), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.stars_rounded, color: AppTheme.student)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(matchReason, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.student),
    );
  }

  // --- UPDATED FINAL ACTION LOGIC ---
  Widget _buildFinalAction() {
    bool isReady = selectedCareer != null; // Button only glows after career selection
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: isReady ? const LinearGradient(colors: [Color(0xFF0056D2), Color(0xFF00C2FF)]) : null,
        color: isReady ? null : Colors.grey.shade300,
        boxShadow: isReady ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))] : [],
      ),
      child: ElevatedButton(
        onPressed: isReady ? () {
          // Navigate to final roadmap screen
        } : null,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Text("GENERATE MY ROADMAP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  // (Keeping previous AppBar, HeaderInfo, PhaseHeader, JourneyTile helpers...)
  // Note: Just ensure the vertical line in _buildPhaseSection uses the student blue.

  Widget _buildCustomAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
          const Text("MY PATHWAY", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("The Road to\nDiscovery", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
        const SizedBox(height: 10),
        Text("Complete all layers to unlock your AI-generated Career Roadmap.", style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPhaseSection(String phaseTitle, List<Map<String, dynamic>> tests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhaseHeader(phaseTitle),
        Stack(
          children: [
            Positioned(left: 33, top: 0, bottom: 0, child: Container(width: 2, color: AppTheme.student.withOpacity(0.1))),
            Column(children: tests.map((data) => _buildJourneyTile(data)).toList()),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPhaseHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 20, top: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.student, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildJourneyTile(Map<String, dynamic> data) {
    int index = data['index'];
    bool isUnlocked = index == 0 || index <= completedIndex + 1;
    bool isDone = index <= completedIndex;
    Color doneColor = const Color(0xFF00C2FF);

    return GestureDetector(
      onTap: isUnlocked ? () => setState(() => completedIndex = index) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            Container(
              width: 68,
              alignment: Alignment.center,
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isDone ? doneColor : (isUnlocked ? Colors.white : Colors.grey.shade200),
                  shape: BoxShape.circle,
                  border: Border.all(color: isUnlocked ? AppTheme.student.withOpacity(0.1) : Colors.transparent, width: 4),
                ),
                child: Icon(isDone ? Icons.check : (isUnlocked ? data['icon'] : Icons.lock_rounded), size: 18, color: isDone ? Colors.white : (isUnlocked ? AppTheme.student : Colors.grey.shade400)),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: isDone ? doneColor.withOpacity(0.3) : Colors.white),
                  boxShadow: isUnlocked ? [BoxShadow(color: AppTheme.student.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))] : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isUnlocked ? Colors.black : Colors.grey.shade400)),
                    const SizedBox(height: 4),
                    Text(data['subtitle'], style: TextStyle(fontSize: 12, color: isUnlocked ? Colors.blueGrey.shade300 : Colors.grey.shade300)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _testData(int idx, String t, String s, IconData i) {
    return {'index': idx, 'title': t, 'subtitle': s, 'icon': i};
  }
}