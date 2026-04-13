import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';
import 'chat_screen.dart';
import 'student_session_screen.dart';
import 'student_schedule_screen.dart'; // ✅ Added import for the new schedule screen

class MentorListScreen extends StatefulWidget {
  const MentorListScreen({super.key});

  @override
  State<MentorListScreen> createState() => _MentorListScreenState();
}

class _MentorListScreenState extends State<MentorListScreen> {
  final AssessmentService _apiService = AssessmentService();

  List<dynamic> _allMentors = [];

  // ✅ Each entry: { user_id, full_name, role, mentor_profile_id (enriched) }
  List<Map<String, String>> _myMentors = [];

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

      // Fetch all three in parallel for speed
      final results = await Future.wait([
        _apiService.searchMentors(careerGoal: goal),
        _apiService.getAcceptedConnections(),
        _apiService.getSentRequests(),
      ]);

      final List<dynamic> rawAllMentors    = results[0] as List<dynamic>;
      final List<dynamic> acceptedRaw      = results[1] as List<dynamic>;
      final List<dynamic> existingRequests = results[2] as List<dynamic>;

      // Build a lookup: user_id → mentor_profile_id (Mentor.id)
      // The searchMentors response includes BOTH id (profile) and user_id
      final Map<String, String> userIdToProfileId = {};
      for (final m in rawAllMentors) {
        final uid = m['user_id']?.toString() ?? '';
        final pid = m['id']?.toString() ?? '';
        if (uid.isNotEmpty && pid.isNotEmpty) {
          userIdToProfileId[uid] = pid;
        }
      }

      // ✅ Enrich accepted connections with mentor_profile_id
      // acceptedRaw items: { user_id, full_name, role, request_type }
      // We need mentor_profile_id to call the availability API later
      final List<Map<String, String>> enrichedMyMentors = [];
      for (final m in acceptedRaw) {
        final String userId = m['user_id']?.toString() ?? '';
        String profileId = userIdToProfileId[userId] ?? '';

        // If not found in the search results (mentor may not show up in this
        // career-specific search), try a direct lookup
        if (profileId.isEmpty && userId.isNotEmpty) {
          debugPrint(
              "⚠️ mentor_profile_id not in search results for user_id=$userId — fetching directly");
          final lookedUp =
          await _apiService.getMentorProfileIdByUserId(userId);
          profileId = lookedUp ?? '';
        }

        debugPrint(
            "✅ MY MENTOR: user_id=$userId, profile_id=$profileId, name=${m['full_name']}");

        enrichedMyMentors.add({
          "user_id":           userId,
          "mentor_profile_id": profileId,
          "name":              m['full_name']?.toString() ?? "Expert",
          "role":              m['role']?.toString() ?? "Mentor",
          "request_type":      m['request_type']?.toString() ?? "",
        });
      }

      // Build the accepted user_id set to filter from ALL MENTORS tab
      final acceptedUserIds =
      enrichedMyMentors.map((m) => m['user_id']!).toSet();

      // Filter ALL MENTORS: remove those already accepted
      final filteredAll = rawAllMentors.where((m) {
        return !acceptedUserIds.contains(m['user_id']?.toString() ?? '');
      }).toList();

      // Populate pending request IDs
      final Set<String> pendingIds = {};
      for (final conn in existingRequests) {
        final mId = conn['mentor_id']?.toString();
        if (mId != null) pendingIds.add(mId);
      }

