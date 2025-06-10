import 'package:flutter/material.dart';
// Importieren Sie hier andere notwendige Abhängigkeiten, falls der challengeDetailScreen verwendet wird
import 'package:lebenshygiene_anwendung/screens/challenge_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiniChallengesScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Daten für die Mini-Herausforderungen
  final Map<String, List<Map<String, dynamic>>> _miniChallengesData = {
    'Mini-Herausforderungen': [
      {'name': 'Digitale Detox Routine (7 Tage)', 'icon': Icons.phone_android},
      {'name': 'Fit-Aufwach-Routine (14 Tage)', 'icon': Icons.wb_sunny},
      {'name': 'Tiefschlaf-Routine (30 Tage)', 'icon': Icons.bedtime},
      {'name': '10k Schritte Challenge (7 Tage)', 'icon': Icons.directions_walk},
      {'name': 'Trink-Challenge (14 Tage)', 'icon': Icons.water_drop},
      {'name': 'Meditations-Challenge (30 Tage)', 'icon': Icons.self_improvement},
    ],
  };

  // Gewohnheiten, die mit Challenges verbunden sind
  final Map<String, List<String>> _challengeHabits = {
    'Digitale Detox Routine (7 Tage)': [
      'Smartphone erst nach dem Frühstück nutzen',
      'Social Media Nutzung auf 30 Minuten begrenzen',
      'Eine Stunde vor dem Schlafengehen keine Bildschirme',
    ],
    'Fit-Aufwach-Routine (14 Tage)': [
      'Direkt nach dem Aufwachen Wasser trinken',
      '10 Minuten Morgengymnastik',
      'Gesundes Frühstück',
    ],
    'Tiefschlaf-Routine (30 Tage)': [
      'Feste Schlafenszeit einhalten',
      'Entspannungsübungen vor dem Schlafengehen',
      'Koffeinfreie Getränke am Abend',
    ],
    '10k Schritte Challenge (7 Tage)': [
      'Tägliches Spazierengehen',
      'Treppen statt Aufzug nutzen',
      'Aktive Pausen einlegen',
    ],
    'Trink-Challenge (14 Tage)': [
      'Mindestens 2 Liter Wasser täglich',
      'Wassertrinkzeiten planen',
      'Zuckerhaltige Getränke reduzieren',
    ],
    'Meditations-Challenge (30 Tage)': [
      'Tägliche 10-Minuten Meditation',
      'Achtsamkeitsübungen',
      'Tägliche Dankbarkeitsmomente',
    ],
  };

  MiniChallengesScreen({super.key});

  // Funktion zum Hinzufügen von Gewohnheiten aus Challenges
  Future<void> _addHabitsFromChallenge(List<String> habits) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        
        for (var habit in habits) {
          final habitRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('habits')
              .doc();
              
          batch.set(habitRef, {
            'name': habit,
            'isCompleted': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error adding habits: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
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
                  'Mini-Herausforderungen',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                centerTitle: false,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final challenge = _miniChallengesData['Mini-Herausforderungen']![index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2d3748),
                          const Color(0xFF1a202c),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          challenge['icon'] as IconData,
                          color: const Color(0xFF667eea),
                          size: 28,
                        ),
                      ),
                      title: Text(
                        challenge['name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChallengeDetailScreen(
                              challenge: challenge,
                              challengeHabits: _challengeHabits[challenge['name']] ?? [],
                              onStartChallenge: _addHabitsFromChallenge,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                childCount: _miniChallengesData['Mini-Herausforderungen']?.length ?? 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 