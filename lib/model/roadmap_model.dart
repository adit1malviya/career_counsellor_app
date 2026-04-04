class CareerRoadmap {
  final String careerTitle;
  final String studentLevel;
  final String totalDuration;
  final String dailyCommitment;
  final List<RoadmapPhase> phases;

  CareerRoadmap({
    required this.careerTitle,
    required this.studentLevel,
    required this.totalDuration,
    required this.dailyCommitment,
    required this.phases,
  });

  factory CareerRoadmap.fromJson(Map<String, dynamic> json) {
    return CareerRoadmap(
      careerTitle: json['career_title'] ?? '',
      studentLevel: json['student_level'] ?? '',
      totalDuration: json['total_duration'] ?? '',
      dailyCommitment: json['daily_commitment'] ?? '',
      phases: (json['phases'] as List).map((i) => RoadmapPhase.fromJson(i)).toList(),
    );
  }
}

class RoadmapPhase {
  final int phaseNumber;
  final String phaseTitle;
  final String description;
  final List<String> skills;
  final List<WeeklyTask> weeklyBreakdown;

  RoadmapPhase({
    required this.phaseNumber,
    required this.phaseTitle,
    required this.description,
    required this.skills,
    required this.weeklyBreakdown,
  });

  factory RoadmapPhase.fromJson(Map<String, dynamic> json) {
    return RoadmapPhase(
      phaseNumber: json['phase_number'] ?? 0,
      phaseTitle: json['phase_title'] ?? '',
      description: json['description'] ?? '',
      skills: List<String>.from(json['skills_targeted'] ?? []),
      weeklyBreakdown: (json['weekly_breakdown'] as List).map((i) => WeeklyTask.fromJson(i)).toList(),
    );
  }
}

class WeeklyTask {
  final int weekNumber;
  final String topic;
  final List<String> tasks;
  final List<String> resources;

  WeeklyTask({required this.weekNumber, required this.topic, required this.tasks, required this.resources});

  factory WeeklyTask.fromJson(Map<String, dynamic> json) {
    return WeeklyTask(
      weekNumber: json['week_number'] ?? 0,
      topic: json['topic'] ?? '',
      tasks: List<String>.from(json['tasks'] ?? []),
      resources: List<String>.from(json['resources'] ?? []),
    );
  }
}