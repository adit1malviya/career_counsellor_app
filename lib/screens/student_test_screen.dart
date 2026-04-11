import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';
import 'question_screen.dart';
import '../screens/aptitude_result_screen.dart';
import '../screens/ai_recommendations_screen.dart';
import '../dashboards/roadmap_dashboard.dart'; //

class StudentTestScreen extends StatefulWidget {
  const StudentTestScreen({super.key});

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen> {
  final AssessmentService _apiService = AssessmentService();

  int currentStep = 0;
  bool _isLoadingProgress = true; // ✅ ADDED: The missing variable
  bool _isGeneratingRoadmap = false;
  bool _hasActiveRoadmap = false; // ✅ Tracks if roadmap exists in DB
  String? selectedCareer;
  String? studentCurrentClass;

  final List<Map<String, String>> steps = [
    {"title": "Basic Assessment", "subtitle": "The Starting Point", "phase": "PHASE 1: FOUNDATION"},
    {"title": "Personality", "subtitle": "Who are you truly?", "phase": "PHASE 2: THE DISCOVERY"},
    {"title": "Passion", "subtitle": "Fuel for your career", "phase": ""},
    {"title": "Lifestyle", "subtitle": "Your ideal environment", "phase": ""},
    {"title": "Family Link", "subtitle": "Support & Heritage", "phase": ""},
    {"title": "Interests", "subtitle": "Natural inclinations", "phase": ""},
    {"title": "Dreams", "subtitle": "Vision for the future", "phase": ""},
    {"title": "Aptitude", "subtitle": "Logic & Mental agility", "phase": "PHASE 3: PERFORMANCE"},
    {"title": "Academic", "subtitle": "Current scholastic standing", "phase": ""},
    {"title": "Career Options", "subtitle": "Final Target Selection", "phase": "PHASE 4: TARGET SELECTION"},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
  }

  // ✅ ADD THIS METHOD to handle the API call
  Future<void> _handleGenerateRoadmap() async {
    if (selectedCareer == null) return;

    setState(() => _isGeneratingRoadmap = true);

    try {
      final roadmap = await _apiService.generateAndSaveRoadmap(selectedCareer!);

      if (!mounted) return;
      setState(() => _isGeneratingRoadmap = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success! ${roadmap['total_duration']} Roadmap created."),
          backgroundColor: Colors.green,
        ),
      );

      // TODO: Navigate to your Roadmap Dashboard here!
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RoadmapDashboard()));

    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingRoadmap = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // --- FETCH PROGRESS ON LOAD ---
  Future<void> _loadUserProgress() async {
    try {
      // 1. Fetch the general assessment progress
      final profile = await _apiService.getUserProfile();
      final progress = profile['progress'] ?? {};

      // 2. ✅ NEW: Check if a roadmap already exists in the database
      final roadmap = await _apiService.getCurrentRoadmap();

      int stepIndex = 0;

      // Your existing cascade logic
      if (progress['profile_done'] == true || progress['basic_assessment_done'] == true) stepIndex = 1;
      if (stepIndex == 1 && progress['personality_done'] == true) stepIndex = 2;
      if (stepIndex == 2 && progress['passion_done'] == true) stepIndex = 3;
      if (stepIndex == 3 && progress['lifestyle_done'] == true) stepIndex = 4;
      if (stepIndex == 4 && (progress['financial_done'] == true || progress['family_link_done'] == true)) stepIndex = 5;
      if (stepIndex == 5 && progress['interests_done'] == true) stepIndex = 6;
      if (stepIndex == 6 && (progress['aspiration_done'] == true || progress['dreams_done'] == true)) stepIndex = 7;
      if (stepIndex == 7 && progress['aptitude_done'] == true) stepIndex = 8;
      if (stepIndex == 8 && progress['academic_done'] == true) stepIndex = 9;

      if (mounted) {
        setState(() {
          // 3. ✅ NEW: If a roadmap exists, force the index to the very end (Step 10)
          if (roadmap != null) {
            _hasActiveRoadmap = true;
            selectedCareer = roadmap['title'];
            currentStep = 10; // This ensures the 10th step gets the green tick
          } else {
            currentStep = stepIndex;
          }
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  void _completeStep(int index) async {
    final stepTitle = steps[index]['title']!;

    // If it's the last step, don't fetch questions. Go straight to AI.
    if (index == steps.length - 1) {
      _fetchAndShowAIRecommendations();
      return;
    }

    // Normal flow for all other steps
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.student)),
    );

    try {
      final data = await _apiService.fetchQuestions(stepTitle, currentClass: studentCurrentClass);
      if (!mounted) return;
      Navigator.pop(context);

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(
            title: stepTitle,
            data: data,
            currentClass: studentCurrentClass,
          ),
        ),
      );

      if (result != null && result['success'] == true) {
        final Map<String, dynamic> answers = Map<String, dynamic>.from(result['answers'] ?? {});

        // APTITUDE LOGIC
        if (stepTitle == "Aptitude") {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AptitudeResultScreen(
                questions: result['rawQuestions'],
                userAnswers: answers,
              ),
            ),
          );
        }

        // Save class if needed
        if (stepTitle == "Basic Assessment" && answers.containsKey('current_class')) {
          setState(() {
            studentCurrentClass = answers['current_class']?.toString();
          });
        }

        // Advance step
        if (index == currentStep && currentStep < steps.length - 1) {
          setState(() => currentStep++);
        }
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _fetchAndShowAIRecommendations() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.student),
            SizedBox(height: 20),
            Text("AI is analyzing your profile...",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );

