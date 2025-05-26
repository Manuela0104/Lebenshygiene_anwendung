import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<Map<String, dynamic>> _habits = [];
  Map<String, bool> _dailyCompletionStatus = {};
  final TextEditingController _newHabitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadHabits();
      _loadDailyCompletionStatus();
    }
  }

  @override
  void dispose() {
    _newHabitController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadHabits() async {
    if (_user == null) return;
    try {
      final habitsSnapshot = await _firestore.collection('users').doc(_user!.uid).collection('habits').get();
      setState(() {
        _habits = habitsSnapshot.docs.map((doc) => {...
// ... existing code ...
        title: const Text('Habit Tracker'), // Will be localized later
      ),
      body: _user == null
          ? const Center(child: Text('Bitte melden Sie sich an, um den Habit Tracker zu nutzen.')) // Localize this later
          : ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                final habit = _habits[index];
                final isCompleted = _dailyCompletionStatus[habit['name']] ?? false;
                return ListTile(
                  title: Text(habit['name']),
                  trailing: Checkbox(
                    value: isCompleted,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        _updateCompletionStatus(habit['name'], newValue);
                      }
                    },
                  ),
                );
              },
            ),
      floatingActionButton: _user == null
          ? null
          : FloatingActionButton(
              onPressed: _addNewHabitDialog,
              tooltip: 'Add New Habit', // Will be localized later
              child: const Icon(Icons.add),
            ),
    );
  }
} 