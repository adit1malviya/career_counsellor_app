import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mentor_service.dart';
import 'video_call_screen.dart';

class MentorScheduleScreen extends StatefulWidget {
  const MentorScheduleScreen({super.key});

  @override
  State<MentorScheduleScreen> createState() => _MentorScheduleScreenState();
}

class _MentorScheduleScreenState extends State<MentorScheduleScreen> with SingleTickerProviderStateMixin {
  final MentorService _service = MentorService();
  late TabController _tabController;

  List<dynamic> _upcomingSessions = [];
  bool _isLoadingSessions = true;

  List<dynamic> _pendingRequests = [];
  bool _isLoadingRequests = true;

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
    ]);
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoadingSessions = true);
    final data = await _service.getUpcomingSessions();
    if (mounted) setState(() { _upcomingSessions = data; _isLoadingSessions = false; });
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    final data = await _service.getPendingConnectionRequests();
    if (mounted) setState(() { _pendingRequests = data; _isLoadingRequests = false; });
  }

  // ── Accept/Reject Connections ──────────────────────────────────────────────

  Future<void> _handleConnection(Map<String, dynamic> req, bool isAccept) async {
    final String reqId = req['request_id']?.toString() ?? '';
    if (reqId.isEmpty) return;

    final backup = List.from(_pendingRequests);
    setState(() => _pendingRequests.removeWhere((r) => r['request_id'] == req['request_id']));

    final success = isAccept
        ? await _service.acceptConnectionRequest(reqId)
        : await _service.rejectConnectionRequest(reqId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAccept ? '✅ Connection approved!' : '❌ Connection rejected.'),
        backgroundColor: isAccept ? Colors.green : Colors.red,
      ));
      _loadAll();
    } else if (mounted) {
      setState(() => _pendingRequests = backup);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Action failed. Please try again.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ── Join video session (FIXED FOR MENTOR) ──────────────────────────────────

  Future<void> _joinSession(Map<String, dynamic> session) async {
    final String sessionId = session['session_id']?.toString() ?? session['id']?.toString() ?? '';
    if (sessionId.isEmpty) return;

    setState(() => _joiningSessionId = sessionId);

    // ✅ FIX 1: Tiny delay to ensure server/provider synchronization
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final result = await _service.joinVideoSession(sessionId);
      if (mounted) setState(() => _joiningSessionId = null);

      if (result != null && mounted) {
        final String dyteToken = result['token'] ?? '';
        if (dyteToken.isEmpty) return;

        // ✅ FIX 2: Standard push keeps this background logic alive
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoCallScreen(token: dyteToken)),
        );

        // This runs ONLY AFTER the mentor leaves the screen
        await _service.endVideoSession(sessionId);
        _loadAll();
      }
    } catch (e) {
      if (mounted) setState(() => _joiningSessionId = null);
      debugPrint("❌ Join Error: $e");
    }
  }

  // ── Delete Session ─────────────────────────────────────────────────────────

  Future<void> _deleteSession(String sessionId) async {
    final success = await _service.deleteBroadcast(sessionId);
    if (success) {
      _loadAll();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Broadcast removed.")));
    }
  }

  // ── Create Broadcast Sheet ─────────────────────────────────────────────────

  void _showBroadcastSheet() {
    final TextEditingController topicController = TextEditingController(text: "Open Mentorship Session");
    int delayMinutes = 0;
    bool isSaving = false;

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
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 25),
                const Row(
                  children: [
                    Icon(Icons.sensors_rounded, color: Colors.redAccent, size: 28),
                    SizedBox(width: 10),
                    Text('Go Live', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Broadcast a session to all your connected students.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),

                const Text('Topic', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    hintText: "e.g. Q&A about Software Engineering",
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('When?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FB), borderRadius: BorderRadius.circular(14)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: delayMinutes,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("Instant (Live Now)")),
                        DropdownMenuItem(value: 15, child: Text("In 15 Minutes")),
                        DropdownMenuItem(value: 60, child: Text("In 1 Hour")),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheet(() => delayMinutes = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : () async {
                      if (topicController.text.trim().isEmpty) return;
                      setSheet(() => isSaving = true);

                      final result = await _service.broadcastSession(topicController.text.trim(), delayMinutes);

                      if (mounted) Navigator.pop(ctx);

                      if (result != null && mounted) {
                        // ✅ Auto-Join if instant
                        if (delayMinutes == 0) {
                          _joinSession(result);
                        } else {
                          _loadAll();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.mentor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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
        onPressed: _showBroadcastSheet,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.sensors_rounded, color: Colors.white),
        label: const Text('Go Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          _buildSliverAppBar(),
          SliverPersistentHeader(
            delegate: _TabBarDelegate(TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.mentor,
              labelColor: AppTheme.mentor,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: _pendingRequests.isEmpty ? 'CONNECTIONS' : 'CONNECTIONS (${_pendingRequests.length})'),
                const Tab(text: 'MY BROADCASTS'),
              ],
            )),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [_buildRequestsTab(), _buildUpcomingTab()],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF4F7F6),
      elevation: 0,
      pinned: true,
      title: const Text('Mentor Dashboard', style: TextStyle(color: Color(0xFF1A2138), fontWeight: FontWeight.w900, fontSize: 22)),
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.mentor), onPressed: _loadAll)],
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) return const Center(child: CircularProgressIndicator(color: AppTheme.mentor));
    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchPendingRequests,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 60),
          Center(child: Column(children: [
            Icon(Icons.people_alt_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No pending connection requests', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ])),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchPendingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _pendingRequests.length,
        itemBuilder: (_, i) => _buildRequestCard(_pendingRequests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final String studentName = req['student_name'] ?? 'Student';
    final String message = req['message'] ?? 'Wants to connect';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.mentor.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(radius: 26, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${req['student_id']}')),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(studentName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 4),
          Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])),
        GestureDetector(
          onTap: () => _handleConnection(req, true),
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.green, size: 22)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _handleConnection(req, false),
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 22)),
        ),
      ]),
    );
  }

  Widget _buildUpcomingTab() {
    if (_isLoadingSessions) return const Center(child: CircularProgressIndicator(color: AppTheme.mentor));
    if (_upcomingSessions.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchSessions,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 60),
          Center(child: Column(children: [
            Icon(Icons.sensors_off_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No active broadcasts', style: TextStyle(color: Colors.grey, fontSize: 15)),
          ])),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchSessions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        itemCount: _upcomingSessions.length,
        itemBuilder: (_, i) => _buildSessionCard(_upcomingSessions[i]),
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final bool isLive = session['is_live'] == true;
    final int secsUntil = session['seconds_until_start'] ?? 99999;
    final String sessionId = session['session_id']?.toString() ?? session['id']?.toString() ?? '';
    final bool isJoining = _joiningSessionId == sessionId;
    final bool canJoin = isLive || secsUntil <= 300;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isLive ? AppTheme.mentor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(session['topic'] ?? "Broadcast Session", style: TextStyle(color: isLive ? Colors.white : Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? Colors.white.withValues(alpha: 0.2) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isLive ? 'LIVE NOW' : (secsUntil < 3600 ? 'In ${secsUntil ~/ 60} min' : 'In ${secsUntil ~/ 3600}h'),
                  style: TextStyle(color: isLive ? Colors.white : Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ])),
            IconButton(
              icon: Icon(Icons.delete_outline, color: isLive ? Colors.white70 : Colors.grey),
              onPressed: () => _deleteSession(sessionId),
            )
          ]),
        ),
        if (canJoin) InkWell(
          onTap: isJoining ? null : () => _joinSession(session),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isLive ? Colors.white.withValues(alpha: 0.15) : AppTheme.mentor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Center(child: isJoining
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('ENTER STUDIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ])),
          ),
        ),
      ]),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: Colors.white, child: tabBar);
  @override bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}