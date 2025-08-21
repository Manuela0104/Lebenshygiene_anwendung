import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Zielauswahl-Bildschirm für die Personalisierung der Anwendung
/// 
/// Bietet Funktionalitäten für:
/// - Auswahl aus vordefinierten Gesundheitszielen
/// - Kategorisierte Ziele (Organisation, Wohlbefinden, Hygiene, Fortschritt)
/// - Detaillierte Beschreibungen und Features für jedes Ziel
/// - Personalisierung der Anwendung basierend auf Benutzerzielen
/// - Integration mit dem Benutzerprofil für zielgerichtete Funktionen
/// 
/// Der Bildschirm hilft Benutzern, ihre Gesundheitsziele zu definieren
/// und die Anwendung entsprechend anzupassen.
class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

/// State-Klasse für den Zielauswahl-Bildschirm
/// 
/// Verwaltet Zielauswahl, Animationen und Benutzerinteraktionen.
/// Implementiert Firestore-Integration für Zielspeicherung,
/// Animationen für Fade und Slide-Effekte.
/// Bietet eine intuitive Benutzeroberfläche für die
/// Zielauswahl und -personalisierung.
class _GoalSelectionScreenState extends State<GoalSelectionScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedGoal;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _cardController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _cardController = AnimationController(
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
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'organization',
      'title': 'Bessere Organisation des Alltags',
      'icon': Icons.schedule,
      'color': const Color(0xFF667eea),
      'description': 'Person mit viel Stress, die ihre Routine wieder unter Kontrolle bringen möchte.',
      'features': [
        'Wasser trinken, Spazieren, Zähneputzen nicht vergessen',
        'Tagesablauf mit einfachen Routinen strukturieren',
        'Gesundheitsüberblick ohne Komplikationen'
      ]
    },
    {
      'id': 'wellbeing',
      'title': 'Psychische & körperliche Gesundheit',
      'icon': Icons.self_improvement,
      'color': const Color(0xFF43e97b),
      'description': 'Person auf der Suche nach Wohlbefinden und ganzheitlichem Wohlsein.',
      'features': [
        'Regelmäßigerer Schlaf',
        'Bessere Stressbewältigung und Stimmungsverfolgung',
        'Entschleunigung und gesunde Gewohnheiten'
      ]
    },
    {
      'id': 'hygiene',
      'title': 'Regelmäßigkeit in der Lebenshygiene',
      'icon': Icons.cleaning_services,
      'color': const Color(0xFFfa709a),
      'description': 'Jugendliche, Studenten oder Erwachsene in schwierigen Phasen.',
      'features': [
        'Körperhygiene (Duschen, Zähneputzen)',
        'Ernährung und Lebensrhythmus',
        'Diskreter Coach ohne Urteile'
      ]
    },
    {
      'id': 'progress',
      'title': 'Fortschritte & Motivation',
      'icon': Icons.trending_up,
      'color': const Color(0xFF4facfe),
      'description': 'Person, die ihre Entwicklung visualisieren möchte.',
      'features': [
        'Gewohnheiten mit Statistiken stärken',
        'Kleine Ziele erreichen',
        'Täglicher Wohlfühl- oder Vitalitätswert'
      ]
    },
    {
      'id': 'recovery',
      'title': 'Schwierige Zeiten überwinden',
      'icon': Icons.healing,
      'color': const Color(0xFFfee140),
      'description': 'Person nach Burnout, depressiver Episode oder Trennung.',
      'features': [
        'Schrittweise Wiederaufbau',
        'Grundlegende Gewohnheiten wiederherstellen',
        'Begleitung ohne Druck'
      ]
    },
    {
      'id': 'routine',
      'title': 'Personalisierte Tagesroutine',
      'icon': Icons.calendar_today,
      'color': const Color(0xFF764ba2),
      'description': 'Nutzer von Tagesroutinen oder Journaling.',
      'features': [
        'Einfache, anpassungsfähige App',
        'Morgen: Getränk, Dusche, Sport',
        'Abend: Entspannung, Stimmungsnotiz, Schlafroutine'
      ]
    }
  ];

  Future<void> _saveSelectedGoal() async {
    if (_selectedGoal == null) return;
    
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final selectedGoalData = _goals.firstWhere((goal) => goal['id'] == _selectedGoal);
        await _firestore.collection('users').doc(user.uid).update({
          'selectedGoal': _selectedGoal,
          'ziel': selectedGoalData['title'],
          'goalSelectedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Ziel erfolgreich gespeichert! 🎯'),
                ],
              ),
              backgroundColor: const Color(0xFF43e97b),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
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
                    child: Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Padding(
                        padding: EdgeInsets.all(isTablet ? 40 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(isTablet),
                            const SizedBox(height: 30),
                            ..._goals.asMap().entries.map((entry) {
                              return AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, (1 - _animationController.value) * 100 * (entry.key + 1)),
                                    child: Opacity(
                                      opacity: _animationController.value,
                                      child: _buildGoalCard(entry.value, isTablet),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 40),
                            _buildConfirmButton(isTablet),
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
            'Zielauswahl',
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

  Widget _buildHeader(bool isTablet) {
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.flag,
              color: Colors.white,
              size: isTablet ? 40 : 35,
            ),
          ),
          SizedBox(height: isTablet ? 25 : 20),
          Text(
            'Was möchtest du erreichen?',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 15 : 12),
          Text(
            'Wähle dein Hauptziel und wir passen die App an deine Bedürfnisse an.',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal, bool isTablet) {
    final isSelected = _selectedGoal == goal['id'];
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 20),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGoal = goal['id'];
          });
          _cardController.forward().then((_) => _cardController.reverse());
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(isTablet ? 30 : (isSmallScreen ? 15 : 25)),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      goal['color'].withOpacity(0.3),
                      goal['color'].withOpacity(0.1),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2d3748),
                      Color(0xFF1a202c),
                    ],
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? goal['color'] 
                  : Colors.white.withOpacity(0.1),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected 
                    ? goal['color'].withOpacity(0.3) 
                    : Colors.black.withOpacity(0.2),
                blurRadius: isSelected ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 16 : (isSmallScreen ? 10 : 14)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          goal['color'],
                          goal['color'].withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: goal['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      goal['icon'],
                      size: isTablet ? 32 : (isSmallScreen ? 20 : 28),
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Text(
                      goal['title'],
                      style: TextStyle(
                        fontSize: isTablet ? 20 : (isSmallScreen ? 14 : 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),
              Text(
                goal['description'],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                  height: 1.4,
                ),
              ),
              SizedBox(height: isTablet ? 20 : (isSmallScreen ? 12 : 16)),
              ...(goal['features'] as List<String>).map((feature) => Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isSmallScreen ? 6 : 8,
                      height: isSmallScreen ? 6 : 8,
                      margin: EdgeInsets.only(
                        top: isSmallScreen ? 4 : 6, 
                        right: isSmallScreen ? 8 : 12
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [goal['color'], goal['color'].withOpacity(0.7)],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: isTablet ? 15 : (isSmallScreen ? 11 : 13),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 60 : 55,
      child: ElevatedButton(
        onPressed: _selectedGoal == null ? null : _saveSelectedGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _selectedGoal != null
                ? const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  )
                : LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.2),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _selectedGoal != null
                ? [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Container(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: isTablet ? 24 : 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ziel bestätigen',
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
    );
  }
} 