import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  bool _isLoading = true;
  List<Map<String, dynamic>> _habits = [];
  int _streakCount = 0;
  double _completionRate = 0.0;
  int _totalHabits = 0;
  int _completedToday = 0;

  // Voreingestellte Gewohnheiten
  final List<Map<String, dynamic>> _defaultHabits = [
    {
      'id': 'hydration',
      'name': 'Hydration',
      'icon': Icons.water_drop,
      'color': Color(0xFF43e97b),
    },
    {
      'id': 'active_pause',
      'name': 'Aktive Pause',
      'icon': Icons.directions_walk,
      'color': Color(0xFF43e97b),
    },
    {
      'id': 'evening_routine',
      'name': 'Abendroutine',
      'icon': Icons.nightlight_round,
      'color': Color(0xFF43e97b),
    },
    {
      'id': 'decoupling',
      'name': 'Entkopplung',
      'icon': Icons.phone_android_outlined,
      'color': Color(0xFF43e97b),
    },
    {
      'id': 'meditation',
      'name': 'Meditation',
      'icon': Icons.self_improvement,
      'color': Color(0xFF43e97b),
    },
    {
      'id': 'sleep',
      'name': 'Schlaf',
      'icon': Icons.bedtime,
      'color': Color(0xFF43e97b),
    },
  ];

  Map<String, bool> _completionStatus = {};
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeUserData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _initializeUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Créer ou mettre à jour le document utilisateur
        final userDocRef = _firestore.collection('users').doc(user.uid);
        
        await userDocRef.set({
          'email': user.email,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Initialiser les habitudes par défaut si elles n'existent pas
        final habitsCollectionRef = userDocRef.collection('habits');
        final habitsSnapshot = await habitsCollectionRef.get();

        if (habitsSnapshot.docs.isEmpty) {
          final batch = _firestore.batch();
          for (var habit in _defaultHabits) {
            final habitDoc = habitsCollectionRef.doc(habit['id']);
            batch.set(habitDoc, {
              'name': habit['name'],
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });
          }
          await batch.commit();
        }

        // Charger le statut de complétion pour aujourd'hui
        await _loadCompletionStatus();
        await _loadStreak();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Initialisieren der Daten: $e';
      });
      debugPrint(_errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final streakDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streak')
            .get();

        setState(() {
          _streakCount = streakDoc.data()?['currentStreak'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading streak: $e');
    }
  }

  Future<void> _loadCompletionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(today);
        
        final statusDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_status')
            .doc(dateStr)
            .get();

        final completed = List<String>.from(statusDoc.data()?['completed'] ?? []);
        setState(() {
          _completionStatus = Map.fromIterable(
            _defaultHabits,
            key: (habit) => habit['id'] as String,
            value: (habit) => completed.contains(habit['id']),
          );
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Gewohnheiten: $e';
      });
      debugPrint(_errorMessage);
    }
  }

  Future<void> _toggleHabit(Map<String, dynamic> habit) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final newStatus = !(_completionStatus[habit['id']] ?? false);

    setState(() {
      _completionStatus[habit['id']] = newStatus;
      _errorMessage = '';
    });

    try {
      final statusDocRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_status')
          .doc(dateStr);

      await _firestore.runTransaction((transaction) async {
        final statusDoc = await transaction.get(statusDocRef);
        
        if (statusDoc.exists) {
          List<String> completed = List<String>.from(statusDoc.data()?['completed'] ?? []);
          if (newStatus) {
            completed.add(habit['id']);
          } else {
            completed.remove(habit['id']);
          }
          transaction.update(statusDocRef, {
            'completed': completed,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(statusDocRef, {
            'completed': newStatus ? [habit['id']] : [],
            'date': dateStr,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      // Mettre à jour le streak si nécessaire
      if (newStatus) {
        await _updateStreak();
      }
    } catch (e) {
      setState(() {
        _completionStatus[habit['id']] = !newStatus;
        _errorMessage = 'Fehler beim Aktualisieren der Gewohnheit: $e';
      });
      debugPrint(_errorMessage);
    }
  }

  Future<void> _updateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final streakRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streak');

        await _firestore.runTransaction((transaction) async {
          final streakDoc = await transaction.get(streakRef);
          final currentStreak = streakDoc.data()?['currentStreak'] ?? 0;
          
          transaction.set(streakRef, {
            'currentStreak': currentStreak + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          setState(() {
            _streakCount = currentStreak + 1;
          });
        });
      }
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 40 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProgressHeader(isTablet),
                            const SizedBox(height: 30),
                            _buildStreakCard(isTablet),
                            const SizedBox(height: 30),
                            _buildHabitsList(isTablet),
                            if (_habits.isEmpty) _buildEmptyState(isTablet),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          if (_errorMessage.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement add new habit
        },
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Neue Gewohnheit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
            'Meine Gewohnheiten',
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

  Widget _buildProgressHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF43e97b).withOpacity(0.2),
            const Color(0xFF38f9d7).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF43e97b).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Heute',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd. MMMM yyyy').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF43e97b).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF43e97b).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: const Color(0xFF43e97b),
                      size: isTablet ? 24 : 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_completedToday/$_totalHabits',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: (MediaQuery.of(context).size.width - (isTablet ? 140 : 90)) *
                    (_completionRate / 100),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF43e97b).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_completionRate.toStringAsFixed(1)}% geschafft',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFfad0c4).withOpacity(0.2),
            const Color(0xFFffd1ff).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFFfad0c4).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFfad0c4), Color(0xFFffd1ff)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFfad0c4).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: isTablet ? 32 : 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_streakCount Tage Streak! 🔥',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 22 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weiter so! Bleib am Ball und erreiche deine Ziele.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 20),
          child: Text(
            'Tägliche Gewohnheiten',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._habits.asMap().entries.map((entry) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  (1 - _animationController.value) * 100 * (entry.key + 1),
                ),
                child: Opacity(
                  opacity: _animationController.value,
                  child: _buildHabitCard(entry.value, isTablet),
                ),
              );
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildHabitCard(Map<String, dynamic> habit, bool isTablet) {
    final bool isCompleted = habit['lastCompleted'] != null &&
        (habit['lastCompleted'] as Timestamp).toDate().isAfter(
              DateTime.now().subtract(const Duration(days: 1)),
            );
    final int streak = habit['streak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleHabit(habit),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 25 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isCompleted
                      ? const Color(0xFF43e97b).withOpacity(0.2)
                      : const Color(0xFF2d3748),
                  isCompleted
                      ? const Color(0xFF38f9d7).withOpacity(0.1)
                      : const Color(0xFF1a202c),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF43e97b).withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                width: isCompleted ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCompleted
                      ? const Color(0xFF43e97b).withOpacity(0.2)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isCompleted ? 20 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCompleted
                          ? [const Color(0xFF43e97b), const Color(0xFF38f9d7)]
                          : [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted
                                ? const Color(0xFF43e97b)
                                : const Color(0xFF667eea))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    habit['icon'] ?? Icons.check_circle_outline,
                    size: isTablet ? 32 : 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              habit['name'] ?? '',
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (streak > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFfad0c4).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFfad0c4).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: const Color(0xFFfad0c4),
                                    size: isTablet ? 16 : 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$streak',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 14 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habit['description'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 16 : 14,
                        ),
                      ),
                      if (habit['reminder'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.white.withOpacity(0.6),
                              size: isTablet ? 16 : 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              habit['reminder'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isTablet ? 14 : 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF43e97b)
                        : Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.arrow_forward,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFF2d3748),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_task,
            size: isTablet ? 60 : 50,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Keine Gewohnheiten vorhanden',
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Füge neue Gewohnheiten hinzu, um deine Ziele zu erreichen',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}