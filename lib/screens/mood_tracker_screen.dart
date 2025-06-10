import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  double _currentMoodLevel = 3.0;
  final TextEditingController _moodCommentController = TextEditingController();
  bool _isLoading = false;
  String? _currentMoodId;
  late AnimationController _animationController;
  late AnimationController _emojiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _emojiAnimation;

  final List<Map<String, dynamic>> _moodData = [
    {
      'level': 1.0,
      'emoji': '😢',
      'label': 'Sehr schlecht',
      'color': const Color(0xFFff6b6b),
      'description': 'Ich fühle mich wirklich niedergeschlagen',
    },
    {
      'level': 2.0,
      'emoji': '😟',
      'label': 'Schlecht',
      'color': const Color(0xFFffa726),
      'description': 'Es ist ein schwieriger Tag',
    },
    {
      'level': 3.0,
      'emoji': '😐',
      'label': 'Neutral',
      'color': const Color(0xFFffee58),
      'description': 'Weder gut noch schlecht',
    },
    {
      'level': 4.0,
      'emoji': '😊',
      'label': 'Gut',
      'color': const Color(0xFF66bb6a),
      'description': 'Ich fühle mich ziemlich gut',
    },
    {
      'level': 5.0,
      'emoji': '😄',
      'label': 'Sehr gut',
      'color': const Color(0xFF43e97b),
      'description': 'Ich bin sehr glücklich und energiegeladen',
    },
  ];

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _emojiController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
    
    _emojiAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _emojiController,
      curve: Curves.elasticOut,
    ));
    
    if (_user != null) {
      _loadDailyMood();
    }
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _moodCommentController.dispose();
    _animationController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Map<String, dynamic> _getCurrentMoodData() {
    return _moodData.firstWhere(
      (mood) => mood['level'] == _currentMoodLevel,
      orElse: () => _moodData[2], // Default to neutral
    );
  }

  Future<void> _loadDailyMood() async {
    if (_user == null) return;
    
    try {
      final today = _getCurrentDate();
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('moodEntries')
          .doc(today)
          .get();

      if (moodSnapshot.exists && mounted) {
        final moodData = moodSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentMoodLevel = (moodData['level'] as num?)?.toDouble() ?? 3.0;
          _moodCommentController.text = (moodData['comment'] as String?) ?? '';
          _currentMoodId = moodSnapshot.id;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der täglichen Stimmung: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _saveDailyMood() async {
    if (_user == null) return;
    
    setState(() => _isLoading = true);
    try {
      final today = _getCurrentDate();
      final moodData = {
        'level': _currentMoodLevel,
        'comment': _moodCommentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'emoji': _getCurrentMoodData()['emoji'],
        'label': _getCurrentMoodData()['label'],
      };

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('moodEntries')
          .doc(today)
          .set(moodData, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _currentMoodId = today;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mood, color: Colors.white),
                SizedBox(width: 8),
                Text('Stimmung erfolgreich gespeichert! 💝'),
              ],
            ),
            backgroundColor: Color(0xFF43e97b),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateMood(double newLevel) {
    setState(() {
      _currentMoodLevel = newLevel;
    });
    _emojiController.forward().then((_) => _emojiController.reverse());
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
            child: _user == null
                ? _buildNotLoggedIn()
                : _isLoading
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
                            padding: EdgeInsets.all(isTablet ? 40 : 20),
                            child: Column(
                              children: [
                                _buildMoodSelectionCard(isTablet),
                                const SizedBox(height: 30),
                                _buildMoodVisualization(isTablet),
                                const SizedBox(height: 30),
                                _buildCommentSection(isTablet),
                                const SizedBox(height: 30),
                                _buildActionButtons(isTablet),
                                const SizedBox(height: 30),
                                _buildMoodTips(isTablet),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCurrentMoodData()['color'].withOpacity(0.8),
              _getCurrentMoodData()['color'].withOpacity(0.6),
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
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.analytics_outlined, color: Colors.white),
            onPressed: () {
              _showMoodAnalytics();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelectionCard(bool isTablet) {
    final currentMood = _getCurrentMoodData();
    
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
          Text(
            'Wie fühlst du dich heute?',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 30 : 25),
          AnimatedBuilder(
            animation: _emojiAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _emojiAnimation.value,
                child: Container(
                  width: isTablet ? 120 : 100,
                  height: isTablet ? 120 : 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentMood['color'].withOpacity(0.3),
                        currentMood['color'].withOpacity(0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: currentMood['color'].withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      currentMood['emoji'],
                      style: TextStyle(
                        fontSize: isTablet ? 60 : 50,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Text(
            currentMood['label'],
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: currentMood['color'],
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            currentMood['description'],
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodVisualization(bool isTablet) {
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
            'Wähle deine Stimmung',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _moodData.map((mood) {
              final isSelected = _currentMoodLevel == mood['level'];
              
              return GestureDetector(
                onTap: () => _updateMood(mood['level']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isTablet ? 16 : 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              mood['color'].withOpacity(0.8),
                              mood['color'].withOpacity(0.6),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? mood['color'] : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: mood['color'].withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        mood['emoji'],
                        style: TextStyle(
                          fontSize: isTablet ? 40 : 32,
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Text(
                        mood['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  Widget _buildCommentSection(bool isTablet) {
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
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: _getCurrentMoodData()['color'],
                size: isTablet ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Gedanken & Notizen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _moodCommentController,
              maxLines: 4,
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 16 : 14,
              ),
              cursorColor: _getCurrentMoodData()['color'],
              decoration: InputDecoration(
                hintText: 'Was beschäftigt dich heute? Teile deine Gedanken...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: isTablet ? 16 : 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(isTablet ? 20 : 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: isTablet ? 60 : 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveDailyMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getCurrentMoodData()['color'],
                      _getCurrentMoodData()['color'].withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getCurrentMoodData()['color'].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: isTablet ? 24 : 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Speichern',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: isTablet ? 60 : 55,
          height: isTablet ? 60 : 55,
          child: ElevatedButton(
            onPressed: _analyzeMoodWithAI,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                alignment: Alignment.center,
                child: Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodTips(bool isTablet) {
    final currentMood = _getCurrentMoodData();
    final tips = _getMoodTips(_currentMoodLevel);
    
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
                Icons.lightbulb_outline,
                color: currentMood['color'],
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Tipps für deine Stimmung',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: currentMood['color'],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: isTablet ? 14 : 12,
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

  Widget _buildNotLoggedIn() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mood_bad_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          const Text(
            'Anmeldung erforderlich',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Bitte melde dich an, um den Stimmungs-Tracker zu nutzen.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<String> _getMoodTips(double moodLevel) {
    if (moodLevel <= 2.0) {
      return [
        'Versuche 10 Minuten zu meditieren oder zu entspannen',
        'Gehe an die frische Luft für einen kurzen Spaziergang',
        'Sprich mit einem Freund oder einer vertrauensvollen Person',
        'Höre beruhigende Musik oder deine Lieblingslieder',
        'Praktiziere Dankbarkeit - denke an 3 positive Dinge',
      ];
    } else if (moodLevel <= 3.0) {
      return [
        'Probiere eine neue Aktivität aus, die dir Freude bereitet',
        'Organisiere deine Umgebung - Ordnung kann beruhigend wirken',
        'Nimm dir Zeit für ein Hobby oder eine kreative Tätigkeit',
        'Trinke genug Wasser und achte auf gesunde Ernährung',
        'Plane etwas Schönes für die nächsten Tage',
      ];
    } else {
      return [
        'Teile deine gute Stimmung mit anderen',
        'Nutze deine positive Energie für produktive Aktivitäten',
        'Dokumentiere, was dich heute glücklich gemacht hat',
        'Plane zukünftige Aktivitäten, die dir Freude bereiten',
        'Praktiziere Dankbarkeit und genieße den Moment',
      ];
    }
  }

  void _analyzeMoodWithAI() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.psychology,
              color: _getCurrentMoodData()['color'],
            ),
            const SizedBox(width: 12),
            const Text(
              'KI-Analyse',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basierend auf deiner aktuellen Stimmung "${_getCurrentMoodData()['label']}" und deinen Notizen:',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCurrentMoodData()['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getCurrentMoodData()['color'].withOpacity(0.3),
                ),
              ),
              child: Text(
                _getAIRecommendation(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: _getCurrentMoodData()['color'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAIRecommendation() {
    final mood = _getCurrentMoodData();
    final comment = _moodCommentController.text.trim();
    
    if (_currentMoodLevel <= 2.0) {
      return 'Es scheint, als hättest du einen schwierigen Tag. Versuche eine kurze Meditation oder einen Spaziergang an der frischen Luft. Denke daran, dass schwierige Zeiten vorübergehen.';
    } else if (_currentMoodLevel <= 3.0) {
      return 'Deine Stimmung ist neutral. Das ist völlig in Ordnung! Vielleicht ist heute ein guter Tag für eine entspannte Aktivität oder um dich auf morgen vorzubereiten.';
    } else {
      return 'Du hast eine positive Stimmung! Das ist wunderbar. Nutze diese Energie für Aktivitäten, die dir wichtig sind, oder teile deine gute Laune mit anderen.';
    }
  }

  void _showMoodAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Stimmungsanalyse',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Deine Stimmungsstatistiken und -trends werden hier angezeigt, sobald du mehr Einträge gesammelt hast.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                color: _getCurrentMoodData()['color'],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 