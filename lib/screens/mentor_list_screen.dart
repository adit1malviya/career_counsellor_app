import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';
import 'chat_screen.dart'; // ← Import the new chat screen

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  final AssessmentService _apiService = AssessmentService();

  List<dynamic> _allMentors = [];
  List<dynamic> _myMentors = [];
  bool _isLoading = true;

  final Set<String> _sentRequestIds = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final profile = await _apiService.getUserProfile();
      final aspiration = profile['aspiration_data'] ?? {};
      String goal = aspiration['dream_career'] ?? "technology";

      final rawAllMentors = await _apiService.searchMentors(careerGoal: goal);
      final acceptedMentors = await _apiService.getAcceptedConnections();
      final existingRequests = await _apiService.getSentRequests();

      if (mounted) {
        setState(() {
          _myMentors = acceptedMentors;

          final acceptedUserIds =
          _myMentors.map((m) => m['user_id'].toString()).toSet();

          _allMentors = rawAllMentors.where((m) {
            return !acceptedUserIds.contains(m['user_id'].toString());
          }).toList();

          _sentRequestIds.clear();
          for (var conn in existingRequests) {
            String? mId = conn['mentor_id']?.toString();
            if (mId != null) _sentRequestIds.add(mId);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching mentors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Navigation helper ──────────────────────────────────────────────────────

  void _openChat({
    required String userId,
    required String name,
    required String role,
    required String avatarUrl,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ChatScreen(
          otherUserId: userId,
          otherUserName: name,
          otherUserRole: role,
          avatarUrl: avatarUrl,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            "Mentorship",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppTheme.student,
            labelColor: AppTheme.student,
            unselectedLabelColor: Colors.grey,
            labelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "ALL MENTORS"),
              Tab(text: "MY MENTORS"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
            child: CircularProgressIndicator(color: AppTheme.student))
            : TabBarView(
          children: [
            _buildAllMentorsTab(),
            _buildMyMentorsTab(),
          ],
        ),
      ),
    );
  }

  // ── Tab: All Mentors ───────────────────────────────────────────────────────

  Widget _buildAllMentorsTab() {
    if (_allMentors.isEmpty) {
      return const Center(
          child: Text("No new mentors found matching your goals."));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: _allMentors.length,
      itemBuilder: (context, index) {
        final m = _allMentors[index];
        final String mentorProfileId = m['id'].toString();
        final String userId = m['user_id'].toString();
        final bool isRequested = _sentRequestIds.contains(mentorProfileId);

        return _buildMentorProfessionalCard(
          context,
          {
            "id": mentorProfileId,
            "user_id": userId,
            "name": m['full_name'] ?? "Expert",
            "role": m['expertise'] ?? "Professional",
            "image": 'https://i.pravatar.cc/150?u=$mentorProfileId',
            "rating": (m['rating'] ?? 0.0).toString(),
            "sessions": "${m['years_experience']} Yrs Exp.",
          },
          isMyMentorTab: false,
          isRequested: isRequested,
        );
      },
    );
  }

  // ── Tab: My Mentors ────────────────────────────────────────────────────────

  Widget _buildMyMentorsTab() {
    if (_myMentors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              "No mentors assigned yet",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      itemCount: _myMentors.length,
      itemBuilder: (context, index) {
        final m = _myMentors[index];
        final String userId = m['user_id'].toString();

        return _buildMentorProfessionalCard(
          context,
          {
            "id": userId,
            "user_id": userId,
            "name": m['full_name'] ?? "Expert",
            "role": m['role'] ?? "Mentor",
            "image": 'https://i.pravatar.cc/150?u=$userId',
            "rating": "5.0",
            "sessions": "Active Connection",
          },
          isMyMentorTab: true,
          isRequested: false,
        );
      },
    );
  }

  // ── Mentor Card ────────────────────────────────────────────────────────────

  Widget _buildMentorProfessionalCard(
      BuildContext context,
      Map<String, String> mentor, {
        required bool isMyMentorTab,
        bool isRequested = false,
      }) {
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
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(mentor['image']!),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mentor['name']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentor['role']!,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            mentor['rating']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.history_edu_rounded,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            mentor['sessions']!,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
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
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F9FF),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                // ── Left button: View Profile / Request Session ──────────
                Expanded(
                  child: _buildActionButton(
                    icon: isMyMentorTab
                        ? Icons.calendar_today_outlined
                        : Icons.person_outline_rounded,
                    label: isMyMentorTab ? "Request Session" : "View Profile",
                    color: AppTheme.student,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                // ── Right button: Chat / Request Mentorship ──────────────
                Expanded(
                  child: _buildActionButton(
                    icon: isMyMentorTab
                        ? Icons.chat_bubble_outline_rounded
                        : (isRequested
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_task_rounded),
                    label: isMyMentorTab
                        ? "Chat Now"
                        : (isRequested ? "Requested" : "Request Mentorship"),
                    color: isRequested
                        ? Colors.grey.shade400
                        : (isMyMentorTab ? Colors.white : Colors.white),
                    textColor: isRequested
                        ? Colors.white
                        : AppTheme.student,
                    isOutlined: !isRequested,
                    onTap: () async {
                      // ── My Mentors tab → open chat ───────────────────
                      if (isMyMentorTab) {
                        _openChat(
                          userId: mentor['user_id']!,
                          name: mentor['name']!,
                          role: 'mentor',
                          avatarUrl: mentor['image']!,
                        );
                        return;
                      }

                      // ── All Mentors tab → send connection request ────
                      if (!isRequested) {
                        final bool success =
                        await _apiService.requestMentorship(mentor['id']!);
                        if (success) {
                          setState(
                                  () => _sentRequestIds.add(mentor['id']!));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Mentorship request sent successfully!"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Action Button ──────────────────────────────────────────────────────────

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
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}