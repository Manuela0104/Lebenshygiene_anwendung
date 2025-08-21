import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

/// Fortschritts-Bildschirm für die Überwachung der Gesundheitsziele
/// 
/// Bietet umfassende Funktionalitäten für:
/// - Anzeige aller gesetzten Gesundheitsziele
/// - Tägliche Fortschrittsverfolgung in Echtzeit
/// - Erfolge und Meilensteine mit Feier-Animationen
/// - Fortschrittsstatistiken und Trends
/// - Motivation durch visuelle Fortschrittsdarstellung
/// - Integration mit allen Tracking-Funktionen
/// 
/// Der Bildschirm bietet eine zentrale Übersicht über
/// alle Gesundheitsziele und deren aktuellen Status.
class GoalsProgressScreen extends StatefulWidget {
  const GoalsProgressScreen({super.key});

  @override
  State<GoalsProgressScreen> createState() => _GoalsProgressScreenState();
}

/// State-Klasse für den Fortschritts-Bildschirm
/// 
/// Verwaltet Zielfortschritt, Erfolge und verschiedene Animationen.
/// Implementiert Firestore-Integration für Datenpersistierung,
/// Animationen für Fade, Scale und Rotations-Effekte.
/// Bietet eine motivierende Benutzeroberfläche mit
/// Feier-Animationen für erreichte Ziele.
class _GoalsProgressScreenState extends State<GoalsProgressScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic> _goals = {};
  Map<String, dynamic> _todayProgress = {};
  List<Map<String, dynamic>> _achievements = [];
  late AnimationController _animationController;
  late AnimationController _celebrationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadGoalsAndProgress();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalsAndProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user goals
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      // Load today's progress
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final progressDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyData')
          .doc(today)
          .get();
      
      final progressData = progressDoc.data() ?? {};

      // Load achievements
      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .orderBy('unlockedAt', descending: true)
          .limit(20)
          .get();

      setState(() {
        _goals = {
          'steps': userData['stepGoal'] ?? 10000,
          'water': userData['waterGoal'] ?? 2.0,
          'sleep': userData['sleepGoal'] ?? 8.0,
          'calories': userData['calorieGoal'] ?? 2000,
          'weight': userData['weightGoal'] ?? 70.0,
        };
        
        _todayProgress = {
          'steps': progressData['steps'] ?? 0,
          'water': progressData['water'] ?? 0.0,
          'sleep': progressData['sleep'] ?? 0.0,
          'calories': progressData['kcal'] ?? 0,
          'weight': progressData['weight'] ?? 70.0,
        };
        
        _achievements = achievementsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? '',
            'description': data['description'] ?? '',
            'icon': data['icon'] ?? 'star',
            'color': data['color'] ?? '#667eea',
            'unlockedAt': data['unlockedAt'],
            'type': data['type'] ?? 'general',
          };
        }).toList();
        
        _isLoading = false;
      });

      _animationController.forward();
      
      // Check for new achievements
      _checkForNewAchievements();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  Future<void> _checkForNewAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check various achievement conditions
    final achievements = <Map<String, dynamic>>[];
    
    // Steps achievements
    final steps = _todayProgress['steps'] ?? 0;
    if (steps >= 10000) {
      achievements.add({
        'title': 'Schritt-Meister',
        'description': '10.000 Schritte an einem Tag erreicht!',
        'icon': 'directions_walk',
        'color': '#43e97b',
        'type': 'steps',
      });
    }
    if (steps >= 15000) {
      achievements.add({
        'title': 'Aktivitäts-Champion',
        'description': '15.000 Schritte - Du bist unaufhaltbar!',
        'icon': 'emoji_events',
        'color': '#ffd700',
        'type': 'steps',
      });
    }

    // Water achievements
    final water = _todayProgress['water'] ?? 0.0;
    if (water >= 2.0) {
      achievements.add({
        'title': 'Hydrations-Held',
        'description': '2 Liter Wasser getrunken!',
        'icon': 'water_drop',
        'color': '#4facfe',
        'type': 'water',
      });
    }

    // Sleep achievements
    final sleep = _todayProgress['sleep'] ?? 0.0;
    if (sleep >= 8.0) {
      achievements.add({
        'title': 'Schlaf-Experte',
        'description': '8 Stunden erholsamen Schlaf erreicht!',
        'icon': 'bedtime',
        'color': '#667eea',
        'type': 'sleep',
      });
    }

    // Save new achievements
    for (final achievement in achievements) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('achievements')
          .add({
        ...achievement,
        'unlockedAt': FieldValue.serverTimestamp(),
      });
    }

    if (achievements.isNotEmpty) {
      _celebrationController.forward();
      _loadGoalsAndProgress(); // Reload to show new achievements
    }
  }

  Future<void> _editGoal(String goalType) async {
    final currentValue = _goals[goalType]?.toDouble() ?? 0.0;
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) => _BuildGoalEditDialog(
        goalType: goalType,
        currentValue: currentValue,
      ),
    );
    
    if (result != null) {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            '${goalType}Goal': result,
          });
          
          setState(() {
            _goals[goalType] = result;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('${_getGoalTitle(goalType)} aktualisiert! 🎯'),
                ],
              ),
              backgroundColor: const Color(0xFF43e97b),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Speichern: $e'),
              backgroundColor: Colors.red.shade400,
            ),
          );
        }
      }
    }
  }

  String _getGoalTitle(String goalType) {
    switch (goalType) {
      case 'steps':
        return 'Schritte-Ziel';
      case 'water':
        return 'Wasser-Ziel';
      case 'sleep':
        return 'Schlaf-Ziel';
      case 'calories':
        return 'Kalorien-Ziel';
      case 'weight':
        return 'Gewichts-Ziel';
      default:
        return 'Ziel';
    }
  }

  String _getGoalUnit(String goalType) {
    switch (goalType) {
      case 'steps':
        return 'Schritte';
      case 'water':
        return 'Liter';
      case 'sleep':
        return 'Stunden';
      case 'calories':
        return 'kcal';
      case 'weight':
        return 'kg';
      default:
        return '';
    }
  }

  Color _getGoalColor(String goalType) {
    switch (goalType) {
      case 'steps':
        return const Color(0xFF43e97b);
      case 'water':
        return const Color(0xFF4facfe);
      case 'sleep':
        return const Color(0xFF667eea);
      case 'calories':
        return const Color(0xFFfa709a);
      case 'weight':
        return const Color(0xFFfee140);
      default:
        return const Color(0xFF764ba2);
    }
  }

  IconData _getGoalIcon(String goalType) {
    switch (goalType) {
      case 'steps':
        return Icons.directions_walk;
      case 'water':
        return Icons.water_drop;
      case 'sleep':
        return Icons.bedtime;
      case 'calories':
        return Icons.local_fire_department;
      case 'weight':
        return Icons.monitor_weight;
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(50),
                      child: CircularProgressIndicator(
                        color: Color(0xFF667eea),
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 40 : 20),
                        child: Column(
                          children: [
                            _buildProgressSummary(isTablet),
                            const SizedBox(height: 30),
                            _buildGoalsList(isTablet),
                            const SizedBox(height: 30),
                            _buildAchievements(isTablet),
                            const SizedBox(height: 30),
                            _buildWeeklyProgress(isTablet),
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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Ziele & Fortschritt',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
        ),
      ),
    );
  }

  Widget _buildProgressSummary(bool isTablet) {
    int completedGoals = 0;
    int totalGoals = _goals.length;
    
    _goals.forEach((goalType, goalValue) {
      final progress = _todayProgress[goalType] ?? 0;
      if (progress >= goalValue) {
        completedGoals++;
      }
    });
    
    final overallProgress = totalGoals > 0 ? completedGoals / totalGoals : 0.0;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF43e97b),
            Color(0xFF38d9a9),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43e97b).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: isTablet ? 40 : 32,
                ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heutiger Fortschritt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedGoals von $totalGoals Zielen erreicht',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Stack(
            children: [
              Container(
                height: isTablet ? 20 : 16,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                height: isTablet ? 20 : 16,
                width: MediaQuery.of(context).size.width * 0.8 * overallProgress,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 15 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(overallProgress * 100).toInt()}% erreicht',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (overallProgress == 1.0)
                RotationTransition(
                  turns: _rotationAnimation,
                  child: const Icon(
                    Icons.stars,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
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
            'Meine Ziele',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          ..._goals.entries.map((entry) {
            final goalType = entry.key;
            final goalValue = entry.value.toDouble();
            final progress = (_todayProgress[goalType] ?? 0).toDouble();
            final percentage = goalValue > 0 ? math.min<double>(progress / goalValue, 1.0) : 0.0;
            
            return _buildGoalCard(
              goalType,
              goalValue,
              progress,
              percentage,
              isTablet,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String goalType, double goalValue, double progress, double percentage, bool isTablet) {
    final color = _getGoalColor(goalType);
    final isCompleted = percentage >= 1.0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () => _editGoal(goalType),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isCompleted ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? color : Colors.white.withOpacity(0.1),
              width: isCompleted ? 2 : 1,
            ),
            boxShadow: isCompleted ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 14 : 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getGoalIcon(goalType),
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _getGoalTitle(goalType),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                color: color,
                                size: isTablet ? 20 : 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${progress.toStringAsFixed(goalType == 'water' || goalType == 'sleep' ? 1 : 0)} / ${goalValue.toStringAsFixed(goalType == 'water' || goalType == 'sleep' ? 1 : 0)} ${_getGoalUnit(goalType)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: isCompleted ? color : Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 16 : 12),
              Stack(
                children: [
                  Container(
                    height: isTablet ? 12 : 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    height: isTablet ? 12 : 10,
                    width: (MediaQuery.of(context).size.width - (isTablet ? 140 : 120)) * percentage,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievements(bool isTablet) {
    if (_achievements.isEmpty) {
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
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.white.withOpacity(0.5),
              size: isTablet ? 48 : 40,
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Erfolge freigeschaltet',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erreiche deine Ziele, um Erfolge zu sammeln!',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: isTablet ? 14 : 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFfee140),
            Color(0xFFfa709a),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFfee140).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Erfolge (${_achievements.length})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          SizedBox(
            height: isTablet ? 120 : 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return _buildAchievementBadge(achievement, isTablet);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Map<String, dynamic> achievement, bool isTablet) {
    return Container(
      width: isTablet ? 100 : 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: isTablet ? 60 : 50,
            height: isTablet ? 60 : 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getAchievementIcon(achievement['icon']),
              color: Color(int.parse(achievement['color'].replaceAll('#', '0xFF'))),
              size: isTablet ? 30 : 24,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            achievement['title'],
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgress(bool isTablet) {
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
          Text(
            'Wöchentliche Übersicht',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final day = DateTime.now().subtract(Duration(days: 6 - index));
              final dayName = DateFormat('E', 'de').format(day).substring(0, 2);
              final isToday = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(DateTime.now());
              
              return Column(
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: isTablet ? 32 : 28,
                    height: isTablet ? 32 : 28,
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF43e97b) : Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isToday ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'water_drop':
        return Icons.water_drop;
      case 'bedtime':
        return Icons.bedtime;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'star':
        return Icons.star;
      default:
        return Icons.emoji_events;
    }
  }
}

class _BuildGoalEditDialog extends StatefulWidget {
  final String goalType;
  final double currentValue;

  const _BuildGoalEditDialog({
    required this.goalType,
    required this.currentValue,
  });

  @override
  State<_BuildGoalEditDialog> createState() => _BuildGoalEditDialogState();
}

class _BuildGoalEditDialogState extends State<_BuildGoalEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentValue.toStringAsFixed(widget.goalType == 'water' || widget.goalType == 'sleep' ? 1 : 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGoalTitle() {
    switch (widget.goalType) {
      case 'steps':
        return 'Schritte-Ziel';
      case 'water':
        return 'Wasser-Ziel (Liter)';
      case 'sleep':
        return 'Schlaf-Ziel (Stunden)';
      case 'calories':
        return 'Kalorien-Ziel';
      case 'weight':
        return 'Gewichts-Ziel (kg)';
      default:
        return 'Ziel bearbeiten';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2d3748),
      title: Text(
        _getGoalTitle(),
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Neues Ziel eingeben',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF667eea)),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          filled: true,
          fillColor: const Color(0xFF2d3748),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Abbrechen',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.of(context).pop(value);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
          ),
          child: const Text('Speichern', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}