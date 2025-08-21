import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Challenge-Detail-Bildschirm für detaillierte Informationen zu Herausforderungen
/// 
/// Bietet Funktionalitäten für:
/// - Detaillierte Anzeige von Challenge-Informationen
/// - Auflistung aller enthaltenen Gewohnheiten
/// - Start-Funktionalität für neue Challenges
/// - Integration mit dem Challenge-Management-System
/// - Übersichtliche Darstellung der Challenge-Anforderungen
/// 
/// Der Bildschirm dient als Informationszentrum für
/// Benutzer, die mehr über eine Challenge erfahren möchten.
class ChallengeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final List<String> challengeHabits;
  final Function(List<String>) onStartChallenge;

  const ChallengeDetailScreen({super.key, required this.challenge, required this.challengeHabits, required this.onStartChallenge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(challenge['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beschreibung und Details für ${challenge['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enthaltende Gewohnheiten:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: challengeHabits.map((habit) => Text('- $habit')).toList(),
            ),
            const SizedBox(height: 24),
            // Hier können weitere Details und die Start-Logik hinzugefügt werden
            Center(
              child: ElevatedButton(
                onPressed: () {
                  onStartChallenge(challengeHabits);
                  Navigator.pop(context); // Bildschirm nach dem Start der Challenge schließen
                },
                child: const Text('Challenge starten'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 