import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ChallengeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

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
            // Hier können weitere Details und die Start-Logik hinzugefügt werden
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementiere Logik zum Starten des Challenges
                  debugPrint('Challenge starten: ${challenge['name']}');
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