import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'water_counter_screen.dart';
import 'sleep_counter_screen.dart';
import 'calorie_counter_screen.dart';
import 'habit_tracker_screen.dart';
import 'mini_challenges_screen.dart';
import 'enhanced_mood_tracker_screen.dart';
import 'smart_reminders_screen.dart';
import 'goal_selection_screen.dart';
import 'habits_screen.dart';
import 'advanced_analytics_screen.dart';
import 'simple_reports_screen.dart';

/// Hauptdashboard-Bildschirm der Lebenshygiene-Anwendung
/// 
/// Zeigt eine umfassende Übersicht über alle wichtigen Gesundheitsmetriken:
/// - Schritte, Wasseraufnahme, Schlaf, Kalorien
/// - Fortschrittsbalken für alle Ziele
/// - Schnellzugriff auf alle Tracking-Funktionen
/// - Tägliche Statistiken und Trends
/// 
/// Der Bildschirm lädt Daten aus Firestore und bietet
/// eine intuitive Benutzeroberfläche für die Gesundheitsüberwachung.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// State-Klasse für den Dashboard-Bildschirm
/// 
/// Verwaltet alle Gesundheitsdaten, Ziele und Animationen.
/// Implementiert Firestore-Integration für Datenpersistierung
/// und bietet eine reaktive Benutzeroberfläche mit
/// Fade- und Slide-Animationen.
class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  int _steps = 0;
  int _stepsGoal = 10000;
  double _water = 1.2; // in Litern
  double _waterGoal = 2.0;
  double _sleep = 7.0; // in Stunden
  double _sleepGoal = 8.0;
  int _kcal = 1200;
  int _kcalGoal = 2000;
  double _weight = 66.0;
  double _height = 170.0;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _loadUserGoals();
    _loadDailyData(_selectedDate);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _kcalGoal = (data['zielKcal'] ?? 2000) is int ? data['zielKcal'] : int.tryParse(data['zielKcal'].toString()) ?? 2000;
        _sleepGoal = (data['zielSleep'] ?? 8.0) is double ? data['zielSleep'] : double.tryParse(data['zielSleep'].toString()) ?? 8.0;
        _waterGoal = (data['zielWater'] ?? 2.0) is double ? data['zielWater'] : double.tryParse(data['zielWater'].toString()) ?? 2.0;
        _stepsGoal = (data['zielSteps'] ?? 10000) is int ? data['zielSteps'] : int.tryParse(data['zielSteps'].toString()) ?? 10000;
      });
    }
  }

  Future<void> _loadDailyData(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    
    // Réinitialiser les données si c'est un nouveau jour
    if (!doc.exists && DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now())) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .set({
        'steps': 0,
        'water': 0.0,
        'sleep': 0.0,
        'kcal': 0,
        'date': dateStr,
      });
    }

    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _steps = (data['steps'] ?? 0) as int;
        _water = (data['water'] ?? 0.0).toDouble();
        _sleep = (data['sleep'] ?? 0.0).toDouble();
        _kcal = (data['kcal'] ?? 0) as int;
        _weight = (data['weight'] ?? 0.0).toDouble();
        _height = (data['height'] ?? 0.0).toDouble();
      });
      // Si le poids est manquant ou null, le charger depuis le profil utilisateur
      if ((data['weight'] == null || data['weight'] == 0.0)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (!mounted) return;
          setState(() {
            _weight = (userData['weight'] ?? 66.0).toDouble();
          });
        }
      }
      // Si la taille est manquante ou null, la charger depuis le profil utilisateur
      if ((data['height'] == null || data['height'] == 0.0)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (!mounted) return;
          setState(() {
            _height = (userData['height'] ?? 170.0).toDouble();
          });
        }
      }
    } else {
      if (!mounted) return;
      setState(() {
        _steps = 0;
        _water = 0.0;
        _sleep = 0.0;
        _kcal = 0;
      });
      // Charger la taille et le poids depuis le profil utilisateur
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (!mounted) return;
        setState(() {
          _height = (userData['height'] ?? 170.0).toDouble();
          _weight = (userData['weight'] ?? 66.0).toDouble();
        });
      }
    }
  }

  double _calculateBMI() {
    if (_height > 0 && _weight > 0) {
      double heightInMeters = _height / 100;
      return _weight / (heightInMeters * heightInMeters);
    }
    return 0.0;
  }

  String _bmiStatus(double bmi) {
    if (bmi < 18.5) return 'Untergewicht';
    if (bmi < 25) return 'Normalgewicht';
    if (bmi < 30) return 'Übergewicht';
    return 'Adipositas';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(),
                      const SizedBox(height: 30),
                      _buildMainStatsCard(),
                      const SizedBox(height: 30),
                      _buildQuickActionsSection(),
                      const SizedBox(height: 30),
                      _buildHealthMetricsSection(),
                      const SizedBox(height: 30),
                      _buildCategoriesSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoalSelectionScreen(),
                ),
              );
            },
            tooltip: 'Ziele',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
                await _loadDailyData(picked);
              }
            },
            tooltip: 'Kalender',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF16213e),
            Color(0xFF0f172a),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hallo! 👋',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wie läuft dein Tag?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('dd. MMMM yyyy').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.self_improvement,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Deine heutigen Fortschritte',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: (_steps / _stepsGoal).clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: Color(0xFF667eea),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_steps / _stepsGoal * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_steps Schritte',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            progressColor: const Color(0xFF667eea),
            backgroundColor: Colors.white.withOpacity(0.1),
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniProgressIndicator(
                'Wasser',
                _water,
                _waterGoal,
                const Color(0xFF4facfe),
                Icons.water_drop,
                'L',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WaterCounterScreen()),
                ).then((_) => _loadDailyData(_selectedDate)),
              ),
              _buildMiniProgressIndicator(
                'Schlaf',
                _sleep,
                _sleepGoal,
                const Color(0xFF43e97b),
                Icons.bedtime,
                'h',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SleepCounterScreen()),
                ).then((_) => _loadDailyData(_selectedDate)),
              ),
              _buildMiniProgressIndicator(
                'Kalorien',
                _kcal.toDouble(),
                _kcalGoal.toDouble(),
                const Color(0xFFfa709a),
                Icons.local_fire_department,
                'kcal',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalorieCounterScreen()),
                ).then((_) => _loadDailyData(_selectedDate)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProgressIndicator(
    String label,
    double value,
    double goal,
    Color color,
    IconData icon,
    String unit,
    VoidCallback onTap,
  ) {
    final percentage = (value / goal).clamp(0.0, 1.0);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isSmallScreen ? 120 : 140, // Hauteur adaptative
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon, 
                color: color, 
                size: isSmallScreen ? 20 : 24
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Container(
              width: 60,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}/$goal $unit',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: isSmallScreen ? 9 : 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Schnellzugriff',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Gewohnheiten',
                Icons.check_circle_outline,
                const Color(0xFF667eea),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HabitsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildQuickActionCard(
                'Stimmung',
                Icons.sentiment_satisfied_alt,
                const Color(0xFF764ba2),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EnhancedMoodTrackerScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                'Berichte',
                Icons.assessment,
                const Color(0xFFff9a9e),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SimpleReportsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildQuickActionCard(
                'Mini Herausforderungen',
                Icons.analytics,
                const Color(0xFF43e97b),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MiniChallengesScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gesundheitsmetriken',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthMetric(
                'Gewicht',
                '${_weight.toStringAsFixed(1)} kg',
                Icons.monitor_weight,
                const Color(0xFFff9a9e),
              ),
              _buildHealthMetric(
                'Größe',
                '${_height.toStringAsFixed(0)} cm',
                Icons.height,
                const Color(0xFFa8edea),
              ),
              _buildHealthMetric(
                'BMI',
                _calculateBMI().toStringAsFixed(1),
                Icons.calculate,
                const Color(0xFFfad0c4),
                subtitle: _bmiStatus(_calculateBMI()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color, {String? subtitle}) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    final categories = [
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weitere Features',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        ...categories.map((category) => Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: _buildCategoryTile(
            category['icon'] as IconData,
            category['title'] as String,
            category['color'] as Color,
            category['onTap'] as VoidCallback,
          ),
        )),
      ],
    );
  }

  Widget _buildCategoryTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFF2d3748),
              const Color(0xFF1a202c),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}