import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';
import 'question_screen.dart';
import '../screens/aptitude_result_screen.dart';

class StudentTestScreen extends StatefulWidget {
  const StudentTestScreen({super.key});

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

class _StudentTestScreenState extends State<StudentTestScreen> {
  final AssessmentService _apiService = AssessmentService();

  int currentStep = 0;
  bool _isLoadingProgress = true; // ✅ ADDED: The missing variable
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

  // --- FETCH PROGRESS ON LOAD ---
  Future<void> _loadUserProgress() async {
    try {
      final profile = await _apiService.getUserProfile();
      final progress = profile['progress'] ?? {};

      int stepIndex = 0;

      // Cascade check: advance the step if the previous one is done.
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
          currentStep = stepIndex;
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

      _showCareerSelectionSheet(aiData);

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

  Widget _buildGenerateButton() {
    bool isReady = selectedCareer != null;
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
          onTap: isReady
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Roadmap generation started..."),
                backgroundColor: AppTheme.student,
              ),
            );
          }
              : null,
          borderRadius: BorderRadius.circular(22),
          child: Center(
            child: Text(
              "GENERATE MY ROADMAP",
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
    bool isCompleted = index < currentStep;
    bool isCurrent = index == currentStep;
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

  void _showCareerSelectionSheet(Map<String, dynamic> aiData) {
    final List<dynamic> options = aiData['top_5_careers'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("AI Recommended Paths", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              aiData['brutal_truth_summary'] ?? "Select one to finalize your roadmap",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ...options.map((career) => _buildCareerTile(
                career['title'],
                career['rationale']
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerTile(String title, String category) {
    return GestureDetector(
      onTap: () async {
        bool success = await _apiService.selectCareer(title);
        if (success) {
          setState(() => selectedCareer = title);
          if (mounted) Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.student, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(category, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}