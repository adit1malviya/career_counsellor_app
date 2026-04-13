import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';
import 'video_call_screen.dart'; // ✅ Added import for the VC screen

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final MentorService _service = MentorService();

  List<dynamic> _mySessions = [];
  bool _isLoading = true;
  String? _joiningSessionId;

  @override
  void initState() {
    super.initState();
    _fetchMySessions();
  }

  Future<void> _fetchMySessions() async {
    setState(() => _isLoading = true);
    final data = await _service.getUpcomingSessions();
    if (mounted) {
      setState(() {
        _mySessions = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _joinSession(Map<String, dynamic> session) async {
    final String sessionId = session['session_id']?.toString() ?? '';
    if (sessionId.isEmpty) return;

    setState(() => _joiningSessionId = sessionId);
    final result = await _service.joinVideoSession(sessionId);
    if (mounted) setState(() => _joiningSessionId = null);

    if (result != null && mounted) {
      final String dyteToken = result['token'] ?? '';

      // ✅ AWAIT the video call screen. The code pauses here while they chat.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(token: dyteToken),
        ),
      );

      // ✅ Once they tap 'Leave Call' and the screen closes, hit the backend!
      await _service.endVideoSession(sessionId);

      // ✅ Automatically refresh the UI to show the session is complete
      _fetchMySessions();

    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not join session. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Schedule",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.student),
            onPressed: _fetchMySessions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMySessions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.student))
            : _mySessions.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          itemCount: _mySessions.length,
          itemBuilder: (context, index) => _buildSessionCard(_mySessions[index]),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                "No upcoming sessions",
                style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Book a slot with a mentor to see it here.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final bool isLive = session['is_live'] == true;
    final int secsUntil = session['seconds_until_start'] ?? 999999;
    final String name = session['other_party_name'] ?? 'Mentor';
    final String sessionId = session['session_id']?.toString() ?? '';
    final bool isJoining = _joiningSessionId == sessionId;

    DateTime? scheduledAt;
    try {
      scheduledAt = DateTime.parse(session['scheduled_at'].toString());
    } catch (_) {}

    final String timeLabel = scheduledAt != null
        ? "${scheduledAt.day}/${scheduledAt.month} at "
        "${scheduledAt.hour.toString().padLeft(2, '0')}:"
        "${scheduledAt.minute.toString().padLeft(2, '0')}"
        : "—";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isLive ? AppTheme.student.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: isLive ? 15 : 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: isLive ? AppTheme.student : Colors.transparent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isLive ? AppTheme.student : AppTheme.student.withValues(alpha: 0.1),
                  child: Icon(Icons.video_camera_front_rounded, color: isLive ? Colors.white : AppTheme.student),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(timeLabel, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.redAccent, size: 8),
                        SizedBox(width: 4),
                        Text("LIVE", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isLive || secsUntil <= 300) ? AppTheme.student : Colors.grey.shade100,
                  foregroundColor: (isLive || secsUntil <= 300) ? Colors.white : Colors.grey.shade500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: isJoining
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.videocam_rounded, size: 20),
                label: Text(
                  isJoining ? "Connecting..." : ((isLive || secsUntil <= 300) ? "Join Video Call" : "Starts soon"),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: (isJoining || !(isLive || secsUntil <= 300)) ? null : () => _joinSession(session),
              ),
            ),
          ],
        ),
      ),
    );
  }
}