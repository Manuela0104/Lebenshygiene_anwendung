import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _habits = [];
  Map<String, bool> _completionStatus = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _streakCount = 0;
  double _progressPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  // Hilfsfunktion für Icon-Zuordnung
  IconData _getIconFromCode(int? iconCode) {
    if (iconCode == null) return Icons.check_circle_outline;
    
    // Vordefinierte Icon-Zuordnungen für häufige Icons
    switch (iconCode) {
      case 0xe3c9: return Icons.water_drop;
      case 0xe3c7: return Icons.directions_walk;
      case 0xe3c8: return Icons.bedtime;
      case 0xe3c6: return Icons.shower;
      case 0xe3c5: return Icons.fitness_center;
      case 0xe3c4: return Icons.restaurant;
      case 0xe3c3: return Icons.book;
      case 0xe3c2: return Icons.music_note;
      case 0xe3c1: return Icons.brush;
      case 0xe3c0: return Icons.self_improvement;
      default: return Icons.check_circle_outline;
    }
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('habits')
            .get();

        setState(() {
          _habits = snapshot.docs.map((doc) {
            final data = doc.data();
            final iconCode = data['iconCode'] as int?;
            return {
              'id': doc.id,
              'name': data['name'] as String? ?? 'Unbenannte Gewohnheit',
              'icon': _getIconFromCode(iconCode),
            };
          }).toList();
        });

        await _loadCompletionStatus();
        await _loadStreak();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Gewohnheiten: $e';
      });
      debugPrint(_errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCompletionStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final today = DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(today);
        
        final statusDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('daily_status')
            .doc(dateStr)
            .get();

        final completed = statusDoc.exists 
            ? List<String>.from(statusDoc.data()?['completed'] ?? [])
            : <String>[];
        
        setState(() {
          _completionStatus = Map.fromIterable(
            _habits,
            key: (habit) => habit['id'] as String,
            value: (habit) => completed.contains(habit['id']),
          );
          
          // Aktualisiere den Fortschritt
          _updateProgress();
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Status: $e');
    }
  }

  void _updateProgress() {
    if (_habits.isEmpty) {
      setState(() => _progressPercentage = 0.0);
      return;
    }
    
    final completedCount = _completionStatus.values.where((v) => v).length;
    setState(() {
      _progressPercentage = completedCount / _habits.length;
    });
  }

  Future<void> _loadStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final streakDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streak')
            .get();

        setState(() {
          _streakCount = streakDoc.data()?['currentStreak'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Streaks: $e');
    }
  }

  Future<void> _toggleHabit(String habitId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);
    final newStatus = !(_completionStatus[habitId] ?? false);

    setState(() {
      _completionStatus[habitId] = newStatus;
      _updateProgress();
    });

    try {
      final statusRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_status')
          .doc(dateStr);

      await _firestore.runTransaction((transaction) async {
        final statusDoc = await transaction.get(statusRef);
        final completed = statusDoc.exists 
            ? List<String>.from(statusDoc.data()?['completed'] ?? [])
            : <String>[];
        
        if (newStatus) {
          completed.add(habitId);
        } else {
          completed.remove(habitId);
        }

        transaction.set(statusRef, {
          'completed': completed,
          'date': dateStr,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      if (newStatus) {
        await _updateStreak();
      }
    } catch (e) {
      setState(() {
        _completionStatus[habitId] = !newStatus;
        _updateProgress();
        _errorMessage = 'Fehler beim Aktualisieren: $e';
      });
      debugPrint(_errorMessage);
    }
  }

  Future<void> _updateStreak() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final streakRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streak');

        await _firestore.runTransaction((transaction) async {
          final streakDoc = await transaction.get(streakRef);
          final currentStreak = streakDoc.data()?['currentStreak'] ?? 0;
          
          transaction.set(streakRef, {
            'currentStreak': currentStreak + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          setState(() {
            _streakCount = currentStreak + 1;
          });
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Aktualisieren des Streaks: $e');
    }
  }

  Future<void> _addNewHabit() async {
    final TextEditingController nameController = TextEditingController();
    IconData selectedIcon = Icons.check_circle_outline;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Neue Gewohnheit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Name der Gewohnheit',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFF1a1a2e),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF667eea)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildIconOption(Icons.water_drop, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
                _buildIconOption(Icons.directions_walk, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
                _buildIconOption(Icons.nightlight_round, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
                _buildIconOption(Icons.phone_android_outlined, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
                _buildIconOption(Icons.self_improvement, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
                _buildIconOption(Icons.bedtime, selectedIcon, (icon) {
                  setState(() => selectedIcon = icon);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'icon': selectedIcon,
                });
              }
            },
            child: const Text(
              'Hinzufügen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.all(20),
      ),
    ).then((value) async {
      if (value != null) {
        try {
          final user = _auth.currentUser;
          if (user != null) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('habits')
                .add({
              'name': value['name'],
              'iconCode': (value['icon'] as IconData).codePoint,
              'createdAt': FieldValue.serverTimestamp(),
            });
            
            await _loadHabits();
          }
        } catch (e) {
          setState(() {
            _errorMessage = 'Fehler beim Hinzufügen: $e';
          });
          debugPrint(_errorMessage);
        }
      }
    });
  }

  Widget _buildIconOption(IconData icon, IconData selectedIcon, Function(IconData) onSelect) {
    final isSelected = icon == selectedIcon;
    
    return GestureDetector(
      onTap: () => onSelect(icon),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF667eea) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF667eea) : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Future<void> _deleteHabit(String habitId, String habitName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Gewohnheit löschen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Möchtest du die Gewohnheit "$habitName" wirklich löschen?',
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
            ),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
        actionsPadding: const EdgeInsets.all(20),
      ),
    );

    if (confirm == true) {
      try {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('habits')
              .doc(habitId)
              .delete();

          // Aktualisiere die Liste
          await _loadHabits();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$habitName wurde gelöscht'),
                backgroundColor: const Color(0xFF2d3748),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Fehler beim Löschen: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Fehler beim Löschen der Gewohnheit'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          'Meine Gewohnheiten',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF43e97b),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHabits,
              color: const Color(0xFF43e97b),
              backgroundColor: const Color(0xFF2d3748),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fortschrittsbereich
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16213E),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Heute',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd. MMMM yyyy', 'de_DE').format(DateTime.now()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Fortschrittsbalken
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progressPercentage,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43e97b)),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(_progressPercentage * 100).toInt()}% geschafft',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF43e97b).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_completionStatus.values.where((v) => v).length}/${_habits.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF43e97b),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Streak-Anzeige
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213E).withOpacity(0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_fire_department,
                              color: Color(0xFFFF6B6B),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_streakCount Tage Streak! 🔥',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Weiter so! Bleib am Ball und erreiche deine Ziele.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Liste der Gewohnheiten
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tägliche Gewohnheiten',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_habits.isEmpty)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Keine Gewohnheiten vorhanden',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Füge neue Gewohnheiten hinzu, um deine Ziele zu erreichen',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._habits.map((habit) => _buildHabitTile(habit)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewHabit,
        backgroundColor: const Color(0xFF43e97b),
        icon: const Icon(Icons.add),
        label: const Text('Neue Gewohnheit'),
      ),
    );
  }

  Widget _buildHabitTile(Map<String, dynamic> habit) {
    final isCompleted = _completionStatus[habit['id']] ?? false;
    
    return Dismissible(
      key: Key(habit['id']),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteHabit(habit['id'], habit['name']);
      },
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2d3748),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Text(
              'Gewohnheit löschen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Möchtest du die Gewohnheit "${habit['name']}" wirklich löschen?',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                ),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Löschen'),
              ),
            ],
            actionsPadding: const EdgeInsets.all(20),
          ),
        );
      },
      child: GestureDetector(
        onLongPress: () => _deleteHabit(habit['id'], habit['name']),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => _toggleHabit(habit['id']),
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                habit['icon'],
                color: isCompleted ? Colors.white : Colors.white54,
                size: 24,
              ),
              title: Text(
                habit['name'],
                style: TextStyle(
                  color: isCompleted ? Colors.white : Colors.white54,
                  fontSize: 16,
                ),
              ),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? const Color(0xFF43e97b) : Colors.white24,
                    width: 2,
                  ),
                  color: isCompleted ? const Color(0xFF43e97b) : Colors.transparent,
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}