import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Schlafzähler-Bildschirm für die Überwachung der täglichen Schlafdauer
/// 
/// Bietet Funktionalitäten für:
/// - Tägliche Schlafdauer in Stunden verfolgen
/// - Personalisierte Schlafziele basierend auf Benutzerprofil
/// - Visuelle Darstellung der Schlafqualität
/// - Fortschrittsanzeige und Statistiken
/// - Integration mit dem täglichen Daten-Tracking
/// 
/// Der Bildschirm verwendet Schlaf-bezogene Motive und
/// speichert alle Daten in Firestore.
class SleepCounterScreen extends StatefulWidget {
  const SleepCounterScreen({super.key});

  @override
  State<SleepCounterScreen> createState() => _SleepCounterScreenState();
}

/// State-Klasse für den Schlafzähler-Bildschirm
/// 
/// Verwaltet Schlafdaten, Ziele und verschiedene Animationen.
/// Implementiert Firestore-Integration für Datenpersistierung,
/// Animationen für Fade, Scale und Pulse-Effekte.
/// Bietet eine beruhigende Benutzeroberfläche mit
/// Schlaf-bezogenen visuellen Elementen.
class _SleepCounterScreenState extends State<SleepCounterScreen> with TickerProviderStateMixin {
  double _hours = 0.0;
  double _sleepGoal = 8.0;
  bool _loading = true;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _loadGoalAndSleep();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalAndSleep() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _sleepGoal = (userDoc.data()?['zielSleep'] ?? 8.0).toDouble();
        });
      }
      
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final sleepDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .get();
      
      if (sleepDoc.exists) {
        setState(() {
          _hours = (sleepDoc.data()?['sleep'] ?? 0.0).toDouble();
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

  Future<void> _saveSleep() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(dateStr)
          .set({'sleep': _hours}, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Speichern: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _updateSleep(double newHours) {
    setState(() {
      _hours = newHours.clamp(0.0, 12.0);
    });
    _saveSleep();
    
    if (_hours >= _sleepGoal) {
      _showCelebration();
    }
  }

  void _showCelebration() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.bedtime, color: Colors.white),
            SizedBox(width: 8),
            Text('Perfekt! Du hast dein Schlafziel erreicht! 😴'),
          ],
        ),
        backgroundColor: const Color(0xFF43e97b),
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
                        color: Color(0xFF43e97b),
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
                            _buildSleepProgressCard(),
                            const SizedBox(height: 30),
                            _buildSleepControls(),
                            const SizedBox(height: 30),
                            _buildSleepTips(),
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
              Color(0xFF43e97b),
              Color(0xFF38d9a9),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Schlafzähler',
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

  Widget _buildSleepProgressCard() {
    final progress = (_hours / _sleepGoal).clamp(0.0, 1.0);
    final isComplete = progress >= 1.0;
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
                'Schlafziel heute',
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
                    colors: [Color(0xFF43e97b), Color(0xFF38d9a9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_sleepGoal.toStringAsFixed(1)} h',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43e97b)),
                  strokeCap: StrokeCap.round,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isComplete ? _pulseAnimation.value : 1.0,
                    child: Column(
                      children: [
                        Icon(
                          isComplete ? Icons.bedtime : Icons.bedtime_outlined,
                          color: const Color(0xFF43e97b),
                          size: isTablet ? 50 : 40,
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          '${_hours.toStringAsFixed(1)} h',
                          style: TextStyle(
                            fontSize: isTablet ? 32 : 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
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
          if (isComplete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Schlafziel erreicht!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSleepControls() {
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
            'Schlafstunden einstellen',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Container(
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
              children: [
                Text(
                  'Slider zum Einstellen',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 15),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF43e97b),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: const Color(0xFF43e97b),
                    overlayColor: const Color(0xFF43e97b).withOpacity(0.2),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: isTablet ? 15 : 12),
                    trackHeight: isTablet ? 8 : 6,
                  ),
                  child: Slider(
                    value: _hours,
                    min: 0.0,
                    max: 12.0,
                    divisions: 24,
                    label: '${_hours.toStringAsFixed(1)} h',
                    onChanged: _updateSleep,
                  ),
                ),
                SizedBox(height: isTablet ? 20 : 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickTimeButton('6h', 6.0, isTablet),
                    _buildQuickTimeButton('7h', 7.0, isTablet),
                    _buildQuickTimeButton('8h', 8.0, isTablet),
                    _buildQuickTimeButton('9h', 9.0, isTablet),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTimeButton(String label, double hours, bool isTablet) {
    final isSelected = _hours == hours;
    
    return GestureDetector(
      onTap: () => _updateSleep(hours),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 10,
          horizontal: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF43e97b), Color(0xFF38d9a9)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF43e97b) : Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 16 : 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSleepTips() {
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
                color: Color(0xFF43e97b),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Schlaf-Tipps',
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
            'Gehe jeden Tag zur gleichen Zeit schlafen',
            'Vermeide Koffein 6 Stunden vor dem Schlafengehen',
            'Halte dein Schlafzimmer kühl (16-19°C)',
            'Verzichte auf Bildschirme 1 Stunde vor dem Schlafen',
            'Erstelle eine entspannende Abendroutine',
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
                    color: Color(0xFF43e97b),
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
          'Schlafzähler Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Verfolge deine tägliche Schlafdauer und erreiche dein Schlafziel für bessere Gesundheit und Wohlbefinden.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Verstanden',
              style: TextStyle(color: Color(0xFF43e97b), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 