import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CalorieCounterScreen extends StatefulWidget {
  const CalorieCounterScreen({super.key});

  @override
  State<CalorieCounterScreen> createState() => _CalorieCounterScreenState();
}

class _CalorieCounterScreenState extends State<CalorieCounterScreen> {
  int _portions = 0;
  int _maxPortions = 20;
  int _portionValue = 100; // 100 kcal
  int _kcalGoal = 2000;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoalAndCalories();
  }

  Future<void> _loadGoalAndCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        final zielKcalRaw = userDoc.data()?['zielKcal'];
        int kcalGoal;
        if (zielKcalRaw is int) {
          kcalGoal = zielKcalRaw;
        } else if (zielKcalRaw is double) {
          kcalGoal = zielKcalRaw.toInt();
        } else if (zielKcalRaw != null) {
          kcalGoal = int.tryParse(zielKcalRaw.toString()) ?? 2000;
        } else {
          kcalGoal = 2000;
        }
        _kcalGoal = kcalGoal;
        _maxPortions = (_kcalGoal / _portionValue).round();
      });
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final kcalDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    if (kcalDoc.exists) {
      setState(() {
        _portions = ((kcalDoc.data()?['kcal'] ?? 0) / _portionValue).round();
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .set({'kcal': _portions * _portionValue}, SetOptions(merge: true));
  }

  void _addPortion() {
    if (_portions < _maxPortions) {
      setState(() {
        _portions++;
      });
      _saveCalories();
    }
  }

  void _removePortion() {
    if (_portions > 0) {
      setState(() {
        _portions--;
      });
      _saveCalories();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalorienzähler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Kalorien', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Ziel: $_kcalGoal kcal', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text('${(_portions * _portionValue).toString()} kcal', style: const TextStyle(fontSize: 40, color: Colors.white)),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(_maxPortions, (index) {
                        bool filled = index < _portions;
                        return GestureDetector(
                          onTap: filled ? _removePortion : _addPortion,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: filled ? Colors.white : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Icon(
                                filled ? Icons.restaurant : Icons.add,
                                color: filled ? Colors.orange : Colors.orange.shade100,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 