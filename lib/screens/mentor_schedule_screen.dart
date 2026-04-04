import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MentorScheduleScreen extends StatefulWidget {
  const MentorScheduleScreen({super.key});

  @override
  State<MentorScheduleScreen> createState() => _MentorScheduleScreenState();
}

class _MentorScheduleScreenState extends State<MentorScheduleScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      // 1. FAB FOR ADDING SCHEDULE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSessionSheet(context),
        backgroundColor: AppTheme.mentor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),

          // 2. MODERN HORIZONTAL DATE PICKER WITH "OPEN CALENDAR" ICON
          SliverToBoxAdapter(
            child: _buildEnhancedDateHeader(),
          ),

          // 3. THE SESSIONS LIST
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildTimelineItem(
                  time: "10:00 AM",
                  student: "Rohan Das",
                  topic: "Cybersecurity Roadmap",
                  isCompleted: true,
                ),
                _buildTimelineItem(
                  time: "04:30 PM",
                  student: "Alex",
                  topic: "UI/UX Case Study Review",
                  isLive: true,
                ),
                _buildTimelineItem(
                  time: "06:00 PM",
                  student: "Priya Sharma",
                  topic: "Portfolio Feedback",
                  isLocked: true,
                ),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- COMPONENT: SLIVER APP BAR ---
  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFFF4F7F6),
      elevation: 0,
      pinned: true,
      title: const Text("My Schedule", style: TextStyle(color: Color(0xFF1A2138), fontWeight: FontWeight.w900, fontSize: 22)),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.mentor),
          onPressed: () {}, // Filter options (Video calls only, etc.)
        ),
      ],
    );
  }

  // --- COMPONENT: ENHANCED DATE HEADER ---
  Widget _buildEnhancedDateHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("April 2026", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.mentor.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.calendar_month_rounded, color: AppTheme.mentor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Simple custom horizontal week view placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              bool isToday = index == 2;
              return Column(
                children: [
                  Text(["M", "T", "W", "T", "F", "S", "S"][index], style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: 35, height: 35,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.mentor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text("${index + 29}", style: TextStyle(color: isToday ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  // --- COMPONENT: THE ADD SESSION SHEET ---
  void _showAddSessionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            const Text("Schedule New Session", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            _buildInputLabel("Student Name"),
            TextField(decoration: _inputStyle("Select student...")),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Time"), TextField(decoration: _inputStyle("09:00 AM"))])),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildInputLabel("Duration"), TextField(decoration: _inputStyle("45 mins"))])),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mentor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text("Confirm Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildInputLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)));

  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint,
    filled: true, fillColor: const Color(0xFFF8F9FB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  );

  Widget _buildTimelineItem({required String time, required String student, required String topic, bool isLive = false, bool isCompleted = false, bool isLocked = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(time.split(" ")[0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(time.split(" ")[1], style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                Expanded(child: Container(width: 2, color: Colors.grey.withOpacity(0.2))),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLive ? AppTheme.mentor : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isLive ? [BoxShadow(color: AppTheme.mentor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))] : [],
                border: isCompleted ? Border.all(color: Colors.green.shade100) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(student, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isLive ? Colors.white : Colors.black)),
                      if (isCompleted) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(topic, style: TextStyle(color: isLive ? Colors.white70 : Colors.blueGrey, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}