    try {
      final aiData = await _apiService.getAIRecommendations();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      // ✅ NEW: Navigate to the beautiful full screen instead of the bottom sheet
      final selectedPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIRecommendationsScreen(
            aiData: aiData,
            apiService: _apiService,
          ),
        ),
      );

      // ✅ NEW: If they selected a career and came back, update the button UI
      if (selectedPath != null && mounted) {
        setState(() => selectedCareer = selectedPath as String);
        // Advance currentStep to the last index so the "Generate" button becomes visible
        setState(() => currentStep = steps.length - 1);
      }

    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("AI Error: ${e.toString().contains('401') ? 'Authentication Required' : e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ADDED: Show a loading spinner while we fetch progress from the backend
    if (_isLoadingProgress) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4FD),
        body: Center(child: CircularProgressIndicator(color: AppTheme.student)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeroSection(),
                  const SizedBox(height: 30),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (step['phase']!.isNotEmpty) _buildPhaseHeader(step['phase']!),
                          _buildModernJourneyStep(index, step['title']!, step['subtitle']!),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildGenerateButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF0F4FD),
      elevation: 0,
      pinned: true,
      centerTitle: true,
      title: const Text(
        "MY PATHWAY",
        style: TextStyle(
          color: Color(0xFF8E99AF),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    double progress = (currentStep / (steps.length - 1));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "The Road to\nDiscovery",
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, color: Color(0xFF1A2138)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.student.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppTheme.student),
              const SizedBox(width: 8),
              Text(
                "${(progress * 100).toInt()}% COMPLETED",
                style: const TextStyle(color: AppTheme.student, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ REPLACED: Now calls backend and shows a loading spinner
  Widget _buildGenerateButton() {
    // Ready if career is selected OR if roadmap is already active
    bool isReady = (selectedCareer != null || _hasActiveRoadmap) && !_isGeneratingRoadmap;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        gradient: isReady
            ? const LinearGradient(
          colors: [AppTheme.student, Color(0xFF6A5AE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isReady ? null : AppTheme.student.withOpacity(0.15),
        borderRadius: BorderRadius.circular(22),
        boxShadow: isReady
            ? [BoxShadow(color: AppTheme.student.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReady ? () {
            if (_hasActiveRoadmap) {
              // ✅ Redirect to roadmap if it already exists
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoadmapDashboard()));
            } else {
              // ✅ Generate new roadmap
              _handleGenerateRoadmap();
            }
          } : null,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: _isGeneratingRoadmap
                ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
                SizedBox(width: 12),
                Text("ARCHITECTING PATH...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            )
                : Text(
              // ✅ Dynamic text change
              _hasActiveRoadmap ? "CONTINUE YOUR JOURNEY" : "GENERATE MY ROADMAP",
              style: TextStyle(
                color: isReady ? Colors.white : AppTheme.student.withOpacity(0.5),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernJourneyStep(int index, String title, String subtitle) {

    bool isCompleted = index < currentStep || (index == 9 && _hasActiveRoadmap);
    bool isCurrent = index == currentStep && !_hasActiveRoadmap;
    bool isLocked = index > currentStep;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF00D293)
                      : (isCurrent ? AppTheme.student : Colors.white),
                  shape: BoxShape.circle,
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppTheme.student.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                  border: isLocked ? Border.all(color: Colors.grey.shade300, width: 2) : null,
                ),
                child: Icon(
                  isCompleted ? Icons.check : (isLocked ? Icons.lock_outline : Icons.play_arrow_rounded),
                  size: 16,
                  color: isLocked ? Colors.grey.shade400 : Colors.white,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isCompleted ? const Color(0xFF00D293).withOpacity(0.4) : Colors.grey.shade300,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isCurrent ? () => _completeStep(index) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isCurrent
                      ? const LinearGradient(colors: [AppTheme.student, Color(0xFF6A5AE0)])
                      : null,
                  color: isCurrent ? null : (isLocked ? Colors.white.withOpacity(0.5) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isCurrent
                      ? [BoxShadow(color: AppTheme.student.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  border: Border.all(
                    color: isCurrent
                        ? Colors.white.withOpacity(0.2)
                        : (isLocked ? Colors.transparent : Colors.white),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            index == steps.length - 1 && selectedCareer != null ? selectedCareer! : title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isCurrent
                                  ? Colors.white
                                  : (isLocked ? Colors.grey.shade400 : const Color(0xFF1A2138)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isCurrent ? Colors.white.withOpacity(0.7) : Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent) const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF8E99AF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
      ),
    );
  }
}