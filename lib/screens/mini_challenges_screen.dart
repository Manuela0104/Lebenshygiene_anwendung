import 'package:flutter/material.dart';
// Importieren Sie hier andere notwendige Abhängigkeiten, falls der challengeDetailScreen verwendet wird
import 'package:lebenshygiene_anwendung/screens/challenge_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MiniChallengesScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MiniChallengesScreen({super.key});

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
      'Bildschirmzeit vor dem Schlafengehen begrenzen',
      'Von sozialen Medien abmelden',
      'Telefon nachts in den Flugmodus schalten',
      'Netzwerke während der Mahlzeiten deaktivieren',
      'Unnötige Apps löschen', // Diese Gewohnheit ist eher einmalig, bei Bedarf anpassen
    ],
    'Fit-Aufwach-Routine (14 Tage)': [
      'Jeden Tag zur gleichen Zeit ins Bett gehen',
      '7-9 Stunden schlafen', // Oder ein Schlafziel
      '1 Stunde vor dem Schlafengehen Bildschirme vermeiden',
      'Gesundes Frühstück essen',
      '15 Minuten Sport / Yoga / Stretching machen',
    ],
    'Tiefschlaf-Routine (30 Tage)': [
      '7-9 Stunden schlafen',
      'Jeden Tag zur gleichen Zeit ins Bett gehen',
      '1 Stunde vor dem Schlafengehen Bildschirme vermeiden',
      'Einen Kräutertee trinken oder ein Ritual machen',
      'Ein luftiges und aufgeräumtes Zimmer halten',
    ],
    '10k Schritte Challenge (7 Tage)': [
      '10.000 Schritte gehen',
      'Treppe statt Aufzug nehmen', // Aktivität steigern
      'Nach dem Mittagessen spazieren gehen', // Aktivität steigern
    ],
    'Trink-Challenge (14 Tage)': [
      '2 Liter Wasser trinken',
      'Einen Kräutertee trinken oder ein Ritual machen', // Flüssigkeitszufuhr fördern
    ],
    'Meditations-Challenge (30 Tage)': [
      '10 Minuten meditieren',
      'Beruhigende Musik hören', // Kann bei Meditation/Entspannung helfen
    ]
  };

  // Funktion zum Hinzufügen von Gewohnheiten aus Challenges
  Future<void> _addHabitsFromChallenge(List<String> habitNames) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final batch = _firestore.batch();
    
    // Vorhandene Gewohnheiten laden, um Duplikate zu vermeiden
    final existingHabitsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('habits')
        .get();
    
    final existingHabitNames = existingHabitsSnapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .toSet(); // Ein Set für schnelle Suche verwenden
    
    for (final habitName in habitNames) {
      if (!existingHabitNames.contains(habitName)) {
        final newHabitRef = _firestore.collection('users').doc(user.uid).collection('habits').doc();
        batch.set(newHabitRef, {
          'name': habitName,
          'category': 'Challenges', // Standardkategorie für Challenge-Gewohnheiten
          // TODO: Falls nötig, spezifische Challenge-Felder hinzufügen (z.B. challengeName, endDate)
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    try {
      await batch.commit();
      debugPrint('Gewohnheiten aus Challenge hinzugefügt.');
      // TODO: Gewohnheitenliste in HabitTrackerScreen neu laden, falls nötig
    } catch (e) {
      debugPrint('Fehler beim Hinzufügen von Gewohnheiten aus Challenge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-Herausforderungen'),
      ),
      body: ListView.builder(
        itemCount: _miniChallengesData['Mini-Herausforderungen']?.length ?? 0,
        itemBuilder: (context, index) {
          final challenge = _miniChallengesData['Mini-Herausforderungen']![index];
          return ListTile(
            leading: Icon(challenge['icon'] as IconData),
            title: Text(challenge['name']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
            onTap: () {
              // Zum Detailbildschirm der Challenge navigieren
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailScreen(
                    challenge: challenge,
                    challengeHabits: _challengeHabits[challenge['name']] ?? [], // Zugehörige Gewohnheiten übergeben
                    onStartChallenge: _addHabitsFromChallenge,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 