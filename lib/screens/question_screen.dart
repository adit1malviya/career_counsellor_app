import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';

class QuestionScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;
  final String? currentClass;

  const QuestionScreen({
    super.key,
    required this.title,
    required this.data,
    this.currentClass,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final Map<String, dynamic> _answers = {};
  final AssessmentService _apiService = AssessmentService();
  bool _isSubmitting = false;

  final Map<String, Map<String, dynamic>> localConfigs = {
    "gender": {"type": "selection", "options": ["Male", "Female", "Non-binary", "Prefer not to say"]},
    "current_class": {
      "type": "selection",
      "options": ["6th", "7th", "8th", "9th", "10th", "11th", "12th", "College 1st Year", "College 2nd Year", "College 3rd Year"]
    },
    "school_type": {"type": "selection", "options": ["Government", "Private", "International", "Semi-Government"]},
    "medium_of_learning": {"type": "selection", "options": ["English", "Hindi", "Regional Language", "Mixed"]},
  };

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> rawQuestions = widget.data['questions'] ?? {};

    final Map<String, dynamic> configs = (rawQuestions['field_configs'] is Map)
        ? Map<String, dynamic>.from(rawQuestions['field_configs'])
        : (widget.data['field_configs'] is Map)
        ? Map<String, dynamic>.from(widget.data['field_configs'])
        : {};

    final questions = Map.fromEntries(
      rawQuestions.entries.where((e) =>
      e.key != "null" &&
          e.key.isNotEmpty &&
          e.value != null &&
          e.key != "field_configs"
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        backgroundColor: AppTheme.student,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              String key = questions.keys.elementAt(index);
              return _buildQuestionCard(key, questions[key], configs[key]);
            },
          ),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildSubmitBar()),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String key, dynamic value, Map<String, dynamic>? config) {
    String displayQuestion = "";
    List<String> parsedOptions = [];
    bool isAptitude = widget.title.toLowerCase() == "aptitude";
    String? category;

    if (value is Map && isAptitude) {
      String rawText = value['text'] ?? "";
      category = value['category'];

      final qMatch = RegExp(r"Question: (.*?)(?=A\)|$)").firstMatch(rawText.replaceAll('\n', ' '));
      displayQuestion = qMatch?.group(1)?.trim() ?? rawText;

      final a = RegExp(r"A\) (.*?)(?=B\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
      final b = RegExp(r"B\) (.*?)(?=C\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
      final c = RegExp(r"C\) (.*?)(?=D\)|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();
      final d = RegExp(r"D\) (.*?)(?=Correct|Explanation|$)").firstMatch(rawText.replaceAll('\n', ' '))?.group(1)?.trim();

      if (a != null && b != null && c != null && d != null) {
        parsedOptions = [a, b, c, d];
      }
    } else if (value is Map) {
      displayQuestion = value['text'] ?? "No question text";
    } else {
      displayQuestion = value.toString();
    }

    Map<String, dynamic>? finalConfig = config ?? localConfigs[key];
    String? backendType = finalConfig?['type'] ?? _inferTypeFromKey(key);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (category != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppTheme.student.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(color: AppTheme.student, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          Text(
            displayQuestion,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A2138), height: 1.5),
          ),
          const SizedBox(height: 20),

          if (isAptitude && parsedOptions.isNotEmpty)
            ...List.generate(4, (index) {
              String label = ["A", "B", "C", "D"][index];
              bool isSelected = _answers[key] == label;
              return GestureDetector(
                onTap: () => setState(() => _answers[key] = label),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.student.withOpacity(0.05) : const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.student : Colors.transparent, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: isSelected ? AppTheme.student : Colors.grey.shade300,
                        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          parsedOptions[index],
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? AppTheme.student : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })

          else if (backendType == "scale" || (value is Map && value.containsKey('trait')))
            _buildDynamicSlider(key, finalConfig)

          else if (backendType == "selection" || backendType == "boolean")
              DropdownButtonFormField<String>(
                decoration: _inputDecoration(),
                hint: const Text("Select option...", style: TextStyle(fontSize: 13)),
                items: (backendType == "boolean"
                    ? ["Yes", "No"]
                    : _getEffectiveOptions(displayQuestion, finalConfig))
                    .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                    .toList(),
                onChanged: (val) => setState(() => _answers[key] = val),
              )

            else
              TextField(
                keyboardType: backendType == "number" ? TextInputType.number : TextInputType.text,
                maxLines: backendType == "textarea" ? 4 : 1,
                decoration: _inputDecoration(hint: "Enter your answer..."),
                onChanged: (val) => _answers[key] = (backendType == "number") ? int.tryParse(val) : val,
              ),
        ],
      ),
    );
  }

  String _inferTypeFromKey(String key) {
    if (key.contains("gender") || key.contains("class") || key.contains("school") || key.contains("medium")) {
      return "selection";
    }
    return "text";
  }

  Widget _buildDynamicSlider(String key, Map<String, dynamic>? config) {
    double maxVal = (config?['max'] ?? 5).toDouble();
    double minVal = (config?['min'] ?? 1).toDouble();
    double currentVal = (_answers[key] ?? ((maxVal + minVal) / 2).round()).toDouble();

    return Column(
      children: [
        Slider(
          value: currentVal,
          min: minVal,
          max: maxVal,
          divisions: (maxVal - minVal).toInt(),
          activeColor: AppTheme.student,
          onChanged: (val) => setState(() => _answers[key] = val.toInt()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sliderLabel(maxVal > 5 ? "Min" : "Strongly\nDisagree"),
              if (maxVal <= 5) _sliderLabel("Neutral"),
              _sliderLabel(maxVal > 5 ? "Max" : "Strongly\nAgree"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sliderLabel(String text) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
  );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8F9FB),
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade100),
    ),
  );

  List<String> _getEffectiveOptions(String label, Map<String, dynamic>? config) {
    if (config != null && config.containsKey('options')) return List<String>.from(config['options']);
    return ["Option 1", "Option 2"];
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.student,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: _isSubmitting ? null : _handleFinalSubmit,
        child: _isSubmitting
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Text("SUBMIT ASSESSMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  // ✅ KEY CHANGE: Returns Map with success + answers instead of just bool
  // inside _QuestionScreenState in ques_screen.dart

  void _handleFinalSubmit() async {
    // ✅ 1. Get total count of actual questions (excluding metadata)
    final rawQuestions = widget.data['questions'] ?? {};
    final totalQuestions = rawQuestions.entries.where((e) =>
    e.key != "null" && e.key.isNotEmpty && e.value != null && e.key != "field_configs"
    ).length;

    // ✅ 2. Validate: Answers count must match total questions
    if (_answers.length < totalQuestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please answer all $totalQuestions questions before submitting."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      bool success = await _apiService.submitAnswers(widget.title, _answers);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          // ✅ 3. Return results to parent
          Navigator.pop(context, {
            "success": true,
            "answers": Map<String, dynamic>.from(_answers),
            "rawQuestions": rawQuestions, // Pass this back for scoring in Aptitude
          });
        } else {
          _showErrorSnackBar("Submission failed. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar("Error: $e");
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}