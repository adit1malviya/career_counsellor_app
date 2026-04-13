import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';
import 'video_call_screen.dart';

// ─── Day-of-week helper ───────────────────────────────────────────────────────

const List<String> _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const List<String> _dayFull  = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

// ─── Screen ───────────────────────────────────────────────────────────────────

class MentorScheduleScreen extends StatefulWidget {
  const MentorScheduleScreen({super.key});

  @override
  State<MentorScheduleScreen> createState() => _MentorScheduleScreenState();
}

class _MentorScheduleScreenState extends State<MentorScheduleScreen>
    with SingleTickerProviderStateMixin {
  final MentorService _service = MentorService();

  // ── Tab controller ─────────────────────────────────────────────────────────
  late TabController _tabController;

  // ── Upcoming sessions ──────────────────────────────────────────────────────
  List<dynamic> _upcomingSessions = [];
  bool _isLoadingSessions = true;

  // ── Pending session requests ───────────────────────────────────────────────
  List<dynamic> _pendingRequests = [];
  bool _isLoadingRequests = true;

  // ── Availability slots (Raw from DB) ───────────────────────────────────────
  List<dynamic> _mySlots = [];
  bool _isLoadingSlots = true;
  bool _isSlotsExpanded = false;

  // ── Date UI state ──────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();

  // ── Join VC loading state ──────────────────────────────────────────────────
  String? _joiningSessionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchSessions(),
      _fetchPendingRequests(),
      _fetchMySlots(), // This populates the "My Availability" bar
    ]);
  }

  Future<void> _fetchMySlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);

    // ✅ Logic: Pass "me" to the service to fetch the logged-in mentor's UUID availability
    try {
      final data = await _service.getMentorAvailability("me");
      if (mounted) {
        setState(() {
          _mySlots = data;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching mentor slots: $e");
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoadingSessions = true);
    final data = await _service.getUpcomingSessions();
    if (mounted) setState(() {
      _upcomingSessions = data;
      _isLoadingSessions = false;
    });
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    final data = await _service.getPendingSessionRequests();
    if (mounted) setState(() {
      _pendingRequests = data;
      _isLoadingRequests = false;
    });
  }

  // ── Approve a session request ──────────────────────────────────────────────

  Future<void> _handleApprove(Map<String, dynamic> req) async {
    final String reqId = req['request_id']?.toString() ?? '';
    if (reqId.isEmpty) return;

    final backup = List.from(_pendingRequests);
    setState(() =>
        _pendingRequests.removeWhere((r) => r['request_id'] == req['request_id']));

    final result = await _service.approveSessionRequest(reqId);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Session approved for ${req['student_name'] ?? 'student'}!"),
          backgroundColor: Colors.green,
        ),
      );
      _loadAll(); // Re-fetch to update "Booked" status in the status bar
    } else {
      if (mounted) {
        setState(() => _pendingRequests = backup);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to approve. Please try again."),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Join video session ─────────────────────────────────────────────────────

  Future<void> _joinSession(Map<String, dynamic> session) async {
    final String sessionId = session['session_id']?.toString() ?? '';
    if (sessionId.isEmpty) return;

    setState(() => _joiningSessionId = sessionId);

    final result = await _service.joinVideoSession(sessionId);

    if (mounted) setState(() => _joiningSessionId = null);

    if (result != null && mounted) {
      final String dyteToken = result['token'] ?? '';

      // ✅ AWAIT the video call screen. Code pauses here while the VC is active.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(token: dyteToken),
        ),
      );

      // ✅ Hit the backend to complete the session once they return to this screen
      await _service.endVideoSession(sessionId);

      // ✅ Refresh the mentor's dashboard to reflect the completed session
      _loadAll();

    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Could not start session. Please try again."),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Set availability ───────────────────────────────────────────────────────

  void _showAddAvailabilitySheet() {
    int selectedDay = DateTime.now().weekday;
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    // ✅ Automatically default to 1 hour later
    TimeOfDay endTime   = const TimeOfDay(hour: 10, minute: 0);
    bool _isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 25),
                const Text("Set Your Availability",
                    style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                    "Select a start time. Each slot is strictly 1 hour long.",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                _buildInputLabel("Day of Week"),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final isSelected = selectedDay == day;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.mentor
                                : const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? AppTheme.mentor
                                    : Colors.grey.shade200),
                          ),
                          child: Text(
                            _dayNames[day],
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInputLabel("Start Time"),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final t = await showTimePicker(
                                  context: ctx, initialTime: startTime);
                              if (t != null) {
                                setSheet(() {
                                  startTime = t;
                                  // ✅ Automatically calculate end time (1 hour later)
                                  endTime = TimeOfDay(hour: (t.hour + 1) % 24, minute: t.minute);
                                });
                              }
                            },
                            child: _buildTimeBox(startTime),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Updated label to show it's fixed
                          _buildInputLabel("End Time (1 hr fixed)"),
                          const SizedBox(height: 8),
                          // ✅ Removed the GestureDetector so the user CANNOT click and change it!
                          Opacity(
                            opacity: 0.6, // Makes it look "disabled" or "read-only"
                            child: _buildTimeBox(endTime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                      final String start =
                          "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00";
                      final String end =
                          "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00";

                      if (selectedDay == DateTime.now().weekday) {
                        if (startTime.hour <= DateTime.now().hour) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Today's slots must start at least 1 hour from now.")),
                          );
                          return;
                        }
                      }

                      setSheet(() => _isSaving = true);

                      final success =
                      await _service.setAvailability([
                        {
                          "day_of_week": selectedDay,
                          "start_time": start,
                          "end_time": end,
                        }
                      ]);

                      if (mounted) Navigator.pop(ctx);

                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "✅ Availability set for ${_dayFull[selectedDay]}!"),
                            backgroundColor: AppTheme.mentor,
                          ),
                        );
                        _loadAll(); // Added refresh
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  "Failed to save availability. Check time ranges."),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mentor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : const Text("Save Availability",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAvailabilitySheet,
        backgroundColor: AppTheme.mentor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Set Availability",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(),
          _buildDateHeader(),
          // --- Availability Status Bar ---
          SliverToBoxAdapter(
            child: _buildAvailabilityStatusBar(),
          ),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.mentor,
                labelColor: AppTheme.mentor,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(
                    text: _pendingRequests.isEmpty
                        ? "REQUESTS"
                        : "REQUESTS  (${_pendingRequests.length})",
                  ),
                  const Tab(text: "UPCOMING"),
                ],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildUpcomingTab(),
          ],
        ),
      ),
    );
  }

  // ── Availability Status Bar Logic ──────────────────────────────────────────

  Widget _buildAvailabilityStatusBar() {
    final int freeCount = _mySlots.where((s) => s['is_booked'] == false).length;
    final int bookedCount = _mySlots.where((s) => s['is_booked'] == true).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isSlotsExpanded = !_isSlotsExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.mentor, size: 20),
                    const SizedBox(width: 12),
                    const Text("My Availability", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Icon(_isSlotsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
          if (_isSlotsExpanded) ...[
            const SizedBox(height: 16),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_mySlots.isEmpty)
              const Text("No slots created yet", style: TextStyle(color: Colors.grey, fontSize: 12))
            else
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mySlots.length,
                  itemBuilder: (context, index) {
                    final slot = _mySlots[index];
                    final bool isBooked = slot['is_booked'] ?? false;
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBooked ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isBooked ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_dayNames[slot['day_of_week']], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          Text(slot['start_time'].toString().substring(0, 5), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(isBooked ? "BOOKED" : "FREE",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isBooked ? Colors.orange : Colors.green)),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip("${freeCount} Free", Colors.green),
                const SizedBox(width: 10),
                _buildStatusChip("${bookedCount} Booked", Colors.orange),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  // ── Existing Helper UI ─────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF4F7F6),
      elevation: 0,
      pinned: true,
      title: const Text("My Schedule",
          style: TextStyle(
              color: Color(0xFF1A2138),
              fontWeight: FontWeight.w900,
              fontSize: 22)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppTheme.mentor),
          onPressed: _loadAll,
        ),
      ],
    );
  }

  Widget _buildDateHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20)
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_monthName(_selectedDate.month)} ${_selectedDate.year}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 18),
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppTheme.mentor.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.mentor, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final day = _selectedDate
                    .subtract(Duration(days: _selectedDate.weekday - 1))
                    .add(Duration(days: i));
                final isToday = day.day == DateTime.now().day &&
                    day.month == DateTime.now().month;
                final isSelected = day.day == _selectedDate.day &&
                    day.month == _selectedDate.month;

                return Column(
                  children: [
                    Text(
                      _dayNames[i + 1],
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.mentor
                            : (isToday
                            ? AppTheme.mentor.withValues(alpha: 0.12)
                            : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "${day.day}",
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isToday
                                ? AppTheme.mentor
                                : Colors.black87),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.mentor));
    }
    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPendingRequests,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No pending session requests",
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, i) => _buildRequestCard(_pendingRequests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final String studentName = req['student_name'] ?? "Student";
    final String timeSlot    = req['time_slot'] ?? "—";
    final String reqId       = req['request_id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border:
        Border.all(color: AppTheme.mentor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=${req['student_id']}'),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(timeSlot,
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: reqId.isEmpty ? null : () => _handleApprove(req),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle),
              child:
              const Icon(Icons.check_rounded, color: Colors.green, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _pendingRequests
                .removeWhere((r) => r['request_id'] == req['request_id'])),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.close_rounded,
                  color: Colors.redAccent, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoadingSessions) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.mentor));
    }
    if (_upcomingSessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchSessions,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(Icons.event_available_rounded,
                      size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No upcoming sessions",
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _upcomingSessions.length,
        itemBuilder: (context, i) =>
            _buildSessionCard(_upcomingSessions[i]),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final bool isLive = session['is_live'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: isLive ? AppTheme.mentor : Colors.white, borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        title: Text(session['other_party_name'] ?? 'Student', style: TextStyle(color: isLive ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        subtitle: Text(session['scheduled_at'].toString(), style: TextStyle(color: isLive ? Colors.white70 : Colors.grey)),
        trailing: isLive ? const Icon(Icons.videocam_rounded, color: Colors.white) : null,
        onTap: isLive ? () => _joinSession(session) : null,
      ),
    );
  }

  Widget _buildInputLabel(String label) => Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13));
  Widget _buildTimeBox(TimeOfDay t) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), const Icon(Icons.access_time_rounded, color: AppTheme.mentor, size: 18)]));
  String _monthName(int m) => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m];
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: tabBar);
  @override bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}