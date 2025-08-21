import 'package:flutter/material.dart';

/// Training-Bildschirm für Fitness- und Trainings-Tracking
/// 
/// Bietet Funktionalitäten für:
/// - Trainingsplanung und -überwachung
/// - Übungs-Tracking
/// - Fitness-Ziele und -fortschritt
/// - Trainingsstatistiken
/// 
/// Hinweis: Dieser Bildschirm ist derzeit in Entwicklung
/// und wird in zukünftigen Versionen erweitert.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Training Screen - Coming Soon'),
      ),
    );
  }
} 