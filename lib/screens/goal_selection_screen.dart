import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedGoal;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'organization',
      'title': 'Bessere Organisation des Alltags',
      'icon': Icons.schedule,
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
            const SnackBar(content: Text('Ziel erfolgreich gespeichert!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wähle dein Ziel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Was möchtest du erreichen?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ..._goals.map((goal) => _buildGoalCard(goal)).toList(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _selectedGoal == null ? null : _saveSelectedGoal,
                    child: const Text('Ziel bestätigen'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoal == goal['id'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: isSelected ? Colors.pink[50] : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGoal = goal['id'];
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(goal['icon'], size: 32, color: Colors.pink),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                goal['description'],
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ...(goal['features'] as List<String>).map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature),
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
} 