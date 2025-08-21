import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Einfache Berichte-Bildschirm für grundlegende Gesundheitsstatistiken
/// 
/// Bietet Funktionalitäten für:
/// - Wöchentliche Gesundheitsberichte
/// - Monatliche Gesundheitsberichte
/// - Aggregierte Statistiken für Schritte, Wasser, Schlaf und Kalorien
/// - Einfache Datenvisualisierung
/// - Integration mit dem täglichen Daten-Tracking
/// - Übersichtliche Darstellung der wichtigsten Metriken
/// 
/// Der Bildschirm bietet eine benutzerfreundliche Übersicht
/// über grundlegende Gesundheitsstatistiken.
class SimpleReportsScreen extends StatefulWidget {
  const SimpleReportsScreen({super.key});

  @override
  State<SimpleReportsScreen> createState() => _SimpleReportsScreenState();
}

/// State-Klasse für den einfachen Berichte-Bildschirm
/// 
/// Verwaltet Wochen- und Monatsdaten, Statistiken und Ladezustände.
/// Implementiert Firestore-Integration für Datenaggregation,
/// Zeitraum-basierte Datenberechnung,
/// Einfache Statistik-Berechnungen für verschiedene Metriken.
/// Bietet eine übersichtliche Darstellung der
/// wichtigsten Gesundheitsdaten.
class _SimpleReportsScreenState extends State<SimpleReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _weeklyData = {};
  Map<String, dynamic> _monthlyData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Charger les données de la semaine
      await _loadWeeklyData(user.uid);
      
      // Charger les données du mois
      await _loadMonthlyData(user.uid);
      
    } catch (e) {
      debugPrint('Fehler beim Laden der Berichtsdaten: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadWeeklyData(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    Map<String, dynamic> weeklyStats = {
      'steps': 0,
      'water': 0.0,
      'sleep': 0.0,
      'kcal': 0,
      'days': 0,
    };

    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyData')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        weeklyStats['steps'] += (data['steps'] ?? 0) as int;
        weeklyStats['water'] += (data['water'] ?? 0.0).toDouble();
        weeklyStats['sleep'] += (data['sleep'] ?? 0.0).toDouble();
        weeklyStats['kcal'] += (data['kcal'] ?? 0) as int;
        weeklyStats['days'] += 1;
      }
    }

    setState(() => _weeklyData = weeklyStats);
  }

  Future<void> _loadMonthlyData(String userId) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    
    Map<String, dynamic> monthlyStats = {
      'steps': 0,
      'water': 0.0,
      'sleep': 0.0,
      'kcal': 0,
      'days': 0,
    };

    for (int i = 0; i < now.day; i++) {
      final date = monthStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyData')
          .doc(dateStr)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        monthlyStats['steps'] += (data['steps'] ?? 0) as int;
        monthlyStats['water'] += (data['water'] ?? 0.0).toDouble();
        monthlyStats['sleep'] += (data['sleep'] ?? 0.0).toDouble();
        monthlyStats['kcal'] += (data['kcal'] ?? 0) as int;
        monthlyStats['days'] += 1;
      }
    }

    setState(() => _monthlyData = monthlyStats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Einfache Berichte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF43e97b)),
            )
          : RefreshIndicator(
              onRefresh: _loadReportData,
              color: const Color(0xFF43e97b),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeeklyReport(),
                    const SizedBox(height: 24),
                    _buildMonthlyReport(),
                    const SizedBox(height: 24),
                    _buildSummaryCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklyReport() {
    final avgSteps = _weeklyData['days'] > 0 ? (_weeklyData['steps'] / _weeklyData['days']).round() : 0;
    final avgWater = _weeklyData['days'] > 0 ? (_weeklyData['water'] / _weeklyData['days']) : 0.0;
    final avgSleep = _weeklyData['days'] > 0 ? (_weeklyData['sleep'] / _weeklyData['days']) : 0.0;
    final avgKcal = _weeklyData['days'] > 0 ? (_weeklyData['kcal'] / _weeklyData['days']).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Wöchentlicher Bericht',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Durchschnittswerte dieser Woche',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetricCard(
                  'Schritte',
                  '$avgSteps',
                  'pro Tag',
                  Icons.directions_walk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetricCard(
                  'Wasser',
                  '${avgWater.toStringAsFixed(1)}L',
                  'pro Tag',
                  Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetricCard(
                  'Schlaf',
                  '${avgSleep.toStringAsFixed(1)}h',
                  'pro Nacht',
                  Icons.bedtime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetricCard(
                  'Kalorien',
                  '$avgKcal',
                  'pro Tag',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReport() {
    final avgSteps = _monthlyData['days'] > 0 ? (_monthlyData['steps'] / _monthlyData['days']).round() : 0;
    final avgWater = _monthlyData['days'] > 0 ? (_monthlyData['water'] / _monthlyData['days']) : 0.0;
    final avgSleep = _monthlyData['days'] > 0 ? (_monthlyData['sleep'] / _monthlyData['days']) : 0.0;
    final avgKcal = _monthlyData['days'] > 0 ? (_monthlyData['kcal'] / _monthlyData['days']).round() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFfa709a), Color(0xFFfee140)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Monatlicher Bericht',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Durchschnittswerte diesen Monat',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetricCard(
                  'Schritte',
                  '$avgSteps',
                  'pro Tag',
                  Icons.directions_walk,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetricCard(
                  'Wasser',
                  '${avgWater.toStringAsFixed(1)}L',
                  'pro Tag',
                  Icons.water_drop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetricCard(
                  'Schlaf',
                  '${avgSleep.toStringAsFixed(1)}h',
                  'pro Nacht',
                  Icons.bedtime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetricCard(
                  'Kalorien',
                  '$avgKcal',
                  'pro Tag',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetricCard(String title, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: const Color(0xFF43e97b), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Zusammenfassung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Aktive Tage',
            '${_weeklyData['days']}/7 Tage',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Gesamte Schritte',
            '${_weeklyData['steps']} Schritte',
            Icons.directions_walk,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Gesamte Kalorien',
            '${_weeklyData['kcal']} kcal',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 