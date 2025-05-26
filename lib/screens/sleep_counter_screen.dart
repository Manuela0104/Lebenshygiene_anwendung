import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SleepCounterScreen extends StatefulWidget {
  const SleepCounterScreen({super.key});

  @override
  State<SleepCounterScreen> createState() => _SleepCounterScreenState();
}

class _SleepCounterScreenState extends State<SleepCounterScreen> {
  int _hours = 0;
  int _maxHours = 8;
  double _sleepGoal = 8.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoalAndSleep();
  }

  Future<void> _loadGoalAndSleep() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _sleepGoal = (userDoc.data()?['zielSleep'] ?? 8.0).toDouble();
        _maxHours = _sleepGoal.round();
      });
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final sleepDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    if (sleepDoc.exists) {
      setState(() {
        _hours = (sleepDoc.data()?['sleep'] ?? 0.0).round();
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveSleep() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .set({'sleep': _hours.toDouble()}, SetOptions(merge: true));
  }

  void _addHour() {
    if (_hours < _maxHours) {
      setState(() {
        _hours++;
      });
      _saveSleep();
    }
  }

  void _removeHour() {
    if (_hours > 0) {
      setState(() {
        _hours--;
      });
      _saveSleep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schlafzähler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade200,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Schlaf', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Ziel: ${_sleepGoal.toStringAsFixed(1)} h', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text('${_hours.toString().padLeft(2, '0')}:00 h', style: const TextStyle(fontSize: 40, color: Colors.white)),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(_maxHours, (index) {
                        bool filled = index < _hours;
                        return GestureDetector(
                          onTap: filled ? _removeHour : _addHour,
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
                                filled ? Icons.nightlight_round : Icons.add,
                                color: filled ? Colors.indigo : Colors.indigo.shade100,
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