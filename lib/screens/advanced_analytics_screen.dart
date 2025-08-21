import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';
import '../models/gamification_model.dart' as gamification;
import '../services/report_service.dart';
import '../services/gamification_service.dart';
import 'dart:math' as math;

/// Erweiterte Analysen-Bildschirm für detaillierte Gesundheitsstatistiken
/// 
/// Bietet umfassende Funktionalitäten für:
/// - Detaillierte Gesundheitsberichte und -analysen
/// - Gamification-Statistiken und Badges
/// - Tab-basierte Navigation zwischen verschiedenen Analysetypen
/// - Integration mit Report- und Gamification-Services
/// - Wöchentliche Berichtsgenerierung
/// - Fortschrittsverfolgung und Erfolgsmetriken
/// 
/// Der Bildschirm bietet eine zentrale Plattform für
/// alle erweiterten Analysen und Statistiken.
class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

/// State-Klasse für den erweiterten Analysen-Bildschirm
/// 
/// Verwaltet Berichtsdaten, Gamification-Informationen und Tab-Navigation.
/// Implementiert Service-Integration für Berichte und Gamification,
/// Tab-Controller für verschiedene Analysetypen,
/// Paralleles Laden von Daten für optimale Performance.
/// Bietet eine umfassende Übersicht über alle
/// Gesundheitsmetriken und Erfolge.
class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen>
    with TickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  final GamificationService _gamificationService = GamificationService();
  
  late TabController _tabController;
  bool _isLoading = true;
  
  // Berichtsdaten
  List<PersonalizedReport> _reports = [];
  
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
          'Mini Herausforderungen',
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
            // Tab(text: 'Vorhersagen'),
            // Tab(text: 'Fortschritt'),
            // Tab(text: 'Badges'),
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
                // _buildPredictionsTab(),
                // _buildProgressTab(),
                // _buildBadgesTab(),
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
            // Detaillierte Metriken
            // _buildDetailedMetrics(),
          ],
        ),
      ),
    );
  }

      // Hilfsfunktionen
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