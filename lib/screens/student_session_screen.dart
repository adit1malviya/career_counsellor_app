import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';
import 'student_schedule_screen.dart'; // ✅ Added import for the global schedule screen

/// Navigate here from MentorListScreen when the student taps "Request Session"
/// on a mentor in the MY MENTORS tab.
///
/// Required params:
///   mentorProfileId — Mentor.id (the mentor TABLE primary key, a UUID)
///   mentorUserId    — User.id of the mentor (used for avatar & chat)
///   mentorName      — Display name

class StudentSessionScreen extends StatefulWidget {
  final String mentorProfileId; // ← Mentor TABLE primary key
  final String mentorUserId;    // ← User TABLE id (for avatar)
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

  List<dynamic> _slots          = [];
  bool          _isLoadingSlots = true;

  String? _requestingSlotId;

  @override
  void initState() {
    super.initState();
    debugPrint(
        "🚀 StudentSessionScreen: mentorProfileId=${widget.mentorProfileId}, "
            "mentorUserId=${widget.mentorUserId}");
    _loadAll();
  }

  Future<void> _loadAll() async {
    await _fetchSlots();
  }

  // ── Fetch available slots for THIS mentor ──────────────────────────────────

  Future<void> _fetchSlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);

    // ✅ Pass mentor PROFILE id (Mentor.id), NOT user_id
    final data = await _service.getMentorAvailability(widget.mentorProfileId);

    if (mounted) {
      setState(() {
        _slots          = data;
        _isLoadingSlots = false;
      });
    }
  }

  // ── Book a slot ────────────────────────────────────────────────────────────

  Future<void> _requestSlot(Map<String, dynamic> slot) async {
    final String slotId = slot['id']?.toString() ?? '';
    if (slotId.isEmpty) return;

    setState(() => _requestingSlotId = slotId);

    // ✅ mentorId = Mentor.id (profile UUID), availabilityId = slot UUID
    final success = await _service.requestSession(
      mentorId:       widget.mentorProfileId,
      availabilityId: slotId,
      message:        "I would like to book this session.",
    );

    if (mounted) setState(() => _requestingSlotId = null);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text("✅ Request sent! Waiting for mentor approval."),
          backgroundColor: Colors.green,
        ),
      );
      _fetchSlots(); // slot disappears (now in pending state)
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Could not send request. Slot may be taken or already requested."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?u=${widget.mentorUserId}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.mentorName,
                      style: const TextStyle(
                          color:       Colors.black,
                          fontWeight:  FontWeight.bold,
                          fontSize:    16)),
                  const Text("Book a session",
                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✅ NEW: Button to view the student's global schedule
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.student),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.student),
            onPressed: _loadAll,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                  "Available Time Slots", Icons.calendar_month),
              const SizedBox(height: 4),
              const Text(
                "Tap Book to send a session request to the mentor.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _buildSlotsSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.student, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.bold,
                color:      Color(0xFF1A2138))),
      ],
    );
  }

  // ── Available slots ────────────────────────────────────────────────────────

  Widget _buildSlotsSection() {
    if (_isLoadingSlots) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppTheme.student),
          ));
    }
    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: Colors.grey.shade100)),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("No available slots right now.",
                style: TextStyle(
                    color:      Colors.grey,
                    fontSize:   14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text("Check back later or message your mentor.",
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }
    return Column(
        children:
        _slots.map<Widget>((s) => _buildSlotCard(s)).toList());
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    const List<String> days = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    final int    dayIdx      = (slot['day_of_week'] as int?)?.clamp(1, 7) ?? 1;
    final String rawStart    = slot['start_time']?.toString() ?? '00:00:00';
    final String rawEnd      = slot['end_time']?.toString() ?? '00:00:00';
    final String start       = rawStart.length >= 5 ? rawStart.substring(0, 5) : rawStart;
    final String end         = rawEnd.length   >= 5 ? rawEnd.substring(0, 5)   : rawEnd;
    final String slotId      = slot['id']?.toString() ?? '';
    final bool   isProcessing = _requestingSlotId == slotId;

    return Card(
      margin:     const EdgeInsets.only(bottom: 12),
      elevation:  0,
      color:      Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
              color: AppTheme.student.withValues(alpha: 0.15))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.student.withValues(alpha: 0.1),
          child: Text(days[dayIdx],
              style: const TextStyle(
                  color:      AppTheme.student,
                  fontSize:   11,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text("$start – $end",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(_fullDayName(dayIdx),
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isProcessing
                ? Colors.grey.shade300
                : AppTheme.student,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            elevation: 0,
          ),
          onPressed: isProcessing || slotId.isEmpty
              ? null
              : () => _requestSlot(slot),
          child: isProcessing
              ? const SizedBox(
              width:  15,
              height: 15,
              child:  CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
              : const Text("Book",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  String _fullDayName(int dayIdx) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return (dayIdx >= 1 && dayIdx <= 7) ? names[dayIdx] : '';
  }
}