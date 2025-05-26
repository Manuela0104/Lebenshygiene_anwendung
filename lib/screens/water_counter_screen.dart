import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WaterCounterScreen extends StatefulWidget {
  const WaterCounterScreen({super.key});

  @override
  State<WaterCounterScreen> createState() => _WaterCounterScreenState();
}

class _WaterCounterScreenState extends State<WaterCounterScreen> {
  int _glasses = 0;
  int _maxGlasses = 8;
  final double _glassVolume = 0.25; // 250ml
  double _waterGoal = 2.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGoalAndWater();
  }

  Future<void> _loadGoalAndWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      setState(() {
        _waterGoal = (userDoc.data()?['zielWater'] ?? 2.0).toDouble();
        _maxGlasses = (_waterGoal / _glassVolume).round();
      });
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final waterDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    if (waterDoc.exists) {
      setState(() {
        _glasses = ((waterDoc.data()?['water'] ?? 0.0) / _glassVolume).round();
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _saveWater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('dailyData')
        .doc(dateStr)
        .set({'water': _glasses * _glassVolume}, SetOptions(merge: true));
  }

  void _addGlass() {
    if (_glasses < _maxGlasses) {
      setState(() {
        _glasses++;
      });
      _saveWater();
    }
  }

  void _removeGlass() {
    if (_glasses > 0) {
      setState(() {
        _glasses--;
      });
      _saveWater();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wasserzähler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade200,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Wasser', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Ziel: ${_waterGoal.toStringAsFixed(2)} L', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text('${(_glasses * _glassVolume).toStringAsFixed(2)} L', style: const TextStyle(fontSize: 40, color: Colors.white)),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: List.generate(_maxGlasses, (index) {
                        bool filled = index < _glasses;
                        return GestureDetector(
                          onTap: filled ? _removeGlass : _addGlass,
                          child: Container(
                            width: 40,
                            height: 80,
                            decoration: BoxDecoration(
                              color: filled ? Colors.white : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: filled
                                ? null
                                : const Center(child: Icon(Icons.add, color: Colors.blue)),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text('+ Wasser aus Lebensmitteln: 0 ml', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
    );
  }
} 