import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';
import 'student_schedule_screen.dart';

class StudentSessionScreen extends StatefulWidget {
  final String mentorProfileId; // Mentor TABLE primary key
  final String mentorUserId;    // User TABLE id (for avatar)
  final String mentorName;

  const StudentSessionScreen({
    super.key,
    required this.mentorProfileId,
    required this.mentorUserId,
    required this.mentorName,
  });

  @override
  State<StudentSessionScreen> createState() => _StudentSessionScreenState();
}

class _StudentSessionScreenState extends State<StudentSessionScreen> {
  final MentorService _service = MentorService();
  final TextEditingController _messageController = TextEditingController();

  bool _isRequesting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  // ── Send Connection Request ────────────────────────────────────────────────

  Future<void> _sendRequest() async {
    setState(() => _isRequesting = true);

    final success = await _service.sendConnectionRequest(
      widget.mentorProfileId,
      _messageController.text.trim(),
    );

    if (mounted) setState(() => _isRequesting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Connection request sent to mentor!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back after success
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to send request. You may have already requested this mentor."),
          backgroundColor: Colors.redAccent,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.mentorUserId}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mentorName,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text("Connect", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.student),
            tooltip: "My Schedule",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentScheduleScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Header Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.student.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_tethering_rounded, size: 64, color: AppTheme.student),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              "Join ${widget.mentorName}'s Network",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A2138)),
            ),
            const SizedBox(height: 12),

            // Explanation Text
            const Text(
              "Connect with this mentor to unlock access to their live mentorship broadcasts. Once connected, their sessions will appear directly in your schedule!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Message Input Field
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Send an introductory message (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Hi! I would love to connect and learn from your upcoming live sessions.",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.student, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.student,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isRequesting
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                  "Send Connection Request",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}