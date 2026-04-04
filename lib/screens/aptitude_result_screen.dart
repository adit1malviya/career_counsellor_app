import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AptitudeResultScreen extends StatelessWidget {
  final Map<String, dynamic> questions;
  final Map<String, dynamic> userAnswers;

  const AptitudeResultScreen({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    int totalScore = 0;
    List<Widget> reviewList = [];

    userAnswers.forEach((id, markedLetter) {
      final qData = questions[id];
      final rawText = qData['text'] ?? "";

      // 1. Extract Correct Letter (e.g., "C")
      final correctMatch = RegExp(r"Correct Answer: ([A-D])").firstMatch(rawText);
      final String correctLetter = correctMatch?.group(1) ?? "";

      // 2. Extract Option Texts (Mapping A, B, C, D to their actual descriptions)
      final optionsMap = _parseOptions(rawText);

      // 3. Get Full Text for what user marked and what was correct
      String markedText = optionsMap[markedLetter] ?? markedLetter;
      String correctText = optionsMap[correctLetter] ?? correctLetter;

      bool isCorrect = markedLetter.toString().toUpperCase() == correctLetter;
      if (isCorrect) totalScore++;

      reviewList.add(_buildResultCard(rawText, markedText, correctText, isCorrect));
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: const Text("APTITUDE RESULTS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        backgroundColor: AppTheme.student,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildScoreHeader(totalScore, userAnswers.length),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: reviewList,
            ),
          ),
          _buildContinueButton(context),
        ],
      ),
    );
  }

  // ✅ HELPER: Extracts the actual text for each option
  Map<String, String> _parseOptions(String rawText) {
    final Map<String, String> options = {};
    final cleaned = rawText.replaceAll('\n', ' ');

    final a = RegExp(r"A\) (.*?)(?=B\)|$)").firstMatch(cleaned)?.group(1)?.trim();
    final b = RegExp(r"B\) (.*?)(?=C\)|$)").firstMatch(cleaned)?.group(1)?.trim();
    final c = RegExp(r"C\) (.*?)(?=D\)|$)").firstMatch(cleaned)?.group(1)?.trim();
    final d = RegExp(r"D\) (.*?)(?=Correct|Explanation|$)").firstMatch(cleaned)?.group(1)?.trim();

    if (a != null) options["A"] = a;
    if (b != null) options["B"] = b;
    if (c != null) options["C"] = c;
    if (d != null) options["D"] = d;

    return options;
  }

  Widget _buildScoreHeader(int score, int total) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        children: [
          const Text("TOTAL SCORE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          Text("$score / $total", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppTheme.student)),
          const SizedBox(height: 5),
          Text(score >= (total/2) ? "Excellent Achievement!" : "Good Effort! Keep Practicing.",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResultCard(String rawText, String markedText, String correctText, bool isCorrect) {
    final qMatch = RegExp(r"Question: (.*?)(?=A\)|$)").firstMatch(rawText.replaceAll('\n', ' '));
    final displayQ = qMatch?.group(1)?.trim() ?? "Question";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isCorrect ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
            width: 1.5
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(displayQ, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.4)),
          const SizedBox(height: 16),

          // ✅ MARKED ANSWER
          _answerRow("You marked:", markedText, isCorrect ? Colors.green : Colors.red, isCorrect ? Icons.check_circle : Icons.cancel),

          const SizedBox(height: 8),

          // ✅ CORRECT ANSWER (Only show if user was wrong)
          if (!isCorrect)
            _answerRow("Correct answer:", correctText, Colors.green, Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _answerRow(String label, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.7))),
                Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.student,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 5,
          shadowColor: AppTheme.student.withOpacity(0.3),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text("CONTINUE TO NEXT PHASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}