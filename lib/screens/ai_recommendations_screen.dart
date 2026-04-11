import 'package:flutter/material.dart';
import '../services/assessment_service.dart';
import '../theme/app_theme.dart'; // ✅ Make sure this path points to your AppTheme

class AIRecommendationsScreen extends StatefulWidget {
  final Map<String, dynamic> aiData;
  final AssessmentService apiService;

  const AIRecommendationsScreen({
    super.key,
    required this.aiData,
    required this.apiService,
  });

  @override
  State<AIRecommendationsScreen> createState() => _AIRecommendationsScreenState();
}

class _AIRecommendationsScreenState extends State<AIRecommendationsScreen> {
  bool _isSelecting = false;

  void _handleCareerSelection(String title) async {
    setState(() => _isSelecting = true);

    bool success = await widget.apiService.selectCareer(title);

    if (mounted) {
      setState(() => _isSelecting = false);
      if (success) {
        Navigator.pop(context, title);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save selection. Try again."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> options = widget.aiData['top_5_careers'] ?? [];
    final String brutalTruth = widget.aiData['brutal_truth_summary'] ?? "Here is your personalized roadmap based on your assessment.";

    return Scaffold(
      extendBodyBehindAppBar: true, // Lets the gradient flow behind the appbar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: const Text(
          "YOUR ROADMAP",
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. Beautiful Background matching your theme
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundMid],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            width: double.infinity,
            height: double.infinity,
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recommended\nCareer Paths",
                    style: AppTheme.heading.copyWith(fontSize: 36), // Using your custom heading
                  ),
                  const SizedBox(height: 24),

                  // 2. The Restyled "Profile Analysis" Report
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.student.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(color: Colors.white, width: 2), // Glassmorphism touch
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Accent header bar
                          Container(
                            height: 4,
                            width: double.infinity,
                            color: AppTheme.student,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.studentBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.analytics_rounded, color: AppTheme.student, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      "Profile Analysis",
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  brutalTruth,
                                  style: AppTheme.subheading.copyWith(
                                    height: 1.6,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  const Text(
                    "SELECT YOUR TARGET",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Themed Career Cards
                  ...options.map((career) => _buildPremiumCareerCard(
                    career['title'],
                    career['rationale'],
                  )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isSelecting)
            Container(
              color: AppTheme.backgroundMid.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumCareerCard(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textSecondary.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppTheme.studentBg, width: 1.5), // Subtle student-themed border
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          highlightColor: AppTheme.studentBg.withOpacity(0.5),
          splashColor: AppTheme.studentBg,
          onTap: () => _handleCareerSelection(title),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Themed Icon
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: AppTheme.studentBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: AppTheme.student, size: 22),
                ),
                const SizedBox(width: 16),

                // Content using AppTheme
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.cardTitle.copyWith(color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: AppTheme.cardSubtitle,
                      ),
                    ],
                  ),
                ),

                // Arrow
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.student),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}