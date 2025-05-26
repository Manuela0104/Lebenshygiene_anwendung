import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fl_chart/fl_chart.dart';
import 'package:lebenshygiene_anwendung/screens/challenge_detail_screen.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  List<Map<String, dynamic>> _habits = [];
  Map<String, bool> _dailyCompletionStatus = {};
  final TextEditingController _newHabitController = TextEditingController();
  late TabController _tabController;
  Map<String, double> _categoryCompletionRates = {};
  List<Map<String, dynamic>> _topHabits = [];
  Map<String, List<bool>> _weeklyProgress = {};
  Map<String, List<double>> _monthlyProgress = {};
  List<Map<String, dynamic>> _dailyStats = [];
  List<Map<String, dynamic>> _dailyStepsData = [];
  Map<String, double> _categoryGoals = {};
  double _userWeight = 0.0;
  double _averageWeeklySleep = 0.0;
  String _selectedPeriod = 'Woche';
  final List<String> _periods = ['Woche', 'Monat', 'Jahr'];

  final Map<String, List<Map<String, dynamic>>> _defaultHabits = {
    'Körperhygiene': [
      {'name': 'Zähne 2x täglich putzen', 'icon': Icons.brush},
      {'name': 'Täglich duschen', 'icon': Icons.shower},
      {'name': 'Gesichtspflege / Pflegeroutine', 'icon': Icons.face},
      {'name': 'Saubere Kleidung anziehen', 'icon': Icons.checkroom},
      {'name': 'Nägel schneiden / Epilieren', 'icon': Icons.content_cut},
      {'name': 'Haare waschen (1-2x pro Woche)', 'icon': Icons.water_drop},
      {'name': 'Wäsche waschen / Bettwäsche wechseln', 'icon': Icons.local_laundry_service},
    ],
    'Ernährung und Flüssigkeitszufuhr': [
      {'name': '2 L Wasser trinken', 'icon': Icons.water},
      {'name': '5 Portionen Obst und Gemüse', 'icon': Icons.restaurant},
      {'name': 'Gesundes Frühstück', 'icon': Icons.breakfast_dining},
      {'name': 'Zucker und verarbeitete Lebensmittel vermeiden', 'icon': Icons.no_food},
      {'name': 'Keine Snacks zwischen den Mahlzeiten', 'icon': Icons.timer},
      {'name': 'Bewusst essen ohne Bildschirm', 'icon': Icons.no_meals},
      {'name': 'Nahrungsergänzungsmittel einnehmen', 'icon': Icons.medication},
    ],
    'Körperliche Aktivität': [
      {'name': '10.000 Schritte gehen', 'icon': Icons.directions_walk},
      {'name': 'Treppe statt Aufzug', 'icon': Icons.stairs},
      {'name': '15 Minuten Sport / Yoga / Stretching', 'icon': Icons.fitness_center},
      {'name': 'Nachmittagsspaziergang', 'icon': Icons.directions_run},
      {'name': 'Trainingsprogramm absolvieren', 'icon': Icons.sports_gymnastics},
      {'name': 'Aktive Pausen einlegen', 'icon': Icons.timer},
    ],
    'Mentale Hygiene & Wohlbefinden': [
      {'name': '10 Minuten meditieren', 'icon': Icons.self_improvement},
      {'name': 'Tagebuch führen', 'icon': Icons.edit_note},
      {'name': 'Ein Kapitel lesen', 'icon': Icons.menu_book},
      {'name': 'Kreative Aktivität', 'icon': Icons.palette},
      {'name': 'Social Media Pause', 'icon': Icons.no_accounts},
      {'name': 'Bildschirmzeit vor dem Schlafen reduzieren', 'icon': Icons.nightlight},
      {'name': 'Beruhigende Musik hören', 'icon': Icons.music_note},
      {'name': 'Zeit draußen / in der Sonne verbringen', 'icon': Icons.wb_sunny},
    ],
    'Schlaf': [
      {'name': '7-9 Stunden schlafen', 'icon': Icons.bedtime},
      {'name': 'Regelmäßige Schlafenszeit', 'icon': Icons.access_time},
      {'name': '1 Stunde vor dem Schlafen keine Bildschirme', 'icon': Icons.no_photography},
      {'name': 'Tee trinken / Entspannungsritual', 'icon': Icons.local_cafe},
      {'name': 'Schlafzimmer lüften und aufräumen', 'icon': Icons.cleaning_services},
    ],
    'Tagesablauf & Organisation': [
      {'name': 'Morgens To-Do-Liste erstellen', 'icon': Icons.checklist},
      {'name': 'Mahlzeiten planen', 'icon': Icons.restaurant_menu},
      {'name': '10 Minuten aufräumen', 'icon': Icons.cleaning_services},
      {'name': 'Budget führen / Ausgaben notieren', 'icon': Icons.account_balance_wallet},
      {'name': 'Wichtige E-Mails beantworten', 'icon': Icons.mail},
    ],
    'Soziale Beziehungen': [
      {'name': 'Kontakt zu Freunden/Familie', 'icon': Icons.people},
      {'name': 'Danke sagen / Komplimente machen', 'icon': Icons.favorite},
      {'name': 'Nicht den ganzen Tag isolieren', 'icon': Icons.group},
      {'name': 'An Gruppenaktivitäten teilnehmen', 'icon': Icons.event},
    ],
    'Digitale Hygiene': [
      {'name': 'Benachrichtigungen einschränken', 'icon': Icons.notifications_off},
      {'name': 'Nachts Flugmodus aktivieren', 'icon': Icons.airplanemode_active},
      {'name': 'Unnötige Apps löschen', 'icon': Icons.delete},
      {'name': 'Social Media während der Mahlzeiten deaktivieren', 'icon': Icons.no_meals},
    ],
  };

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _tabController = TabController(length: _defaultHabits.length + 1, vsync: this);
    if (_user != null) {
      _loadHabits();
      _loadDailyCompletionStatus();
      _loadStatistics();
      _loadDailyStatsForPeriod();
      _loadCategoryGoals();
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _newHabitController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadHabits() async {
    if (_user == null) return;
    try {
      final habitsSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('habits')
          .get();
      
      setState(() {
        _habits = habitsSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc.data()['name'] as String,
                  'category': doc.data()['category'] as String,
                  'icon': Icons.check_circle, // Default icon
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading habits: $e');
    }
  }

  Future<void> _loadDailyCompletionStatus() async {
    if (_user == null) return;
    try {
      final today = _getCurrentDate();
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_status')
          .doc(today)
          .get();

      if (statusSnapshot.exists) {
        setState(() {
          _dailyCompletionStatus = Map<String, bool>.from(statusSnapshot.data() ?? {});
        });
      }
    } catch (e) {
      debugPrint('Error loading daily status: $e');
    }
  }

  Future<void> _updateCompletionStatus(String habitName, bool isCompleted) async {
    if (_user == null) return;
    try {
      final today = _getCurrentDate();
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_status')
          .doc(today)
          .set({
        habitName: isCompleted,
      }, SetOptions(merge: true));

      setState(() {
        _dailyCompletionStatus[habitName] = isCompleted;
      });
      await _loadStatistics();
      await _saveDailyStats();
    } catch (e) {
      debugPrint('Error updating completion status: $e');
    }
  }

  Future<void> _addNewHabitDialog() async {
    String selectedCategory = _defaultHabits.keys.first;
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Neue Gewohnheit hinzufügen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newHabitController,
                decoration: const InputDecoration(
                  hintText: 'Name der Gewohnheit eingeben',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: _defaultHabits.keys.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Kategorie',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                if (_newHabitController.text.isNotEmpty) {
                  await _addNewHabit(_newHabitController.text, selectedCategory);
                  _newHabitController.clear();
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewHabit(String habitName, String category) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('habits')
          .add({
        'name': habitName,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _loadHabits();
    } catch (e) {
      debugPrint('Error adding new habit: $e');
    }
  }

  Future<void> _loadUserData() async {
    if (_user == null) return;
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        if (mounted) {
          setState(() {
            _userWeight = (userData['weight'] ?? 0.0).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadStatistics() async {
    if (_user == null) return;
    
    // Charger les données de la semaine
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    Map<String, List<bool>> weeklyData = {};
    Map<String, int> habitCompletions = {};
    Map<String, int> categoryCompletions = {};
    Map<String, int> categoryTotal = {};
    List<double> weeklySleepData = [];
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_status')
          .doc(dateStr)
          .get();
      
      final dailyDataSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('dailyData')
          .doc(dateStr)
          .get();
      
      if (dailyDataSnapshot.exists) {
        final data = dailyDataSnapshot.data() as Map<String, dynamic>;
        weeklySleepData.add((data['sleep'] ?? 0.0).toDouble());
      }
      
      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        
        data.forEach((habitName, isCompleted) {
          if (isCompleted == true) {
            habitCompletions[habitName] = (habitCompletions[habitName] ?? 0) + 1;
            
            // Trouver la catégorie de l'habitude
            for (var category in _defaultHabits.entries) {
              if (category.value.any((habit) => habit['name'] == habitName)) {
                categoryCompletions[category.key] = (categoryCompletions[category.key] ?? 0) + 1;
                categoryTotal[category.key] = (categoryTotal[category.key] ?? 0) + 1;
              }
            }
          }
          
          if (!weeklyData.containsKey(habitName)) {
            weeklyData[habitName] = List.filled(7, false);
          }
          weeklyData[habitName]![i] = isCompleted == true;
        });
      }
    }
    
    // Calculer les taux de complétion par catégorie
    Map<String, double> completionRates = {};
    categoryCompletions.forEach((category, completions) {
      completionRates[category] = completions / (categoryTotal[category] ?? 1);
    });
    
    // Trier les habitudes par taux de complétion
    List<Map<String, dynamic>> topHabits = habitCompletions.entries
        .map((e) => {
          'name': e.key,
          'completionRate': e.value / 7,
        })
        .toList()
      ..sort((a, b) => (b['completionRate'] as double).compareTo(a['completionRate'] as double));
    
    // Durchschnittlichen Schlaf berechnen
    double totalSleep = weeklySleepData.fold(0, (sum, item) => sum + item);
    double averageSleep = weeklySleepData.isNotEmpty ? totalSleep / weeklySleepData.length : 0.0;
    
    setState(() {
      _categoryCompletionRates = completionRates;
      _topHabits = topHabits.take(5).toList();
      _weeklyProgress = weeklyData;
      _averageWeeklySleep = averageSleep;
    });
  }

  Future<void> _saveDailyStats() async {
    if (_user == null) return;
    
    final today = _getCurrentDate();
    final stats = {
      'date': today,
      'timestamp': FieldValue.serverTimestamp(),
      'categoryStats': _categoryCompletionRates,
      'totalCompletionRate': _calculateTotalCompletionRate(),
    };
    
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('daily_stats')
        .doc(today)
        .set(stats);
  }

  double _calculateTotalCompletionRate() {
    if (_categoryCompletionRates.isEmpty) return 0.0;
    double sum = _categoryCompletionRates.values.reduce((a, b) => a + b);
    return sum / _categoryCompletionRates.length;
  }

  Future<void> _loadDailyStatsForPeriod() async {
    if (_user == null) return;
    
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case 'Woche':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monat':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Jahr':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 6)); // Par défaut, la semaine
    }
    
    final statsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('daily_stats')
        .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
        .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate))
        .get();
    
    Map<String, List<double>> monthlyData = {};
    List<Map<String, dynamic>> dailyStats = [];
    List<Map<String, dynamic>> dailyStepsData = [];
    
    for (var doc in statsSnapshot.docs) {
      final data = doc.data();
      if (data == null) continue;
      
      final categoryStatsData = data['categoryStats'];
      if (categoryStatsData == null || !(categoryStatsData is Map)) continue;
      
      final categoryStats = Map<String, double>.from(categoryStatsData as Map);
      
      categoryStats.forEach((category, rate) {
        if (!monthlyData.containsKey(category)) {
          monthlyData[category] = [];
        }
        monthlyData[category]!.add(rate);
      });
      
      final totalRate = data['totalCompletionRate'];
      if (totalRate == null) continue;
      
      final date = data['date'] as String?;
      if (date != null && date.isNotEmpty) {
        dailyStats.add({
          'date': date,
          'totalRate': totalRate is double ? totalRate : double.tryParse(totalRate.toString()) ?? 0.0,
        });
      }
    }
    
    // Filtrer les entrées sans date valide avant de charger les données quotidiennes
    final validDates = dailyStats.map((e) => e['date']).whereType<String>().toList();

    if (validDates.isNotEmpty) {
      final dailyDataSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('dailyData')
          .where(FieldPath.documentId, whereIn: validDates) // Utiliser les IDs de document (les dates)
          .get();
      
      for (var doc in dailyDataSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;

        // Utiliser l'ID du document (la date) comme champ de date
        final date = doc.id;
        if (date.isNotEmpty) {
          dailyStepsData.add({
            'date': date,
            'steps': (data['steps'] ?? 0) as int,
          });
        }
      }
    }
    
    // Trier les données de pas par date
    dailyStepsData.sort((a, b) {
      final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
      final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
      return dateA.compareTo(dateB);
    });
    
    dailyStats.sort((a, b) {
      final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
      final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
      return dateA.compareTo(dateB);
    });
    
    setState(() {
      _monthlyProgress = monthlyData;
      _dailyStats = dailyStats;
      _dailyStepsData = dailyStepsData;
    });
  }

  Future<void> _loadCategoryGoals() async {
    if (_user == null) return;
    
    final goalsDoc = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('settings')
        .doc('category_goals')
        .get();
    
    if (goalsDoc.exists) {
      setState(() {
        _categoryGoals = Map<String, double>.from(goalsDoc.data() ?? {});
      });
    } else {
      // Initialiser les objectifs par défaut
      Map<String, double> defaultGoals = {};
      for (var category in _defaultHabits.keys) {
        defaultGoals[category] = 0.7; // 70% par défaut
      }
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('settings')
          .doc('category_goals')
          .set(defaultGoals);
      
      setState(() {
        _categoryGoals = defaultGoals;
      });
    }
  }

  Future<void> _updateCategoryGoal(String category, double goal) async {
    if (_user == null) return;
    
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('settings')
        .doc('category_goals')
        .set({
      category: goal,
    }, SetOptions(merge: true));
    
    setState(() {
      _categoryGoals[category] = goal;
    });
  }

  Future<void> _showGoalSettingDialog(String category) async {
    final controller = TextEditingController(
      text: ((_categoryGoals[category] ?? 0.7) * 100).toStringAsFixed(0),
    );
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ziel für $category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ziel in Prozent',
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 16),
            Slider(
              value: double.tryParse(controller.text) ?? 70,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${(double.tryParse(controller.text) ?? 70).round()}%',
              onChanged: (value) {
                controller.text = value.round().toString();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final goal = double.tryParse(controller.text) ?? 70;
              _updateCategoryGoal(category, goal / 100);
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gewohnheiten-Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            ..._defaultHabits.keys.map((category) => Tab(text: category)),
            const Tab(text: 'Statistiken'),
          ],
        ),
      ),
      body: _user == null
          ? const Center(
              child: Text('Bitte melden Sie sich an, um den Gewohnheiten-Tracker zu nutzen.'),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                ..._defaultHabits.entries.map((categoryEntry) {
                  final categoryName = categoryEntry.key;
                  final habits = categoryEntry.value;

                  // Pour la catégorie "Mini-Herausforderungen", afficher les challenges
                  if (categoryName == 'Mini-Herausforderungen') {
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final challenge = habits[index];
                        return ListTile(
                          leading: Icon(challenge['icon'] as IconData),
                          title: Text(challenge['name']),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeDetailScreen(challenge: challenge),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else {
                    // Pour les autres catégories, afficher les habitudes avec checkbox
                    return ListView.builder(
                      itemCount: habits.length,
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return ListTile(
                          leading: Icon(habit['icon'] as IconData),
                          title: Text(habit['name']),
                          trailing: Checkbox(
                            value: _dailyCompletionStatus[habit['name']] ?? false,
                            onChanged: (bool? newValue) {
                              if (newValue != null) {
                                _updateCompletionStatus(habit['name'], newValue);
                              }
                            },
                          ),
                        );
                      },
                    );
                  }
                }).toList(),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Zeitraum',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          DropdownButton<String>(
                            value: _selectedPeriod,
                            items: _periods.map((period) {
                              return DropdownMenuItem(
                                value: period,
                                child: Text(period),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPeriod = value;
                                });
                                _loadDailyStatsForPeriod();
                                _loadStatistics();
                                _loadUserData();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kategorie-Übersicht',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._categoryCompletionRates.entries.map((entry) {
                        final goal = _categoryGoals[entry.key] ?? 0.7;
                        final isGoalAchieved = entry.value >= goal;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  IconButton(
                                    icon: const Icon(Icons.settings),
                                    onPressed: () => _showGoalSettingDialog(entry.key),
                                  ),
                                ],
                              ),
                              LinearProgressIndicator(
                                value: entry.value,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isGoalAchieved ? Colors.green :
                                  entry.value > goal * 0.7 ? Colors.orange :
                                  Colors.red,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${(entry.value * 100).toStringAsFixed(1)}%'),
                                  Text(
                                    'Ziel: ${(goal * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: isGoalAchieved ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      const Text(
                        'Gewicht',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ihr aktuelles Gewicht: ${_userWeight.toStringAsFixed(1)} kg',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Durchschnittlicher Schlaf (diese Woche)',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_averageWeeklySleep.toStringAsFixed(1)} Stunden',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Monatlicher Fortschritt',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_dailyStats.isEmpty)
                        const Center(
                          child: Text('Keine Daten verfügbar'),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${(value * 100).toInt()}%');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= _dailyStats.length) return const Text('');
                                      final dateString = _dailyStats[value.toInt()]['date'] as String?;
                                      if (dateString == null) return const Text('');
                                      final date = DateFormat('yyyy-MM-dd').parse(dateString);
                                      return Text(
                                        _selectedPeriod == 'Woche' ? DateFormat('E').format(date) :
                                        _selectedPeriod == 'Monat' ? DateFormat('dd.MM').format(date) :
                                        DateFormat('MM.yy').format(date)
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _dailyStats.asMap().entries.map((entry) {
                                    return FlSpot(entry.key.toDouble(), entry.value['totalRate'] as double);
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Kategorie-Vergleich',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_monthlyProgress.isEmpty)
                        const Center(
                          child: Text('Keine Daten verfügbar'),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${(value * 100).toInt()}%');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= _dailyStats.length) return const Text('');
                                      final dateString = _dailyStats[value.toInt()]['date'] as String?;
                                      if (dateString == null) return const Text('');
                                      final date = DateFormat('yyyy-MM-dd').parse(dateString);
                                      return Text(
                                        _selectedPeriod == 'Woche' ? DateFormat('E').format(date) :
                                        _selectedPeriod == 'Monat' ? DateFormat('dd.MM').format(date) :
                                        DateFormat('MM.yy').format(date)
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey),
                              ),
                              lineBarsData: _monthlyProgress.entries.map((entry) {
                                return LineChartBarData(
                                  spots: entry.value.asMap().entries.map((spot) {
                                    return FlSpot(spot.key.toDouble(), spot.value);
                                  }).toList(),
                                  isCurved: true,
                                  color: _getCategoryColor(entry.key),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Schritt-Fortschritt',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_dailyStepsData.isEmpty)
                        const Center(
                          child: Text('Keine Daten verfügbar'),
                        )
                      else
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(value.toInt().toString());
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= _dailyStepsData.length) return const Text('');
                                      final dateString = _dailyStepsData[value.toInt()]['date'] as String?;
                                      if (dateString == null) return const Text('');
                                      final date = DateFormat('yyyy-MM-dd').parse(dateString);
                                      return Text(
                                        _selectedPeriod == 'Woche' ? DateFormat('E').format(date) :
                                        _selectedPeriod == 'Monat' ? DateFormat('dd.MM').format(date) :
                                        DateFormat('MM.yy').format(date)
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(color: Colors.grey),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _dailyStepsData.asMap().entries.map((entry) {
                                    return FlSpot(entry.key.toDouble(), (entry.value['steps'] ?? 0).toDouble());
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.orange,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      const Text(
                        'Top 5 Gewohnheiten',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._topHabits.map((habit) {
                        return ListTile(
                          title: Text(habit['name']),
                          trailing: Text('${(habit['completionRate'] * 100).toStringAsFixed(1)}%'),
                        );
                      }),
                      const SizedBox(height: 24),
                      const Text(
                        'Wöchentlicher Fortschritt',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._weeklyProgress.entries.map((entry) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: List.generate(7, (index) {
                                    final date = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1 - index));
                                    return Column(
                                      children: [
                                        Text(DateFormat('E').format(date)),
                                        Icon(
                                          entry.value[index] ? Icons.check_circle : Icons.cancel,
                                          color: entry.value[index] ? Colors.green : Colors.red,
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _user == null
          ? null
          : FloatingActionButton(
              onPressed: _addNewHabitDialog,
              tooltip: 'Neue Gewohnheit hinzufügen',
              child: const Icon(Icons.add),
            ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = {
      'Körperhygiene': Colors.blue,
      'Ernährung und Flüssigkeitszufuhr': Colors.green,
      'Körperliche Aktivität': Colors.orange,
      'Mentale Hygiene & Wohlbefinden': Colors.purple,
      'Schlaf': Colors.indigo,
      'Tagesablauf & Organisation': Colors.teal,
      'Soziale Beziehungen': Colors.pink,
      'Digitale Hygiene': Colors.amber,
    };
    return colors[category] ?? Colors.grey;
  }
} 