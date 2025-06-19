import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class TrendPrediction {
  final String metric;
  final double currentValue;
  final double predictedValue;
  final double confidence;
  final String trend; // 'increasing', 'decreasing', 'stable'
  final String recommendation;

  TrendPrediction({
    required this.metric,
    required this.currentValue,
    required this.predictedValue,
    required this.confidence,
    required this.trend,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'metric': metric,
      'currentValue': currentValue,
      'predictedValue': predictedValue,
      'confidence': confidence,
      'trend': trend,
      'recommendation': recommendation,
    };
  }

  factory TrendPrediction.fromMap(Map<String, dynamic> map) {
    return TrendPrediction(
      metric: map['metric'] ?? '',
      currentValue: (map['currentValue'] ?? 0.0).toDouble(),
      predictedValue: (map['predictedValue'] ?? 0.0).toDouble(),
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      trend: map['trend'] ?? 'stable',
      recommendation: map['recommendation'] ?? '',
    );
  }
}

class PredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 7-Tage-Trendvorhersagen generieren
  Future<List<TrendPrediction>> generate7DayPredictions() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final predictions = <TrendPrediction>[];

    // Wasservorhersage
    final waterPrediction = await _predictWaterTrend(user.uid);
    predictions.add(waterPrediction);

    // Schrittworhersage
    final stepsPrediction = await _predictStepsTrend(user.uid);
    predictions.add(stepsPrediction);

    // Schlafvorhersage
    final sleepPrediction = await _predictSleepTrend(user.uid);
    predictions.add(sleepPrediction);

    // Stimmungsvorhersage
    final moodPrediction = await _predictMoodTrend(user.uid);
    predictions.add(moodPrediction);

    // Gewohnheitsvorhersage
    final habitPrediction = await _predictHabitTrend(user.uid);
    predictions.add(habitPrediction);

    return predictions;
  }

  Future<TrendPrediction> _predictWaterTrend(String userId) async {
    final waterData = await _getWaterData(userId, 14); // 14 Tage Daten
    final currentAvg = _calculateAverage(waterData.take(7).toList());
    final predictedAvg = _predictNextValue(waterData);

    final trend = _determineTrend(currentAvg, predictedAvg);
    final confidence = _calculateConfidence(waterData);
    final recommendation = _getWaterRecommendation(trend, predictedAvg);

    return TrendPrediction(
      metric: 'Wasseraufnahme',
      currentValue: currentAvg,
      predictedValue: predictedAvg,
      confidence: confidence,
      trend: trend,
      recommendation: recommendation,
    );
  }

  Future<TrendPrediction> _predictStepsTrend(String userId) async {
    final stepsData = await _getStepsData(userId, 14);
    final currentAvg = _calculateAverage(stepsData.take(7).toList());
    final predictedAvg = _predictNextValue(stepsData);

    final trend = _determineTrend(currentAvg, predictedAvg);
    final confidence = _calculateConfidence(stepsData);
    final recommendation = _getStepsRecommendation(trend, predictedAvg);

    return TrendPrediction(
      metric: 'Schritte',
      currentValue: currentAvg,
      predictedValue: predictedAvg,
      confidence: confidence,
      trend: trend,
      recommendation: recommendation,
    );
  }

  Future<TrendPrediction> _predictSleepTrend(String userId) async {
    final sleepData = await _getSleepData(userId, 14);
    final currentAvg = _calculateAverage(sleepData.take(7).toList());
    final predictedAvg = _predictNextValue(sleepData);

    final trend = _determineTrend(currentAvg, predictedAvg);
    final confidence = _calculateConfidence(sleepData);
    final recommendation = _getSleepRecommendation(trend, predictedAvg);

    return TrendPrediction(
      metric: 'Schlaf',
      currentValue: currentAvg,
      predictedValue: predictedAvg,
      confidence: confidence,
      trend: trend,
      recommendation: recommendation,
    );
  }

  Future<TrendPrediction> _predictMoodTrend(String userId) async {
    final moodData = await _getMoodData(userId, 14);
    final currentAvg = _calculateAverage(moodData.take(7).toList());
    final predictedAvg = _predictNextValue(moodData);

    final trend = _determineTrend(currentAvg, predictedAvg);
    final confidence = _calculateConfidence(moodData);
    final recommendation = _getMoodRecommendation(trend, predictedAvg);

    return TrendPrediction(
      metric: 'Stimmung',
      currentValue: currentAvg,
      predictedValue: predictedAvg,
      confidence: confidence,
      trend: trend,
      recommendation: recommendation,
    );
  }

  Future<TrendPrediction> _predictHabitTrend(String userId) async {
    final habitData = await _getHabitData(userId, 14);
    final currentAvg = _calculateAverage(habitData.take(7).toList());
    final predictedAvg = _predictNextValue(habitData);

    final trend = _determineTrend(currentAvg, predictedAvg);
    final confidence = _calculateConfidence(habitData);
    final recommendation = _getHabitRecommendation(trend, predictedAvg);

    return TrendPrediction(
      metric: 'Gewohnheiten',
      currentValue: currentAvg,
      predictedValue: predictedAvg,
      confidence: confidence,
      trend: trend,
      recommendation: recommendation,
    );
  }

  Future<List<double>> _getWaterData(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['water'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getStepsData(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['steps'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getSleepData(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['sleep'] ?? 0.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getMoodData(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('timestamp')
        .get();

    return snapshot.docs
        .map((doc) => (doc.data()['level'] ?? 3.0).toDouble())
        .toList()
        .cast<double>();
  }

  Future<List<double>> _getHabitData(String userId, int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final habitRates = <double>[];

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
        final totalHabits = data.length;
        final completedHabits = data.values.where((value) => value == true).length;
        final rate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
        habitRates.add(rate);
      } else {
        habitRates.add(0.0);
      }
    }

    return habitRates;
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _predictNextValue(List<double> values) {
    if (values.length < 3) return values.isNotEmpty ? values.last : 0.0;

    // Einfache lineare Regression für Vorhersage
    final n = values.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    return slope * n + intercept;
  }

  String _determineTrend(double current, double predicted) {
    final change = predicted - current;
    final percentChange = current > 0 ? (change / current).abs() : 0.0;

    if (percentChange < 0.05) return 'stable';
    return change > 0 ? 'increasing' : 'decreasing';
  }

  double _calculateConfidence(List<double> values) {
    if (values.length < 3) return 0.5;

    // Konfidenz basierend auf Datenkonsistenz
    final mean = _calculateAverage(values);
    final variance = values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = math.sqrt(variance);
    final coefficientOfVariation = stdDev / mean;

    // Höhere Konfidenz bei geringerer Variation
    return math.max(0.3, 1.0 - coefficientOfVariation);
  }

  String _getWaterRecommendation(String trend, double predictedValue) {
    switch (trend) {
      case 'increasing':
        return 'Ausgezeichnet! Ihre Wasseraufnahme verbessert sich. Behalten Sie diese positive Entwicklung bei.';
      case 'decreasing':
        return 'Achten Sie darauf, Ihre Wasseraufnahme zu erhöhen. Ziel: 2L pro Tag.';
      default:
        if (predictedValue < 1.5) {
          return 'Versuchen Sie, Ihre Wasseraufnahme schrittweise zu erhöhen.';
        }
        return 'Ihre Wasseraufnahme ist stabil. Behalten Sie Ihr aktuelles Niveau bei.';
    }
  }

  String _getStepsRecommendation(String trend, double predictedValue) {
    switch (trend) {
      case 'increasing':
        return 'Großartig! Sie werden aktiver. Streben Sie 10.000 Schritte pro Tag an.';
      case 'decreasing':
        return 'Versuchen Sie, mehr Bewegung in Ihren Alltag zu integrieren.';
      default:
        if (predictedValue < 5000) {
          return 'Beginnen Sie mit kurzen Spaziergängen und steigern Sie schrittweise.';
        }
        return 'Ihre Aktivität ist stabil. Versuchen Sie, das Niveau zu halten.';
    }
  }

  String _getSleepRecommendation(String trend, double predictedValue) {
    switch (trend) {
      case 'increasing':
        return 'Perfekt! Ihr Schlaf verbessert sich. 7-9 Stunden sind optimal.';
      case 'decreasing':
        return 'Achten Sie auf eine regelmäßige Schlafenszeit und Schlafhygiene.';
      default:
        if (predictedValue < 6.0) {
          return 'Versuchen Sie, früher ins Bett zu gehen und Schlafroutinen zu etablieren.';
        }
        return 'Ihr Schlaf ist stabil. Behalten Sie Ihre Schlafgewohnheiten bei.';
    }
  }

  String _getMoodRecommendation(String trend, double predictedValue) {
    switch (trend) {
      case 'increasing':
        return 'Wunderbar! Ihre Stimmung verbessert sich. Bleiben Sie positiv.';
      case 'decreasing':
        return 'Praktizieren Sie Entspannungstechniken und suchen Sie soziale Kontakte.';
      default:
        if (predictedValue < 3.0) {
          return 'Konsultieren Sie einen Arzt, wenn die Stimmung anhält.';
        }
        return 'Ihre Stimmung ist stabil. Achten Sie auf positive Aktivitäten.';
    }
  }

  String _getHabitRecommendation(String trend, double predictedValue) {
    switch (trend) {
      case 'increasing':
        return 'Ausgezeichnet! Ihre Gewohnheiten werden konsistenter. Weiter so!';
      case 'decreasing':
        return 'Konzentrieren Sie sich auf 2-3 wichtige Gewohnheiten.';
      default:
        if (predictedValue < 0.5) {
          return 'Beginnen Sie mit einer einfachen Gewohnheit und bauen Sie darauf auf.';
        }
        return 'Ihre Gewohnheiten sind stabil. Versuchen Sie, das Niveau zu halten.';
    }
  }

  // Vorhersagen speichern
  Future<void> savePredictions(List<TrendPrediction> predictions) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final predictionsMap = {
      'userId': user.uid,
      'timestamp': Timestamp.now(),
      'predictions': predictions.map((p) => p.toMap()).toList(),
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .add(predictionsMap);
  }

  // Letzte Vorhersagen abrufen
  Future<List<TrendPrediction>> getLatestPredictions() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('predictions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final data = snapshot.docs.first.data();
    final predictionsList = data['predictions'] as List<dynamic>;

    return predictionsList
        .map((p) => TrendPrediction.fromMap(p as Map<String, dynamic>))
        .toList();
  }
} 