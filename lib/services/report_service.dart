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

    final report = PersonalizedReport(
      id: '',
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      period: period,
      metrics: metrics.toMap(),
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