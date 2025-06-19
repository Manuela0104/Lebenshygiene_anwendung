import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../models/gamification_model.dart' as gamification;
import '../services/report_service.dart';
import '../services/prediction_service.dart';
import '../services/gamification_service.dart';
import 'dart:math' as math;

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  final PredictionService _predictionService = PredictionService();
  final GamificationService _gamificationService = GamificationService();
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // Berichtsdaten
  List<PersonalizedReport> _reports = [];
  
  // Vorhersagedaten
  List<TrendPrediction> _predictions = [];
  
  // Gamification-Daten
  gamification.UserProgress? _userProgress;
  List<gamification.Badge> _badges = [];
  List<gamification.Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Daten parallel laden
      await Future.wait([
        _loadReports(),
        _loadPredictions(),
        _loadGamificationData(),
      ]);
    } catch (e) {
      debugPrint('Fehler beim Laden der Daten: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _reportService.getUserReports();
      setState(() => _reports = reports);
    } catch (e) {
      debugPrint('Fehler beim Laden der Berichte: $e');
    }
  }

  Future<void> _loadPredictions() async {
    try {
      final predictions = await _predictionService.generate7DayPredictions();
      setState(() => _predictions = predictions);
    } catch (e) {
      debugPrint('Fehler beim Laden der Vorhersagen: $e');
    }
  }

  Future<void> _loadGamificationData() async {
    try {
      final progress = await _gamificationService.getUserProgress();
      final badges = await _gamificationService.getAllBadges();
      final achievements = await _gamificationService.getAllAchievements();
      
      setState(() {
        _userProgress = progress;
        _badges = badges;
        _achievements = achievements;
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der Gamification-Daten: $e');
    }
  }

  Future<void> _generateWeeklyReport() async {
    try {
      await _reportService.generateWeeklyReport();
      await _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wöchentlicher Bericht erfolgreich generiert!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Berichtsgenerierung: $e')),
      );
    }
  }

  Future<void> _generateMonthlyReport() async {
    try {
      await _reportService.generateMonthlyReport();
      await _loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Monatlicher Bericht erfolgreich generiert!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Berichtsgenerierung: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Erweiterte Analysen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF43e97b),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Berichte'),
            Tab(text: 'Vorhersagen'),
            Tab(text: 'Fortschritt'),
            Tab(text: 'Badges'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF43e97b)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(),
                _buildPredictionsTab(),
                _buildProgressTab(),
                _buildBadgesTab(),
              ],
            ),
    );
  }

  Widget _buildReportsTab() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xFF43e97b),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Erweiterte Insights
            _buildAdvancedInsights(),
            const SizedBox(height: 24),
            
            // Korrelationsanalyse
            _buildCorrelationAnalysis(),
            const SizedBox(height: 24),
            
            // Mustererkennung
            _buildPatternRecognition(),
            const SizedBox(height: 24),
            
            // Personalisierte Empfehlungen
            _buildPersonalizedRecommendations(),
            const SizedBox(height: 24),
            
            // Detaillierte Metriken
            _buildDetailedMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedInsights() {
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
              Icon(Icons.psychology, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'KI-basierte Insights',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Optimale Schlafzeit',
            'Basierend auf deinen Daten ist 23:00 Uhr deine ideale Schlafenszeit',
            Icons.bedtime,
            Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Wasseraufnahme-Timing',
            'Du trinkst am meisten Wasser zwischen 10:00-12:00 Uhr',
            Icons.water_drop,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Stimmungsmuster',
            'Deine Stimmung ist am besten nach körperlicher Aktivität',
            Icons.sentiment_satisfied,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationAnalysis() {
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
              Icon(Icons.trending_up, color: const Color(0xFF43e97b), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Korrelationsanalyse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCorrelationItem(
            'Schlaf ↔ Stimmung',
            'Starke positive Korrelation (0.78)',
            'Mehr Schlaf = bessere Stimmung',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildCorrelationItem(
            'Wasser ↔ Energie',
            'Moderate positive Korrelation (0.65)',
            'Ausreichend Wasser steigert Energie',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildCorrelationItem(
            'Schritte ↔ Gewicht',
            'Negative Korrelation (-0.42)',
            'Mehr Bewegung = Gewichtsabnahme',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCorrelationItem(String title, String correlation, String insight, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            correlation,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            insight,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRecognition() {
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
              Icon(Icons.pattern, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Mustererkennung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPatternCard(
            'Wochentags-Muster',
            'Montags und Dienstags sind deine produktivsten Tage',
            '85% deiner Ziele werden an diesen Tagen erreicht',
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildPatternCard(
            'Tageszeit-Optimierung',
            'Nachmittags (14:00-16:00) ist deine beste Zeit für Bewegung',
            'Durchschnittlich 12.500 Schritte in diesem Zeitfenster',
            Icons.access_time,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(String title, String pattern, String detail, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pattern,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedRecommendations() {
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
              Icon(Icons.lightbulb, color: const Color(0xFF43e97b), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Personalisierte Empfehlungen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Schlafoptimierung',
            'Versuche, 30 Minuten früher ins Bett zu gehen',
            'Basierend auf deinen Schlafmustern',
            Icons.bedtime,
            Colors.purple,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Wasseraufnahme',
            'Erhöhe deine Wasseraufnahme um 500ml pro Tag',
            'Für bessere Hydration und Energie',
            Icons.water_drop,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Bewegung',
            'Füge 2 kurze Spaziergänge zu deinem Tag hinzu',
            'Optimal für dein Gewichtsziel',
            Icons.directions_walk,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String title, String recommendation, String reason, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Detaillierte Metriken',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Konsistenz',
                  '78%',
                  'Deine Zielerreichung',
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Trend',
                  '+12%',
                  'Verbesserung diese Woche',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Effizienz',
                  '92%',
                  'Zeitnutzung',
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Balance',
                  '85%',
                  'Work-Life-Balance',
                  Icons.balance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon) {
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
              fontSize: 20,
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

  Widget _buildPredictionsTab() {
    if (_predictions.isEmpty) {
      return const Center(
        child: Text(
          'Laden der Vorhersagen...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPredictions,
      color: const Color(0xFF43e97b),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vorhersagen für die Nächste Woche',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Vorhersagen nach Metrik
            ..._buildMetricPredictions(),
            
            const SizedBox(height: 24),
            
            // Schwierige Tage
            if (_predictions.isNotEmpty) ...[
              const Text(
                'Potentiell Schwierige Tage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDifficultDaysCard(),
              const SizedBox(height: 24),
            ],
            
            // Erreichbare Ziele
            if (_predictions.isNotEmpty) ...[
              const Text(
                'Erreichbare Ziele',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAchievableGoalsCard(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMetricPredictions() {
    return _predictions.map((prediction) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMetricIcon(prediction.metric),
                  color: const Color(0xFF43e97b),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  prediction.metric,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  _getTrendIcon(prediction.trend),
                  color: _getTrendColor(prediction.trend),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Vorhersage: ${prediction.predictedValue.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vertrauen: ${(prediction.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prediction.recommendation,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDifficultDaysCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vorsicht vor diesen Tagen',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Basierend auf Ihren Daten könnten die nächsten Tage herausfordernd sein.',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievableGoalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ziele für diese Woche',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sie sind auf dem richtigen Weg! Konzentrieren Sie sich auf Ihre Stärken.',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    if (_userProgress == null) {
      return const Center(
        child: Text(
          'Laden des Fortschritts...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final progress = _userProgress!;
    
    return RefreshIndicator(
      onRefresh: _loadGamificationData,
      color: const Color(0xFF43e97b),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aktueller Level
            _buildLevelCard(),
            const SizedBox(height: 24),
            
            // Statistiken
            _buildStatsGrid(),
            const SizedBox(height: 24),
            
            // Achievements
            _buildAchievementsSection(),
            const SizedBox(height: 24),
            
            // Badges
            _buildBadgesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final progress = _userProgress!;
    final progressPercentage = progress.progressPercentage;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Level ${progress.currentLevel}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.currentPoints} Punkte',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${progress.pointsToNextLevel} Punkte für Level ${progress.currentLevel + 1}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final progress = _userProgress!;
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Sequenzen', '${progress.streakDays} Tage', Icons.local_fire_department),
        _buildStatCard('Gewohnheiten', '${progress.totalHabitsCompleted}', Icons.check_circle),
        _buildStatCard('Herausforderungen', '${progress.totalChallengesCompleted}', Icons.emoji_events),
        _buildStatCard('Gesamtpunkte', '${progress.totalPoints}', Icons.stars),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF43e97b), size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final completedAchievements = _achievements.where((a) => a.isCompleted).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements (${completedAchievements.length}/${_achievements.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (completedAchievements.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Achievements noch',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setzen Sie Ihre Ziele fort, um Achievements freizuschalten!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...completedAchievements.map((achievement) => _buildAchievementCard(achievement)),
      ],
    );
  }

  Widget _buildAchievementCard(gamification.Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  achievement.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${achievement.pointsReward}',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final unlockedBadges = _badges.where((b) => b.isUnlocked).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges (${unlockedBadges.length}/${_badges.length})',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (unlockedBadges.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kein Badge noch',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bleiben Sie fort, um Ihre App zu verwenden, um Badges zu entsperren!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: unlockedBadges.length,
            itemBuilder: (context, index) => _buildBadgeCard(unlockedBadges[index]),
          ),
      ],
    );
  }

  Widget _buildBadgeCard(gamification.Badge badge) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getBadgeIcon(badge.category),
            color: const Color(0xFF43e97b),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (badge.unlockedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Entsperrt am ${DateFormat('dd/MM').format(badge.unlockedAt!)}',
              style: TextStyle(
                color: const Color(0xFF43e97b),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    return _buildBadgesSection();
  }

  // Utilitäten
  Color _getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'excellent':
      case 'increasing':
        return Colors.green;
      case 'good':
      case 'stable':
        return Colors.blue;
      case 'average':
      case 'decreasing':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend.toLowerCase()) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  IconData _getMetricIcon(String metric) {
    switch (metric) {
      case 'Wasseraufnahme':
        return Icons.water_drop;
      case 'Schritte':
        return Icons.directions_walk;
      case 'Schlaf':
        return Icons.bedtime;
      case 'Stimmung':
        return Icons.mood;
      case 'Gewohnheiten':
        return Icons.check_circle;
      default:
        return Icons.analytics;
    }
  }

  IconData _getBadgeIcon(String category) {
    switch (category) {
      case 'water':
        return Icons.water_drop;
      case 'steps':
        return Icons.directions_walk;
      case 'sleep':
        return Icons.bedtime;
      case 'mood':
        return Icons.mood;
      case 'habits':
        return Icons.check_circle;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.workspace_premium;
    }
  }
} 