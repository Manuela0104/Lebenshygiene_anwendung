import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Map<String, dynamic>> _reminders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reminders')
            .get();
        setState(() {
          _reminders = snapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'title': doc['title'],
                    'time': (doc['time'] as Timestamp).toDate(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Laden von Erinnerungen.';
      });
    }
  }

  Future<void> _saveReminders() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('reminders');
        // Bestehende Erinnerungen löschen
        final snapshot = await ref.get();
        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        // Neue Erinnerungen speichern
        for (var reminder in _reminders) {
          await ref.add({
            'title': reminder['title'],
            'time': reminder['time'],
          });
        }
        setState(() => _isLoading = false);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Fehler beim Speichern.';
      });
    }
  }

  void _addReminder() {
    setState(() {
      _reminders.add({
        'title': '',
        'time': DateTime.now(),
      });
    });
  }

  void _removeReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminders[index]['time']),
    );
    if (picked != null) {
      final now = DateTime.now();
      final newTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() {
        _reminders[index]['time'] = newTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erinnerungen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        final reminder = _reminders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.alarm),
                            title: TextFormField(
                              initialValue: reminder['title'],
                              decoration: const InputDecoration(
                                hintText: 'Titel der Erinnerung',
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => _reminders[index]['title'] = value,
                            ),
                            subtitle: InkWell(
                              onTap: () => _pickTime(index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 5),
                                    Text(DateFormat('HH:mm').format(reminder['time'])),
                                  ],
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeReminder(index),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Erinnerung hinzufügen'),
                        onPressed: _addReminder,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 150,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _saveReminders,
                          child: const Text('Speichern', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
