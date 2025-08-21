import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalizedReport {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final String period; // 'weekly', 'monthly'
  final Map<String, dynamic> metrics;
  final DateTime createdAt;
  final bool isRead;

  PersonalizedReport({
    required this.id,
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.period,
    required this.metrics,
    required this.createdAt,
    this.isRead = false,
  });

  factory PersonalizedReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PersonalizedReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      period: data['period'] ?? 'weekly',
      metrics: data['metrics'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'period': period,
      'metrics': metrics,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

class ReportMetrics {
  final double waterIntake;
  final double steps;
  final double sleepHours;
  final double calories;
  final double moodAverage;
  final double habitCompletionRate;
  final int totalHabits;
  final int completedHabits;
  final double stressLevel;
  final double energyLevel;

  ReportMetrics({
    required this.waterIntake,
    required this.steps,
    required this.sleepHours,
    required this.calories,
    required this.moodAverage,
    required this.habitCompletionRate,
    required this.totalHabits,
    required this.completedHabits,
    required this.stressLevel,
    required this.energyLevel,
  });

  factory ReportMetrics.fromMap(Map<String, dynamic> map) {
    return ReportMetrics(
      waterIntake: (map['waterIntake'] ?? 0.0).toDouble(),
      steps: (map['steps'] ?? 0.0).toDouble(),
      sleepHours: (map['sleepHours'] ?? 0.0).toDouble(),
      calories: (map['calories'] ?? 0.0).toDouble(),
      moodAverage: (map['moodAverage'] ?? 3.0).toDouble(),
      habitCompletionRate: (map['habitCompletionRate'] ?? 0.0).toDouble(),
      totalHabits: map['totalHabits'] ?? 0,
      completedHabits: map['completedHabits'] ?? 0,
      stressLevel: (map['stressLevel'] ?? 3.0).toDouble(),
      energyLevel: (map['energyLevel'] ?? 3.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterIntake': waterIntake,
      'steps': steps,
      'sleepHours': sleepHours,
      'calories': calories,
      'moodAverage': moodAverage,
      'habitCompletionRate': habitCompletionRate,
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'stressLevel': stressLevel,
      'energyLevel': energyLevel,
    };
  }
} 