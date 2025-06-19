import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import 'dart:math' as math;

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Wöchentlichen Bericht generieren
  Future<PersonalizedReport> generateWeeklyReport() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: now.weekday - 1));
    final endDate = startDate.add(const Duration(days: 6));

    return await _generateReport(user.uid, startDate, endDate, 'weekly');
  }

  // Monatlichen Bericht generieren
  Future<PersonalizedReport> generateMonthlyReport() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    return await _generateReport(user.uid, startDate, endDate, 'monthly');
  }

  Future<PersonalizedReport> _generateReport(
    String userId,
    DateTime startDate,
    DateTime endDate,
    String period,
  ) async {
    // Alle Daten für den Zeitraum sammeln
    final metrics = await _collectMetrics(userId, startDate, endDate);
    final insights = await _generateInsights(metrics, period);
    final recommendations = await _generateRecommendations(metrics, insights);

    final report = PersonalizedReport(
      id: '',
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      metrics: metrics.toMap(),
      insights: insights.toMap(),
      recommendations: recommendations,
      createdAt: DateTime.now(),
    );

    // Bericht speichern
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('reports')
        .add(report.toFirestore());

    return PersonalizedReport(
      id: docRef.id,
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      metrics: metrics.toMap(),
      insights: insights.toMap(),
      recommendations: recommendations,
      createdAt: DateTime.now(),
    );
  }

  Future<ReportMetrics> _collectMetrics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Wasserdaten sammeln
    final waterData = await _getWaterData(userId, startDate, endDate);
    
    // Schrittdaten sammeln
    final stepsData = await _getStepsData(userId, startDate, endDate);
    
    // Schlafdaten sammeln
    final sleepData = await _getSleepData(userId, startDate, endDate);
    
    // Kaloriendaten sammeln
    final caloriesData = await _getCaloriesData(userId, startDate, endDate);
    
    // Stimmungsdaten sammeln
    final moodData = await _getMoodData(userId, startDate, endDate);
    
    // Gewohnheitsdaten sammeln
    final habitData = await _getHabitData(userId, startDate, endDate);

    return ReportMetrics(
      waterIntake: _calculateAverage(waterData),
      steps: _calculateAverage(stepsData),
      sleepHours: _calculateAverage(sleepData),
      calories: _calculateAverage(caloriesData),
      moodAverage: _calculateAverage(moodData),
      habitCompletionRate: habitData['completionRate'] ?? 0.0,
      totalHabits: habitData['totalHabits'] ?? 0,
      completedHabits: habitData['completedHabits'] ?? 0,
      stressLevel: _calculateAverage(moodData.map((m) => 5 - m).toList()), // Umkehrung der Stimmung
      energyLevel: _calculateAverage(moodData),
    );
  }

  Future<List<double>> _getWaterData(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['water'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getStepsData(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['steps'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getSleepData(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['sleep'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getCaloriesData(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['kcal'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getMoodData(String userId, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['level'] ?? 3.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<Map<String, dynamic>> _getHabitData(String userId, DateTime startDate, DateTime endDate) async {
    // Gesamte Gewohnheiten zählen
    final habitsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .get();

    final totalHabits = habitsSnapshot.docs.length;
    int completedHabits = 0;
    int totalDays = 0;

    // Abschlussrate für jeden Tag berechnen
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_status')
          .doc(dateStr)
          .get();

      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        final completedCount = data.values.where((value) => value == true).length;
        completedHabits += completedCount;
        totalDays++;
      }
    }

    final completionRate = totalDays > 0 ? completedHabits / (totalHabits * totalDays) : 0.0;

    return {
      'totalHabits': totalHabits,
      'completedHabits': completedHabits,
      'completionRate': completionRate,
    };
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<ReportInsights> _generateInsights(ReportMetrics metrics, String period) async {
    final achievements = <String>[];
    final challenges = <String>[];

    // Wasser analysieren
    if (metrics.waterIntake >= 2.0) {
      achievements.add('Ausgezeichnete Hydratation (${metrics.waterIntake.toStringAsFixed(1)}L/Tag)');
    } else if (metrics.waterIntake < 1.5) {
      challenges.add('Unzureichende Hydratation (${metrics.waterIntake.toStringAsFixed(1)}L/Tag)');
    }

    // Schritte analysieren
    if (metrics.steps >= 8000) {
      achievements.add('Ausgezeichnete körperliche Aktivität (${metrics.steps.toStringAsFixed(0)} Schritte/Tag)');
    } else if (metrics.steps < 5000) {
      challenges.add('Geringe körperliche Aktivität (${metrics.steps.toStringAsFixed(0)} Schritte/Tag)');
    }

    // Schlaf analysieren
    if (metrics.sleepHours >= 7.0) {
      achievements.add('Optimaler Schlaf (${metrics.sleepHours.toStringAsFixed(1)}h/Nacht)');
    } else if (metrics.sleepHours < 6.0) {
      challenges.add('Unzureichender Schlaf (${metrics.sleepHours.toStringAsFixed(1)}h/Nacht)');
    }

    // Stimmung analysieren
    if (metrics.moodAverage >= 4.0) {
      achievements.add('Ausgezeichnete Stimmung (${metrics.moodAverage.toStringAsFixed(1)}/5)');
    } else if (metrics.moodAverage < 3.0) {
      challenges.add('Stimmung verbesserungsbedürftig (${metrics.moodAverage.toStringAsFixed(1)}/5)');
    }

    // Gewohnheiten analysieren
    if (metrics.habitCompletionRate >= 0.8) {
      achievements.add('Ausgezeichnete Beständigkeit bei Gewohnheiten (${(metrics.habitCompletionRate * 100).toStringAsFixed(0)}%)');
    } else if (metrics.habitCompletionRate < 0.5) {
      challenges.add('Beständigkeit bei Gewohnheiten verbesserungsbedürftig (${(metrics.habitCompletionRate * 100).toStringAsFixed(0)}%)');
    }

    // Gesamttrend bestimmen
    final overallTrend = _determineOverallTrend(metrics);
    
    // Beste und schlechteste Metriken bestimmen
    final bestMetric = _determineBestMetric(metrics);
    final worstMetric = _determineWorstMetric(metrics);
    final improvementArea = _determineImprovementArea(metrics);

    return ReportInsights(
      overallTrend: overallTrend,
      bestMetric: bestMetric,
      worstMetric: worstMetric,
      improvementArea: improvementArea,
      achievements: achievements,
      challenges: challenges,
    );
  }

  String _determineOverallTrend(ReportMetrics metrics) {
    int positiveCount = 0;
    int totalCount = 0;

    if (metrics.waterIntake >= 2.0) positiveCount++;
    if (metrics.steps >= 8000) positiveCount++;
    if (metrics.sleepHours >= 7.0) positiveCount++;
    if (metrics.moodAverage >= 4.0) positiveCount++;
    if (metrics.habitCompletionRate >= 0.8) positiveCount++;

    totalCount = 5;

    final percentage = positiveCount / totalCount;

    if (percentage >= 0.8) return 'Ausgezeichnet';
    if (percentage >= 0.6) return 'Gut';
    if (percentage >= 0.4) return 'Mittel';
    return 'Verbesserungsbedürftig';
  }

  String _determineBestMetric(ReportMetrics metrics) {
    final scores = {
      'Hydratation': metrics.waterIntake / 2.5,
      'Aktivität': metrics.steps / 10000,
      'Schlaf': metrics.sleepHours / 8.0,
      'Stimmung': metrics.moodAverage / 5.0,
      'Gewohnheiten': metrics.habitCompletionRate,
    };

    final best = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
    return best.key;
  }

  String _determineWorstMetric(ReportMetrics metrics) {
    final scores = {
      'Hydratation': metrics.waterIntake / 2.5,
      'Aktivität': metrics.steps / 10000,
      'Schlaf': metrics.sleepHours / 8.0,
      'Stimmung': metrics.moodAverage / 5.0,
      'Gewohnheiten': metrics.habitCompletionRate,
    };

    final worst = scores.entries.reduce((a, b) => a.value < b.value ? a : b);
    return worst.key;
  }

  String _determineImprovementArea(ReportMetrics metrics) {
    final scores = {
      'Hydratation': metrics.waterIntake / 2.5,
      'Aktivität': metrics.steps / 10000,
      'Schlaf': metrics.sleepHours / 8.0,
      'Stimmung': metrics.moodAverage / 5.0,
      'Gewohnheiten': metrics.habitCompletionRate,
    };

    final worst = scores.entries.reduce((a, b) => a.value < b.value ? a : b);
    return worst.key;
  }

  Future<Map<String, dynamic>> _generateRecommendations(ReportMetrics metrics, ReportInsights insights) async {
    final recommendations = <String>[];

    // Empfehlungen basierend auf Metriken
    if (metrics.waterIntake < 2.0) {
      recommendations.add('Erhöhen Sie Ihre Wasseraufnahme auf 2L pro Tag');
    }

    if (metrics.steps < 8000) {
      recommendations.add('Gehen Sie mindestens 8000 Schritte pro Tag');
    }

    if (metrics.sleepHours < 7.0) {
      recommendations.add('Schlafen Sie 7-9 Stunden pro Nacht für bessere Erholung');
    }

    if (metrics.moodAverage < 4.0) {
      recommendations.add('Praktizieren Sie Meditation oder entspannende Aktivitäten');
    }

    if (metrics.habitCompletionRate < 0.8) {
      recommendations.add('Konzentrieren Sie sich auf 2-3 Prioritätsgewohnheiten');
    }

    // Empfehlungen basierend auf Insights
    if (insights.improvementArea.isNotEmpty) {
      recommendations.add('Priorisieren Sie die Verbesserung Ihrer ${insights.improvementArea.toLowerCase()}');
    }

    return {
      'general': recommendations,
      'priority': insights.improvementArea.isNotEmpty ? [insights.improvementArea] : [],
      'nextWeek': _generateNextWeekGoals(metrics),
    };
  }

  List<String> _generateNextWeekGoals(ReportMetrics metrics) {
    final goals = <String>[];

    if (metrics.waterIntake < 2.0) {
      goals.add('2L Wasser pro Tag erreichen');
    }

    if (metrics.steps < 8000) {
      goals.add('8000 Schritte pro Tag erreichen');
    }

    if (metrics.sleepHours < 7.0) {
      goals.add('Mindestens 7h pro Nacht schlafen');
    }

    if (metrics.habitCompletionRate < 0.8) {
      goals.add('80% Beständigkeit bei Gewohnheiten beibehalten');
    }

    return goals;
  }

  // Alle Berichte eines Benutzers abrufen
  Future<List<PersonalizedReport>> getUserReports() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PersonalizedReport.fromFirestore(doc))
        .toList();
  }

  // Bericht als gelesen markieren
  Future<void> markReportAsRead(String reportId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reports')
        .doc(reportId)
        .update({'isRead': true});
  }
} 