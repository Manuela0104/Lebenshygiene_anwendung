import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pedometer/pedometer.dart';
import 'package:intl/intl.dart';
import 'fragebogen.dart';
import 'water_counter_screen.dart';
import 'sleep_counter_screen.dart';
import 'calorie_counter_screen.dart';
import 'habit_tracker_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _steps = 0;
  int _stepsGoal = 10000;
  double _water = 1.2; // en litres
  double _waterGoal = 2.0;
  double _sleep = 7.0; // en heures
  double _sleepGoal = 8.0;
  int _kcal = 1200;
  int _kcalGoal = 2000;
  double _weight = 66.0;
  double _height = 170.0;
  DateTime _selectedDate = DateTime.now();
  String? _weightRecommendation; // Variable to store the recommendation

  @override
  void initState() {
    super.initState();
    _loadUserGoals();
    _loadDailyData(_selectedDate);
  }

  Future<void> _loadUserGoals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _kcalGoal = (data['zielKcal'] ?? 2000) is int ? data['zielKcal'] : int.tryParse(data['zielKcal'].toString()) ?? 2000;
        _sleepGoal = (data['zielSleep'] ?? 8.0) is double ? data['zielSleep'] : double.tryParse(data['zielSleep'].toString()) ?? 8.0;
        _waterGoal = (data['zielWater'] ?? 2.0) is double ? data['zielWater'] : double.tryParse(data['zielWater'].toString()) ?? 2.0;
        _stepsGoal = (data['zielSteps'] ?? 10000) is int ? data['zielSteps'] : int.tryParse(data['zielSteps'].toString()) ?? 10000;
      });
    }
  }

  Future<void> _loadDailyData(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      if (!mounted) return;
      setState(() {
        _steps = (data['steps'] ?? 0) as int;
        _water = (data['water'] ?? 0.0).toDouble();
        _sleep = (data['sleep'] ?? 0.0).toDouble();
        _kcal = (data['kcal'] ?? 0) as int;
        _weight = (data['weight'] ?? 0.0).toDouble();
        _height = (data['height'] ?? 0.0).toDouble();
      });
      // Si le poids est absent ou nul, charger depuis le profil utilisateur
      if ((data['weight'] == null || data['weight'] == 0.0)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (!mounted) return;
          setState(() {
            _weight = (userData['weight'] ?? 66.0).toDouble();
          });
        }
      }
      // Si la taille est absente ou nulle, charger depuis le profil utilisateur
      if ((data['height'] == null || data['height'] == 0.0)) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (!mounted) return;
          setState(() {
            _height = (userData['height'] ?? 170.0).toDouble();
          });
        }
      }
    } else {
      if (!mounted) return;
      setState(() {
        _steps = 0;
        _water = 0.0;
        _sleep = 0.0;
        _kcal = 0;
      });
      // Charger la taille et le poids depuis le profil utilisateur
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (!mounted) return;
        setState(() {
          _height = (userData['height'] ?? 170.0).toDouble();
          _weight = (userData['weight'] ?? 66.0).toDouble();
        });
      }
    }
    // After loading weight and height, update the recommendation
    _updateWeightRecommendation();
  }

  double _calculateBMI() {
    if (_height <= 0) return 0;
    return _weight / ((_height / 100) * (_height / 100));
  }

  String _bmiStatus(double bmi) {
    if (bmi < 18.5) return 'Abmagerung';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Übergewicht';
    return 'Fettleibigkeit';
  }

  // New function to calculate weight recommendation
  void _updateWeightRecommendation() {
    final bmi = _calculateBMI();
    String? recommendation;
    if (bmi > 24.9 && _height > 0) {
      final idealWeightMax = 24.9 * (_height / 100) * (_height / 100);
      final weightToLose = _weight - idealWeightMax;
      if (weightToLose > 0) {
        recommendation = 'Abnehmen: ca. ${weightToLose.toStringAsFixed(1)} kg';
      } else {
         recommendation = 'IMC fast im Normalbereich.'; // Close to normal
      }
    } else if (bmi < 18.5 && _height > 0) {
      final idealWeightMin = 18.5 * (_height / 100) * (_height / 100);
      final weightToGain = idealWeightMin - _weight;
      if (weightToGain > 0) {
         recommendation = 'Zunehmen: ca. ${weightToGain.toStringAsFixed(1)} kg';
      } else {
        recommendation = 'IMC fast im Normalbereich.'; // Close to normal
      }
    }

    if (!mounted) return;
    setState(() {
      _weightRecommendation = recommendation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EAF6),
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != _selectedDate) {
                setState(() {
                  _selectedDate = picked;
                });
                await _loadDailyData(picked);
              }
            },
            tooltip: 'Kalender',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Übersicht (cercle central)
            Card(
              color: const Color(0xFFF3CFE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Cercle central : nombre de pas / objectif
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_walk, color: Colors.pinkAccent, size: 22),
                        SizedBox(width: 6),
                        Text('Schritte heute', style: TextStyle(color: Colors.black54, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CircularPercentIndicator(
                      radius: 70,
                      lineWidth: 12,
                      percent: (_steps / _stepsGoal).clamp(0.0, 1.0),
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$_steps', style: const TextStyle(fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold)),
                          Text('von $_stepsGoal', style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                      progressColor: Colors.pinkAccent,
                      backgroundColor: Colors.pink[100]!,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WaterCounterScreen(),
                              ),
                            );
                          },
                          child: _buildProgressBar('Wasser', _water, _waterGoal, Colors.pink[300]!, 'L'),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SleepCounterScreen(),
                              ),
                            );
                          },
                          child: _buildProgressBar('Schlaf', _sleep, _sleepGoal, Colors.pink[200]!, 'h'),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CalorieCounterScreen(),
                              ),
                            );
                          },
                          child: _buildProgressBar('Kalorien', _kcal.toDouble(), _kcalGoal.toDouble(), Colors.pink[400]!, 'kcal'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Kategorien
            Text('Kategorien', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFFF3CFE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildCategoryTile(Icons.check_circle, 'Habit Tracker', Colors.amber, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                  _buildCategoryTile(Icons.star, 'Mini-Herausforderungen', Colors.blueAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                  _buildCategoryTile(Icons.show_chart, 'Trends & Berichte', Colors.greenAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                  _buildCategoryTile(Icons.notifications_active, 'Intelligente Erinnerungen', Colors.orangeAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                  _buildCategoryTile(Icons.sentiment_satisfied_alt, 'Stimmungs-Tracker', Colors.purpleAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                  _buildCategoryTile(Icons.assistant, 'Virtueller Coach', Colors.tealAccent, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HabitTrackerScreen(),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Gewicht, Größe, BMI
            Card(
              color: const Color(0xFFF3CFE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoTile('Gewicht', '${_weight.toStringAsFixed(1)} kg', Icons.monitor_weight, Colors.orange),
                    _buildInfoTile('Größe', '${_height.toStringAsFixed(1)} cm', Icons.height, Colors.pink),
                    _buildInfoTile(
                      'BMI',
                      _calculateBMI().toStringAsFixed(1),
                      Icons.calculate,
                      Colors.pinkAccent,
                      bmiStatus: _bmiStatus(_calculateBMI()),
                      weightRecommendation: _weightRecommendation,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, double goal, Color color, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          width: 70,
          lineHeight: 8,
          percent: (value / goal).clamp(0.0, 1.0),
          progressColor: color,
          backgroundColor: Colors.pink[100],
        ),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} $unit', style: const TextStyle(color: Colors.black54, fontSize: 10)),
      ],
    );
  }

  Widget _buildCategoryTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color, size: 32),
      title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 16)),
      trailing: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(Icons.add, color: color),
          onPressed: onTap,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color, {String? bmiStatus, String? weightRecommendation}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        if (bmiStatus != null)
          Text(bmiStatus, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        if (weightRecommendation != null)
          Text(weightRecommendation, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}