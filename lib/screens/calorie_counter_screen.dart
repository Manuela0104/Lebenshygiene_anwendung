import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Kalorienzähler-Bildschirm für die Überwachung der täglichen Kalorienaufnahme
/// 
/// Bietet Funktionalitäten für:
/// - Tägliche Kalorienaufnahme verfolgen
/// - Vergleich mit persönlichen Kalorienzielen
/// - Eingabe von Mahlzeiten und Snacks
/// - Fortschrittsanzeige und Statistiken
/// - Integration mit dem Benutzerprofil für personalisierte Ziele
/// 
/// Der Bildschirm speichert alle Daten in Firestore und
/// bietet eine animierte Benutzeroberfläche.
class CalorieCounterScreen extends StatefulWidget {
  const CalorieCounterScreen({super.key});

  @override
  State<CalorieCounterScreen> createState() => _CalorieCounterScreenState();
}

/// State-Klasse für den Kalorienzähler-Bildschirm
/// 
/// Verwaltet Kaloriendaten, Ziele und verschiedene Animationen.
/// Implementiert Firestore-Integration für Datenpersistierung,
/// Animationen für Fade, Scale und Counter-Effekte.
/// Bietet eine intuitive Benutzeroberfläche für die Kalorienverfolgung.
class _CalorieCounterScreenState extends State<CalorieCounterScreen> with TickerProviderStateMixin {
  double _calories = 0.0;
  int _kcalGoal = 2000;
  bool _loading = true;
  late AnimationController _animationController;
  late AnimationController _counterController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _counterAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _counterController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _counterAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.elasticOut,
    ));
    
    _loadGoalAndCalories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _counterController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalAndCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          final zielKcalRaw = userDoc.data()?['zielKcal'];
          int kcalGoal;
          if (zielKcalRaw is int) {
            kcalGoal = zielKcalRaw;
          } else if (zielKcalRaw is double) {
            kcalGoal = zielKcalRaw.toInt();
          } else if (zielKcalRaw != null) {
            kcalGoal = int.tryParse(zielKcalRaw.toString()) ?? 2000;
          } else {
            kcalGoal = 2000;
          }
          _kcalGoal = kcalGoal;
        });
      }
      
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final kcalDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .get();
      
      if (kcalDoc.exists) {
        setState(() {
          _calories = (kcalDoc.data()?['kcal'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden der Daten: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => _loading = false);
      _animationController.forward();
    }
  }

  Future<void> _saveCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .set({'kcal': _calories.round()}, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _updateCalories(double newCalories) {
    setState(() {
      _calories = newCalories.clamp(0.0, _kcalGoal * 1.5);
    });
    _counterController.forward().then((_) => _counterController.reverse());
    _saveCalories();
    
    if (_calories >= _kcalGoal * 0.95 && _calories <= _kcalGoal * 1.05) {
      _showSuccess();
    }
  }

  void _addCalories(int amount) {
    _updateCalories(_calories + amount);
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.restaurant, color: Colors.white),
            SizedBox(width: 8),
            Text('Super! Du bist nahe an deinem Kalorienziel! 🎯'),
          ],
        ),
        backgroundColor: const Color(0xFFfa709a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        color: Color(0xFFfa709a),
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 40 : 20),
                        child: Column(
                          children: [
                            _buildCalorieProgressCard(),
                            const SizedBox(height: 30),
                            _buildQuickAddSection(),
                            const SizedBox(height: 30),
                            _buildCalorieControls(),
                            const SizedBox(height: 30),
                            _buildNutritionTips(),
                            const SizedBox(height: 30),
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

  Widget _buildAppBar() {
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
              Color(0xFFfa709a),
              Color(0xFFfee140),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Kalorienzähler',
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
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalorieProgressCard() {
    final progress = (_calories / _kcalGoal).clamp(0.0, 1.0);
    final remaining = (_kcalGoal - _calories).clamp(0.0, _kcalGoal.toDouble());
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 30),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tägliches Kalorienziel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_kcalGoal kcal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 40 : 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: isTablet ? 200 : 150,
                height: isTablet ? 200 : 150,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: isTablet ? 15 : 12,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFfa709a)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              AnimatedBuilder(
                animation: _counterAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _counterAnimation.value,
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: const Color(0xFFfa709a),
                          size: isTablet ? 50 : 40,
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          '${_calories.round()}',
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            color: Colors.white.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: isTablet ? 30 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                'Fortschritt',
                '${(progress * 100).toInt()}%',
                Icons.trending_up,
                Colors.green,
                isTablet,
              ),
              _buildStatColumn(
                'Verbleibend',
                '${remaining.round()}',
                Icons.restaurant_menu,
                Colors.orange,
                isTablet,
              ),
              _buildStatColumn(
                'Überschuss',
                _calories > _kcalGoal ? '+${(_calories - _kcalGoal).round()}' : '0',
                Icons.warning,
                Colors.red,
                isTablet,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color, bool isTablet) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 12 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: isTablet ? 24 : 20),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isTablet ? 14 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
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
          Text(
            'Schnell hinzufügen',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxHeight < 600;
              final isVerySmallScreen = constraints.maxHeight < 500;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAddButton('Frühstück', 400, Icons.free_breakfast, const Color(0xFFfee140), isTablet, isSmallScreen, isVerySmallScreen),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 15),
                      Expanded(
                        child: _buildQuickAddButton('Mittagessen', 600, Icons.lunch_dining, const Color(0xFFfa709a), isTablet, isSmallScreen, isVerySmallScreen),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAddButton('Abendessen', 500, Icons.dinner_dining, const Color(0xFF43e97b), isTablet, isSmallScreen, isVerySmallScreen),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 15),
                      Expanded(
                        child: _buildQuickAddButton('Snack', 150, Icons.cookie, const Color(0xFF4facfe), isTablet, isSmallScreen, isVerySmallScreen),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(String label, int calories, IconData icon, Color color, bool isTablet, bool isSmallScreen, bool isVerySmallScreen) {
    return GestureDetector(
      onTap: () => _addCalories(calories),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : (isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12))),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                color: Colors.white, 
                size: isTablet ? 28 : (isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24))
              ),
              SizedBox(height: isTablet ? 8 : (isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 6))),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 14 : (isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 12)),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isTablet ? 4 : (isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 4))),
              Text(
                '+$calories kcal',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isTablet ? 12 : (isVerySmallScreen ? 7 : (isSmallScreen ? 8 : 10)),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieControls() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
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
          Text(
            'Manuelle Eingabe',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Row(
            children: [
              Expanded(
                child: _buildControlButton(
                  '-100',
                  Icons.remove,
                  Colors.red,
                  () => _updateCalories(_calories - 100),
                  isTablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildControlButton(
                  '-50',
                  Icons.remove,
                  Colors.orange,
                  () => _updateCalories(_calories - 50),
                  isTablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildControlButton(
                  '+50',
                  Icons.add,
                  Colors.green,
                  () => _updateCalories(_calories + 50),
                  isTablet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildControlButton(
                  '+100',
                  Icons.add,
                  Colors.blue,
                  () => _updateCalories(_calories + 100),
                  isTablet,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 15),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reset auf 0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _updateCalories(0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onTap, bool isTablet) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 16 : 12,
          horizontal: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTips() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
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
              const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFfa709a),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Ernährungs-Tipps',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          ...[
            'Iss regelmäßig kleine Mahlzeiten über den Tag verteilt',
            'Achte auf eine ausgewogene Verteilung der Makronährstoffe',
            'Trinke vor jeder Mahlzeit ein Glas Wasser',
            'Verzichte nicht komplett auf Kohlenhydrate',
            'Iss langsam und kaue gründlich',
          ].map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFfa709a),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isTablet ? 16 : 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Kalorienzähler Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Verfolge deine tägliche Kalorienaufnahme und halte dein Energiegleichgewicht im Blick. Eine ausgewogene Ernährung ist der Schlüssel zu deinem Wohlbefinden.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Verstanden',
              style: TextStyle(color: Color(0xFFfa709a), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 