      if (mounted) {
        setState(() {
          _myMentors      = enrichedMyMentors;
          _allMentors     = filteredAll;
          _sentRequestIds
            ..clear()
            ..addAll(pendingIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching mentors: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

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
          otherUserId:   userId,
          otherUserName: name,
          otherUserRole: role,
          avatarUrl:     avatarUrl,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end:   Offset.zero,
            ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _openSessionScreen({
    required String mentorProfileId,
    required String mentorUserId,
    required String mentorName,
  }) {
    if (mentorProfileId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Could not find mentor's profile. Please try again later."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentSessionScreen(
          mentorProfileId: mentorProfileId, // ✅ Mentor.id (profile UUID)
          mentorUserId:    mentorUserId,    // ✅ Mentor.user_id (for avatar/chat)
          mentorName:      mentorName,
        ),
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
          // ✅ NEW: Added the Calendar icon to access My Schedule
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_calendar_rounded, color: AppTheme.student),
              tooltip: "My Schedule",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentScheduleScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppTheme.student,
            labelColor:     AppTheme.student,
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

  // ── All Mentors tab ────────────────────────────────────────────────────────

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
        final String mentorProfileId = m['id']?.toString() ?? '';
        final String userId          = m['user_id']?.toString() ?? '';
        final bool isRequested       = _sentRequestIds.contains(mentorProfileId);

        return _buildMentorCard(
          mentorProfileId: mentorProfileId,
          userId:          userId,
          name:            m['full_name']?.toString() ?? "Expert",
          role:            m['expertise']?.toString() ?? "Professional",
          rating:          (m['rating'] ?? 0.0).toString(),
          sessionLabel:    "${m['years_experience'] ?? 0} Yrs Exp.",
          isMyMentorTab:   false,
          isRequested:     isRequested,
        );
      },
    );
  }

  // ── My Mentors tab ─────────────────────────────────────────────────────────

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
        return _buildMentorCard(
          mentorProfileId: m['mentor_profile_id']!,
          userId:          m['user_id']!,
          name:            m['name']!,
          role:            m['role']!,
          rating:          "5.0",
          sessionLabel:    "Active Connection",
          isMyMentorTab:   true,
          isRequested:     false,
        );
      },
    );
  }

  // ── Shared card widget ─────────────────────────────────────────────────────

  Widget _buildMentorCard({
    required String mentorProfileId,
    required String userId,
    required String name,
    required String role,
    required String rating,
    required String sessionLabel,
    required bool   isMyMentorTab,
    required bool   isRequested,
  }) {
    final String avatarUrl = 'https://i.pravatar.cc/150?u=$userId';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                    backgroundImage: NetworkImage(avatarUrl)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(role,
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(rating,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 12),
                          const Icon(Icons.history_edu_rounded,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(sessionLabel,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F9FF),
              borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Row(
              children: [
                // Left button: Request Session (my mentors) / View Profile (all)
                Expanded(
                  child: _buildActionButton(
                    icon: isMyMentorTab
                        ? Icons.calendar_today_outlined
                        : Icons.person_outline_rounded,
                    label:
                    isMyMentorTab ? "Request Session" : "View Profile",
                    color: AppTheme.student,
                    onTap: () {
                      if (isMyMentorTab) {
                        _openSessionScreen(
                          mentorProfileId: mentorProfileId,
                          mentorUserId:    userId,
                          mentorName:      name,
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Right button: Chat (my mentors) / Request Mentorship (all)
                Expanded(
                  child: _buildActionButton(
                    icon: isMyMentorTab
                        ? Icons.chat_bubble_outline_rounded
                        : (isRequested
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_task_rounded),
                    label: isMyMentorTab
                        ? "Chat Now"
                        : (isRequested
                        ? "Requested"
                        : "Request Mentorship"),
                    color: isRequested
                        ? Colors.grey.shade400
                        : Colors.white,
                    textColor:
                    isRequested ? Colors.white : AppTheme.student,
                    isOutlined: !isRequested,
                    onTap: () async {
                      if (isMyMentorTab) {
                        _openChat(
                          userId:    userId,
                          name:      name,
                          role:      'mentor',
                          avatarUrl: avatarUrl,
                        );
                        return;
                      }
                      if (!isRequested) {
                        final bool success =
                        await _apiService.requestMentorship(
                            mentorProfileId);
                        if (success && mounted) {
                          setState(
                                  () => _sentRequestIds.add(mentorProfileId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Mentorship request sent successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
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

  Widget _buildActionButton({
    required IconData  icon,
    required String    label,
    required Color     color,
    required VoidCallback onTap,
    Color   textColor  = Colors.white,
    bool    isOutlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color:        isOutlined ? Colors.white : color,
          borderRadius: BorderRadius.circular(16),
          border: isOutlined
              ? Border.all(color: color.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color:      textColor,
                    fontWeight: FontWeight.bold,
                    fontSize:   13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}