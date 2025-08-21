import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../utils/motivational_quotes.dart';

/// Erweiterter Stimmungs-Tracker-Bildschirm mit zusätzlichen Funktionen
/// 
/// Bietet erweiterte Funktionalitäten für:
/// - Detaillierte Stimmungsverfolgung mit Journaling
/// - Stimmungsstatistiken und Trends mit Charts
/// - Entspannungsübungen (Atemübungen, Meditation, Dankbarkeit)
/// - Motivierende Zitate in verschiedenen Sprachen
/// - Erweiterte Datenanalyse und -visualisierung
/// 
/// Der Bildschirm integriert verschiedene Wellness-Tools
/// und bietet eine umfassende Stimmungsüberwachung.
class EnhancedMoodTrackerScreen extends StatefulWidget {
  const EnhancedMoodTrackerScreen({super.key});

  @override
  State<EnhancedMoodTrackerScreen> createState() => _EnhancedMoodTrackerScreenState();
}

/// State-Klasse für den erweiterten Stimmungs-Tracker-Bildschirm
/// 
/// Verwaltet erweiterte Stimmungsdaten, Übungen und Animationen.
/// Implementiert Firestore-Integration, Chart-Visualisierung,
/// Atemübungen-Animationen und mehrsprachige Zitate.
/// Bietet eine umfassende Wellness-Erfahrung mit
/// verschiedenen Entspannungstechniken.
class _EnhancedMoodTrackerScreenState extends State<EnhancedMoodTrackerScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _journalController = TextEditingController();
  int _selectedMood = 3;
  bool _isLoading = false;
  List<Map<String, dynamic>> _moodHistory = [];
  Map<String, dynamic> _moodStats = {};
  String _selectedExercise = 'breathing';
  late AnimationController _breathingController;
  late AnimationController _fadeController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _moodLevels = [
    {'level': 1, 'emoji': '😢', 'color': Color(0xFFfa709a), 'label': 'Sehr schlecht'},
    {'level': 2, 'emoji': '😔', 'color': Color(0xFFff9a9e), 'label': 'Schlecht'},
    {'level': 3, 'emoji': '😐', 'color': Color(0xFFffeaa7), 'label': 'Neutral'},
    {'level': 4, 'emoji': '😊', 'color': Color(0xFF74b9ff), 'label': 'Gut'},
    {'level': 5, 'emoji': '😄', 'color': Color(0xFF00b894), 'label': 'Sehr gut'},
  ];

  final List<Map<String, dynamic>> _exercises = [
    {
      'id': 'breathing',
      'title': 'Atemübung (4-7-8)',
      'description': 'Einatmen (4s), Halten (7s), Ausatmen (8s)',
      'icon': Icons.air,
      'color': Color(0xFF4facfe),
    },
    {
      'id': 'meditation',
      'title': '5-Minuten Meditation',
      'description': 'Kurze Entspannungsmeditation',
      'icon': Icons.self_improvement,
      'color': Color(0xFF667eea),
    },
    {
      'id': 'gratitude',
      'title': 'Dankbarkeitsübung',
      'description': 'Denke an 3 Dinge, für die du dankbar bist',
      'icon': Icons.favorite,
      'color': Color(0xFFfa709a),
    },
  ];

  String _currentQuote = "Jeder Tag ist ein neuer Anfang.";

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadMoodData();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    final isEnabled = await MotivationalQuotes.isQuotesEnabled();
    
    if (isEnabled) {
      setState(() {
        _currentQuote = MotivationalQuotes.getQuoteOfTheDay('de'); // Allemand par défaut
      });
    }
  }

  void _initAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _fadeController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load mood history
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moodEntries')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      final history = moodSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'level': data['level'] ?? 3,
          'note': data['note'] ?? '',
          'date': data['date']?.toDate() ?? DateTime.now(),
          'exercises': data['exercises'] ?? [],
        };
      }).toList();

      // Calculate mood statistics
      final stats = _calculateMoodStats(history);

      setState(() {
        _moodHistory = history;
        _moodStats = stats;
        _isLoading = false;
      });
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

  Map<String, dynamic> _calculateMoodStats(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return {};

    final levels = history.map((entry) => entry['level'] as int).toList();
    final average = levels.reduce((a, b) => a + b) / levels.length;
    
    final moodCounts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      moodCounts[i] = levels.where((level) => level == i).length;
    }

    // Calculate streak
    int currentStreak = 0;
    for (final entry in history) {
      if (entry['level'] >= 4) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {
      'average': average,
      'total': history.length,
      'distribution': moodCounts,
      'goodDaysStreak': currentStreak,
      'lastWeekAverage': _getLastWeekAverage(history),
    };
  }

  double _getLastWeekAverage(List<Map<String, dynamic>> history) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentEntries = history.where((entry) => 
        entry['date'].isAfter(weekAgo)).toList();
    
    if (recentEntries.isEmpty) return 0.0;
    
    final levels = recentEntries.map((entry) => entry['level'] as int).toList();
    return levels.reduce((a, b) => a + b) / levels.length;
  }

  Future<void> _saveMoodEntry() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moodEntries')
          .doc(today)
          .set({
        'level': _selectedMood,
        'note': _journalController.text.trim(),
        'date': FieldValue.serverTimestamp(),
        'exercises': [], // Will be updated when exercises are completed
      }, SetOptions(merge: true));

      _journalController.clear();
      _loadMoodData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(_moodLevels[_selectedMood - 1]['emoji']),
              const SizedBox(width: 8),
              const Text('Stimmung gespeichert! 💝'),
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
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startBreathingExercise() {
    _breathingController.repeat(reverse: true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BreathingExerciseDialog(
        animation: _breathingAnimation,
        onComplete: () {
          _breathingController.stop();
          Navigator.of(context).pop();
          _markExerciseCompleted('breathing');
        },
      ),
    );
  }

  Future<void> _markExerciseCompleted(String exerciseId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moodEntries')
          .doc(today)
          .update({
        'exercises': FieldValue.arrayUnion([exerciseId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Übung abgeschlossen! 🌟'),
            ],
          ),
          backgroundColor: Color(0xFF43e97b),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Ignore error silently
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 40 : 20),
                child: Column(
                  children: [
                    _buildDailyQuote(isTablet),
                    const SizedBox(height: 30),
                    _buildMoodSelector(isTablet),
                    const SizedBox(height: 30),
                    _buildJournalEntry(isTablet),
                    const SizedBox(height: 30),
                    _buildQuickExercises(isTablet),
                    const SizedBox(height: 30),
                    if (_moodHistory.isNotEmpty) ...[
                      _buildMoodStats(isTablet),
                      const SizedBox(height: 30),
                      _buildMoodChart(isTablet),
                      const SizedBox(height: 30),
                    ],
                    _buildRecentEntries(isTablet),
                    const SizedBox(height: 30),
                  ],
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
            'Stimmungs-Tracker',
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

  Widget _buildDailyQuote(bool isTablet) {
    final quote = _currentQuote;
    
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.format_quote,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            quote,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Motivation des Tages',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(bool isTablet) {
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
            'Wie fühlst du dich heute?',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moodLevels.map((mood) {
              final isSelected = _selectedMood == mood['level'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMood = mood['level'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? mood['color'].withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? mood['color'] 
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: mood['color'].withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ] : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood['emoji'],
                        style: TextStyle(fontSize: isTablet ? 32 : 28),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntry(bool isTablet) {
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
              Icon(
                Icons.book,
                color: const Color(0xFFfee140),
                size: isTablet ? 28 : 24,
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Tagebuch-Eintrag',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          TextField(
            controller: _journalController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Wie war dein Tag? Was beschäftigt dich? Schreibe deine Gedanken auf...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: isTablet ? 16 : 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFfee140)),
              ),
              filled: true,
              fillColor: const Color(0xFF2d3748),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          SizedBox(
            width: double.infinity,
            height: isTablet ? 50 : 45,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMoodEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_moodLevels[_selectedMood - 1]['emoji']),
                            const SizedBox(width: 8),
                            Text(
                              'Speichern',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 16 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildQuickExercises(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 25 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF43e97b),
            Color(0xFF38d9a9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43e97b).withOpacity(0.3),
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
                Icons.spa,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Wellness-Übungen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isTablet ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTablet ? 1.5 : 3.5,
            children: _exercises.map((exercise) {
              return _buildExerciseCard(exercise, isTablet);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, bool isTablet) {
    return GestureDetector(
      onTap: () {
        if (exercise['id'] == 'breathing') {
          _startBreathingExercise();
        } else {
          _markExerciseCompleted(exercise['id']);
        }
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              exercise['icon'],
              color: Colors.white,
              size: isTablet ? 32 : 24,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              exercise['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 8 : 4),
            Text(
              exercise['description'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 12 : 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodStats(bool isTablet) {
    if (_moodStats.isEmpty) return const SizedBox.shrink();

    final average = _moodStats['average']?.toDouble() ?? 0.0;
    final streak = _moodStats['goodDaysStreak'] ?? 0;
    final lastWeekAverage = _moodStats['lastWeekAverage']?.toDouble() ?? 0.0;

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
            'Emotionale Statistiken',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Durchschnitt',
                  average.toStringAsFixed(1),
                  _getMoodEmoji(average.round()),
                  isTablet,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Gute-Tage-Serie',
                  streak.toString(),
                  '🔥',
                  isTablet,
                ),

              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Diese Woche',
                  lastWeekAverage.toStringAsFixed(1),
                  _getMoodEmoji(lastWeekAverage.round()),
                  isTablet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String emoji, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: isTablet ? 24 : 20),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isTablet ? 12 : 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(bool isTablet) {
    if (_moodHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      height: isTablet ? 250 : 200,
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
            'Stimmungsverlauf (30 Tage)',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 28,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value >= 1 && value <= 5) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _getMoodEmoji(value.toInt()),
                              style: const TextStyle(fontSize: 16),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (_moodHistory.length - 1).toDouble(),
                minY: 1,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: _moodHistory.asMap().entries.map((entry) {
                      return FlSpot(
                        (_moodHistory.length - 1 - entry.key).toDouble(),
                        entry.value['level'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: _getMoodColor(spot.y.toInt()),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFfa709a).withOpacity(0.3),
                          const Color(0xFFfa709a).withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentEntries(bool isTablet) {
    if (_moodHistory.isEmpty) return const SizedBox.shrink();

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
            'Letzte Einträge',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          ...(_moodHistory.take(5).map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry['level']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getMoodColor(entry['level']),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getMoodEmoji(entry['level']),
                        style: TextStyle(fontSize: isTablet ? 20 : 16),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd.MM.yyyy').format(entry['date']),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (entry['note'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            entry['note'],
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isTablet ? 12 : 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  String _getMoodEmoji(int level) {
    if (level < 1 || level > 5) return '😐';
    return _moodLevels[level - 1]['emoji'];
  }

  Color _getMoodColor(int level) {
    if (level < 1 || level > 5) return const Color(0xFFffeaa7);
    return _moodLevels[level - 1]['color'];
  }
}

/// Atemübung-Dialog für geführte Entspannungsübungen
/// 
/// Bietet Funktionalitäten für:
/// - Geführte 4-7-8 Atemübung (60 Sekunden)
/// - Visuelle Phase-Anzeige (Einatmen, Halten, Ausatmen)
/// - Countdown-Timer für Übungsdauer
/// - Animierte Atemvisualisierung
/// - Callback bei Übungsabschluss
/// 
/// Der Dialog bietet eine immersive Atemübung
/// für Stressabbau und Entspannung.
class _BreathingExerciseDialog extends StatefulWidget {
  final Animation<double> animation;
  final VoidCallback onComplete;

  const _BreathingExerciseDialog({
    required this.animation,
    required this.onComplete,
  });

  @override
  State<_BreathingExerciseDialog> createState() => _BreathingExerciseDialogState();
}

/// State-Klasse für den Atemübung-Dialog
/// 
/// Verwaltet Atemübung-Timer, Phasenwechsel und Animationen.
/// Implementiert Countdown-Logik für 60-Sekunden-Übung,
/// Phase-basierte Anweisungen und visuelle Rückmeldung.
/// Bietet eine beruhigende und fokussierte
/// Atemübungserfahrung.
class _BreathingExerciseDialogState extends State<_BreathingExerciseDialog> {
  int _countdown = 60; // 60 seconds exercise
  String _phase = 'Einatmen';

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _countdown > 0) {
        setState(() {
          _countdown--;
          // Change phase every 8 seconds (one breathing cycle)
          final cyclePosition = (60 - _countdown) % 19;
          if (cyclePosition < 4) {
            _phase = 'Einatmen (${4 - cyclePosition})';
          } else if (cyclePosition < 11) {
            _phase = 'Halten (${11 - cyclePosition})';
          } else {
            _phase = 'Ausatmen (${19 - cyclePosition})';
          }
        });
        _startCountdown();
      } else {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4facfe),
              Color(0xFF00f2fe),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Atemübung',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_countdown}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            AnimatedBuilder(
              animation: widget.animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.animation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.air,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            Text(
              _phase,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onComplete,
              child: const Text(
                'Beenden',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
