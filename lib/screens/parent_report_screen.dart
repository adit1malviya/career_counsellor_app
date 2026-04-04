import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({super.key});

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  // 1. MAIN STATE VARIABLES
  String activeCategory = "Latest";
  String activeSort = "Latest Date";

  // 2. RAW DATA
  final List<Map<String, dynamic>> allReports = [
    {
      "title": "Career Pathing",
      "subtitle": "Backend Systems Focus",
      "date": "2026-03-28",
      "displayDate": "28 Mar",
      "mentor": "Dr. Sarah James",
      "avatar": "https://i.pravatar.cc/150?img=32",
      "category": "Technical",
      "duration": "45 min"
    },
    {
      "title": "Aptitude Review",
      "subtitle": "Logical Reasoning",
      "date": "2026-03-22",
      "displayDate": "22 Mar",
      "mentor": "Prof. Mike Wheeler",
      "avatar": "https://i.pravatar.cc/150?img=12",
      "category": "Aptitude",
      "duration": "60 min"
    },
    {
      "title": "Soft Skills",
      "subtitle": "Public Speaking",
      "date": "2026-03-15",
      "displayDate": "15 Mar",
      "mentor": "Maria Garcia",
      "avatar": "https://i.pravatar.cc/150?img=44",
      "category": "Soft Skills",
      "duration": "30 min"
    },
  ];

  // 3. LOGIC: FILTERING & SORTING ENGINE
  List<Map<String, dynamic>> get filteredReports {
    List<Map<String, dynamic>> list = List.from(allReports);

    // Filter by category
    if (activeCategory != "Latest") {
      list = list.where((r) => r['category'] == activeCategory).toList();
    }

    // Sort the filtered list
    if (activeSort == "Latest Date") {
      list.sort((a, b) => b['date'].compareTo(a['date']));
    } else if (activeSort == "Oldest") {
      list.sort((a, b) => a['date'].compareTo(b['date']));
    } else if (activeSort == "A-Z") {
      list.sort((a, b) => a['title'].compareTo(b['title']));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reportsToDisplay = filteredReports;

    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 70,
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFEDF1F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppTheme.parentTheme, size: 22),
                onPressed: () => _showSortSheet(context),
              ),
              const SizedBox(width: 8),
            ],
            centerTitle: true,
            title: const Text("Session Reports",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
          ),

          // Insights bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.parentTheme, Color(0xFF6A5AE0)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.parentTheme.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCompactStat("${allReports.length}", "Total"),
                    Container(width: 1, height: 18, color: Colors.white24),
                    _buildCompactStat("24", "Hours"),
                    Container(width: 1, height: 18, color: Colors.white24),
                    _buildCompactStat("03", "Mentors"),
                  ],
                ),
              ),
            ),
          ),

          // Filter Chips
          SliverToBoxAdapter(
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: ["Latest", "Technical", "Aptitude", "Soft Skills"].map((cat) => _buildFilterChip(cat)).toList(),
              ),
            ),
          ),

          // The List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: reportsToDisplay.isEmpty
                ? const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No reports found in this category", style: TextStyle(color: Colors.grey)),
            )))
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildPremiumCard(reportsToDisplay[index]),
                childCount: reportsToDisplay.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- SORTING SHEET ---
  void _showSortSheet(BuildContext context) {
    String tempSort = activeSort;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Sort By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),

                        // --- IMPROVED RESET BUTTON ---
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              activeSort = "Latest Date";
                              activeCategory = "Latest";
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Filters reset successfully"),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppTheme.parentTheme,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.parentTheme.withOpacity(0.1), // Soft purple background
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: AppTheme.parentTheme // Solid purple icon
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _buildMinimalOption("Latest Date", Icons.calendar_today_rounded, tempSort, (val) {
                          setSheetState(() => tempSort = val);
                        }),
                        const SizedBox(width: 12),
                        _buildMinimalOption("Oldest", Icons.history_rounded, tempSort, (val) {
                          setSheetState(() => tempSort = val);
                        }),
                        const SizedBox(width: 12),
                        _buildMinimalOption("A-Z", Icons.sort_by_alpha_rounded, tempSort, (val) {
                          setSheetState(() => tempSort = val);
                        }),
                      ],
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          activeSort = tempSort;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.parentTheme,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: const Text("Apply Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Widget _buildMinimalOption(String label, IconData icon, String currentTemp, Function(String) onSelect) {
    bool isSelected = currentTemp == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.parentTheme.withOpacity(0.08) : const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected ? AppTheme.parentTheme : Colors.transparent,
                width: 1.8
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isSelected ? AppTheme.parentTheme : Colors.blueGrey[300]),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected ? AppTheme.parentTheme : Colors.blueGrey[600]
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isActive = activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => activeCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.parentTheme : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.blueGrey.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildCompactStat(String val, String label) {
    return Row(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildPremiumCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppTheme.parentTheme.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 12))],
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.parentTheme.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                      child: Text(report['category'].toUpperCase(), style: const TextStyle(color: AppTheme.parentTheme, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                    Text(report['displayDate'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(report['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                Text(report['subtitle'], style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade400)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundImage: NetworkImage(report['avatar'])),
                    const SizedBox(width: 12),
                    Expanded(child: Text(report['mentor'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                    const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              border: Border(top: BorderSide(color: AppTheme.parentTheme.withOpacity(0.1), width: 1.5)),
            ),
            child: const Center(child: Text("VIEW FULL EVALUATION", style: TextStyle(color: AppTheme.parentTheme, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
          ),
        ],
      ),
    );
  }
}