import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';

class RoadmapDashboard extends StatefulWidget {
  final String? studentId; // ✅ Added to support Parent viewing a Ward
  const RoadmapDashboard({super.key, this.studentId});

  @override
  State<RoadmapDashboard> createState() => _RoadmapDashboardState();
}

class _RoadmapDashboardState extends State<RoadmapDashboard> {
  final AssessmentService _apiService = AssessmentService();
  late Future<Map<String, dynamic>?> _roadmapFuture;

  @override
  void initState() {
    super.initState();
    _loadRoadmap();
  }

  void _loadRoadmap() {
    // ✅ Logic: If studentId is passed (Parent Mode), fetch Ward's Roadmap.
    // Otherwise (Student Mode), fetch own roadmap.
    if (widget.studentId != null) {
      _roadmapFuture = _apiService.getWardRoadmap(widget.studentId!);
    } else {
      _roadmapFuture = _apiService.getCurrentRoadmap();
    }
  }

  void _handleTaskToggle(Map<String, dynamic> task) async {
    if (task['status'] == 'Completed') return;

    final taskId = task['id'];
    try {
      await _apiService.toggleTaskCompletion(taskId);
      setState(() {
        task['status'] = 'Completed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task completed!"), backgroundColor: Color(0xFF00D293)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "MY ROADMAP",
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: AppTheme.textSecondary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Stack(
        children: [
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
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _roadmapFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.student));
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(child: Text("No active roadmap found."));
                }

                final roadmap = snapshot.data!;
                final phases = roadmap['phases'] as List<dynamic>? ?? [];

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  // ✅ FIX: ClampingScrollPhysics stops the "unnecessary scrolling" into empty space
                  physics: const ClampingScrollPhysics(),
                  children: [
                    _buildHeroHeader(roadmap),
                    const SizedBox(height: 35),
                    const Text(
                      "JOURNEY PHASES",
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...phases.asMap().entries.map((entry) => _buildPhaseCard(entry.value, entry.key + 1)),
                    const SizedBox(height: 40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Map<String, dynamic> roadmap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // ✅ KEY FIX: Maps to 'career_title' from backend JSON
          roadmap['career_title'] ?? roadmap['title'] ?? 'Career Roadmap',
          style: AppTheme.heading.copyWith(fontSize: 34, height: 1.2),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.student.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.student.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.track_changes_rounded, size: 18, color: AppTheme.student),
              const SizedBox(width: 8),
              Text(
                // ✅ KEY FIX: Maps to 'total_duration' from backend JSON
                (roadmap['total_duration'] ?? roadmap['description'] ?? '').toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.student,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseCard(Map<String, dynamic> phase, int phaseNumber) {
    // ✅ KEY FIX: Backend uses 'weekly_breakdown' or 'tasks' depending on generation logic
    final tasks = phase['weekly_breakdown'] ?? phase['tasks'] as List<dynamic>? ?? [];
    final String status = phase['status'] ?? 'Active'; // Default to Active for generated roadmaps

    Color accentColor = (status == 'Completed') ? const Color(0xFF00D293) : AppTheme.student;
    Color bgColor = (status == 'Completed') ? const Color(0xFFE6FBF4) : AppTheme.studentBg;
    IconData statusIcon = (status == 'Completed') ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.textSecondary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            iconColor: accentColor,
            collapsedIconColor: AppTheme.textMuted,
            title: Row(
              children: [
                Container(
                  height: 42, width: 42,
                  decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text("$phaseNumber", style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ✅ KEY FIX: Maps to 'phase_title' from backend JSON
                        phase['phase_title'] ?? phase['title'] ?? 'Phase',
                        style: AppTheme.cardTitle.copyWith(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, size: 14, color: accentColor),
                          const SizedBox(width: 4),
                          Text(status.toUpperCase(), style: TextStyle(color: accentColor, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      phase['description'] ?? "Foundation building and skill development.",
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "WEEKLY TASKS",
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 8),
                    ...tasks.map((task) => _buildTaskRow(task)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskRow(Map<String, dynamic> task) {
    // ✅ KEY FIX: Maps to 'topic' or 'title' from backend JSON
    final String title = task['topic'] ?? task['title'] ?? 'Learning Task';
    bool isCompleted = task['status'] == 'Completed';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: isCompleted ? null : () => _handleTaskToggle(task),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF00D293) : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF00D293) : AppTheme.textMuted.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.check, size: 16, color: isCompleted ? Colors.white : Colors.transparent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                  fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w700,
                  fontSize: 14,
                  height: 1.4,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}