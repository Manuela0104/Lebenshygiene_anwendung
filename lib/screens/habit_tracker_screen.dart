import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:fl_chart/fl_chart.dart';
import 'package:lebenshygiene_anwendung/screens/challenge_detail_screen.dart';

/// Gewohnheits-Tracker-Bildschirm für die detaillierte Überwachung von Gesundheitsgewohnheiten
/// 
/// Bietet umfassende Funktionalitäten für:
/// - Erstellung und Verwaltung von Gewohnheiten
/// - Tägliche Verfolgung der Gewohnheitserfüllung
/// - Kategorisierte Gewohnheiten (Mini-Herausforderungen, intelligente Erinnerungen)
/// - Fortschrittsstatistiken und Trends mit Charts
/// - Integration mit anderen Tracking-Funktionen (Stimmung, Schlaf, Schritte)
/// - Vordefinierte Gewohnheits-Challenges für verschiedene Zeiträume
/// 
/// Der Bildschirm bietet eine zentrale Plattform für alle
/// Gewohnheits-bezogenen Aktivitäten.
class HabitTrackerScreen extends StatefulWidget {
  final int? initialTabIndex;
  const HabitTrackerScreen({super.key, this.initialTabIndex});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

/// State-Klasse für den Gewohnheits-Tracker-Bildschirm
/// 
/// Verwaltet umfassende Gewohnheitsdaten, Kategorien und Statistiken.
/// Implementiert Firestore-Integration, Tab-basierte Navigation,
/// Chart-Visualisierung und Challenge-Management.
/// Bietet eine detaillierte Übersicht über alle Gewohnheitsaktivitäten
/// und deren Fortschritt über verschiedene Zeiträume.
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
  Map<String, List<double>> _monthlyProgress = {};
  List<Map<String, dynamic>> _dailyStats = [];
  List<Map<String, dynamic>> _dailyStepsData = [];
  List<Map<String, dynamic>> _dailyMoodData = [];
  List<Map<String, dynamic>> _dailyWeightData = [];
  List<Map<String, dynamic>> _dailySleepData = [];
  double _currentMoodLevel = 3.0;
  final TextEditingController _moodCommentController = TextEditingController();
  String? _currentMoodId;
  String _selectedPeriod = 'Woche';
  final List<String> _periods = ['Woche', 'Monat', 'Jahr'];
  double _averageSleep = 0.0;
  double _overallCompletionRate = 0.0;
  Map<String, List<bool>> _weeklyProgress = {};

  final Map<String, List<String>> _challengeHabits = {
    'Routine digitale Detox (7 Tage)': [
      'Bildschirmzeit vor dem Schlafengehen begrenzen',
      'Von sozialen Medien abmelden',
      'Telefon nachts in den Flugmodus schalten',
      'Netzwerke während der Mahlzeiten deaktivieren',
      'Unnötige Apps löschen', // Diese Gewohnheit ist eher einmalig, bei Bedarf anpassen
    ],
    'Morgenroutine (14 Tage)': [
      'Jeden Tag zur gleichen Zeit ins Bett gehen',
      '7-9 Stunden schlafen', // Oder ein Schlafziel
      '1 Stunde vor dem Schlafengehen Bildschirme vermeiden',
      'Gesundes Frühstück essen', // Essgewohnheit
      '15 Minuten Sport / Yoga / Stretching machen', // Körperliche Aktivität
    ],
    'Tiefschlaf-Routine (30 Tage)': [
      '7-9 Stunden schlafen', // Schlaf-Tracking
      'Jeden Tag zur gleichen Zeit ins Bett gehen',
      '1 Stunde vor dem Schlafengehen Bildschirme vermeiden',
      'Einen Kräutertee trinken oder ein Ritual machen', // Kann bei Meditation/Entspannung helfen
      'Ein luftiges und aufgeräumtes Zimmer halten',
    ],
    '10k Schritte Challenge (7 Tage)': [
      '10.000 Schritte gehen', // Schritte verfolgen
      'Treppe statt Aufzug nehmen', // Aktivität steigern
      'Nach dem Mittagessen spazieren gehen', // Aktivität steigern
    ],
    'Trink-Challenge (14 Tage)': [
      '2 Liter Wasser trinken', // Wasser-Tracking
      'Einen Kräutertee trinken oder ein Ritual machen', // Flüssigkeitszufuhr fördern
    ],
    'Meditations-Challenge (30 Tage)': [
      '10 Minuten meditieren', // Meditations-Tracking
      'Beruhigende Musik hören', // Kann bei Meditation/Entspannung helfen
    ]
  };

  final Map<String, List<Map<String, dynamic>>> _defaultHabits = {
    'Mini-Herausforderungen': [
      {'name': 'Routine digitale Detox (7 Tage)', 'icon': Icons.phone_android},
      {'name': 'Morgenroutine (14 Tage)', 'icon': Icons.wb_sunny},
      {'name': 'Tiefschlaf-Routine (30 Tage)', 'icon': Icons.bedtime},
      {'name': '10k Schritte Challenge (7 Tage)', 'icon': Icons.directions_walk},
      {'name': 'Trink-Challenge (14 Tage)', 'icon': Icons.water_drop},
      {'name': 'Meditations-Challenge (30 Tage)', 'icon': Icons.self_improvement},
    ],
    'Intelligente Erinnerungen': [
      {'name': 'Hydration', 'icon': Icons.water_drop},
      {'name': 'Aktive Pause', 'icon': Icons.directions_walk},
      {'name': 'Abendroutine', 'icon': Icons.nightlight},
      {'name': 'Entkopplung', 'icon': Icons.mobile_off},
      {'name': 'Meditation', 'icon': Icons.self_improvement},
      {'name': 'Schlaf', 'icon': Icons.bedtime},
    ],
    'Mood Tracker': [
      {'name': 'Humeur des Tages', 'icon': Icons.mood},
      {'name': 'Energielevel', 'icon': Icons.bolt},
      {'name': 'Schlafqualität', 'icon': Icons.bedtime},
      {'name': 'Stresslevel', 'icon': Icons.psychology},
      {'name': 'Produktivität', 'icon': Icons.work},
      {'name': 'Persönliche Notizen', 'icon': Icons.edit_note},
    ],
    // 'Coach Virtuel' : Cette catégorie a été supprimée du tableau de bord et n'est pas utilisée ici.
  };

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _tabController = TabController(length: 4, vsync: this);
    if (_user != null) {
      _loadHabits();
      _loadDailyCompletionStatus();
      _loadStatistics();
      _loadDailyMood();
    }
    if (widget.initialTabIndex != null && widget.initialTabIndex! < _tabController.length) {
      _tabController.animateTo(widget.initialTabIndex!);
    }
  }

  @override
  void dispose() {
    _newHabitController.dispose();
    _tabController.dispose();
    _moodCommentController.dispose();
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

  Future<void> _loadStatistics() async {
    if (_user == null) return;
    
    // Charger les données de la semaine pour l'affichage hebdomadaire
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    Map<String, List<bool>> weeklyData = {};
    
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('daily_status')
          .doc(dateStr)
          .get();
      
      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        
        data.forEach((habitName, isCompleted) {
          // Conserver la logique pour les habitudes affichées ici
          if (isCompleted == true) {
            // Calculs si nécessaire pour l'affichage hebdomadaire
          }
          
          if (!weeklyData.containsKey(habitName)) {
            weeklyData[habitName] = List.filled(7, false);
          }
          weeklyData[habitName]![i] = isCompleted == true;
        });
      }
    }
    
    setState(() {
      _weeklyProgress = weeklyData;
    });
  }

  Future<void> _addNewHabitDialog() async {
    String selectedCategory = _defaultHabits.keys
        .where((category) =>
            category != 'Mini-Herausforderungen' &&
            category != 'Tendances & Rapports') // Exclure les catégories qui ne sont pas pour les habitudes régulières
        .first;
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
                items: _defaultHabits.keys
                    .where((category) =>
                        category != 'Mini-Herausforderungen' &&
                        category != 'Tendances & Rapports') // Filtrer pour n'afficher que les catégories d'habitudes
                    .map((category) {
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

  Future<void> _addHabitsFromChallenge(List<String> habitNames) async {
    if (_user == null) return;
    final batch = _firestore.batch();

    // Existierende Gewohnheiten laden, um Duplikate zu vermeiden
    final existingHabitsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('habits')
        .get();

    final existingHabitNames = existingHabitsSnapshot.docs
        .map((doc) => doc.data()['name'] as String)
        .toSet(); // Ein Set für schnelle Suche verwenden

    for (final habitName in habitNames) {
      if (!existingHabitNames.contains(habitName)) {
        final newHabitRef = _firestore.collection('users').doc(_user!.uid).collection('habits').doc();
        batch.set(newHabitRef, {
          'name': habitName,
          'category': 'Challenges', // Standardkategorie für Challenge-Gewohnheiten
          'createdAt': FieldValue.serverTimestamp(),
          // TODO: Falls nötig, spezifische Challenge-Felder hinzufügen (z.B. challengeName, endDate)
        });
      }
    }

    try {
      await batch.commit();
      debugPrint('Gewohnheiten aus Challenge hinzugefügt.');
      await _loadHabits(); // Gewohnheitenliste nach dem Hinzufügen neu laden
    } catch (e) {
      debugPrint('Error adding habits from challenge: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter the categories that SHOULD appear in HabitTrackerScreen
    final List<String> habitTrackerCategories = _defaultHabits.keys
        .where((category) =>
            category != 'Mini-Herausforderungen' &&
            category != 'Tendances & Rapports' &&
            category != 'Mood Tracker')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gewohnheiten-Tracker'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            // Tabs for the remaining habit categories
            ...habitTrackerCategories.map((category) => Tab(text: category)),
            const Tab(text: 'Stimmungs-Tracker'), // Mood Tracker tab
            const Tab(text: 'Wöchentlicher Fortschritt'), // Weekly Progress tab
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
                // Views for the remaining habit categories
                ...habitTrackerCategories.map((categoryName) {
                  final habits = _defaultHabits[categoryName] ?? [];
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
                }).toList(),
                // Mood Tracker Tab content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wie fühlen Sie sich heute?',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Stimmungsniveau: ${_currentMoodLevel.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: _currentMoodLevel,
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        onChanged: (newValue) {
                          setState(() {
                            _currentMoodLevel = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Kommentar:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _moodCommentController,
                        decoration: const InputDecoration(
                          hintText: 'Optionalen Kommentar eingeben',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveDailyMood,
                          child: const Text('Stimmung speichern'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenu du Weekly Progress
                 SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text(
                        'Wöchentlicher Fortschritt',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_weeklyProgress.isEmpty)
                        const Center(
                          child: Text('Keine Daten verfügbar'),
                        )
                      else
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
                        }).toList(),
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
              child: const Icon(Icons.add), // Keep the FAB for adding habits
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
      'Challenges': Colors.red, // Ajouter une couleur pour les habitudes des challenges si elles sont affichées ici
    };
    return colors[category] ?? Colors.grey;
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

      if (mounted) {
        setState(() {
          _dailyCompletionStatus[habitName] = isCompleted;
        });
      }
      // Pas besoin de recharger toutes les statistiques ici, juste le statut de complétion
      // await _loadStatistics();
    } catch (e) {
      debugPrint('Error updating completion status: $e');
    }
  }

  Future<void> _saveDailyMood() async {
    if (_user == null) return;
    try {
      final today = _getCurrentDate();
      final moodData = {
        'level': _currentMoodLevel,
        'comment': _moodCommentController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('moodEntries')
          .doc(today)
          .set(moodData, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _currentMoodId = today;
        });
      }
      debugPrint('Tägliche Stimmung für $today gespeichert');
    } catch (e) {
      debugPrint('Fehler beim Speichern der täglichen Stimmung: $e');
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

  Future<void> _loadDailyMood() async {
    if (_user == null) return;
    try {
      final today = _getCurrentDate();
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('moodEntries')
          .doc(today)
          .get();

      if (moodSnapshot.exists) {
        final moodData = moodSnapshot.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _currentMoodLevel = (moodData['level'] as num?)?.toDouble() ?? 3.0;
            _moodCommentController.text = (moodData['comment'] as String?) ?? '';
            _currentMoodId = moodSnapshot.id;
          });
        }
      } else if (mounted) {
        setState(() {
          _currentMoodLevel = 3.0;
          _moodCommentController.text = '';
          _currentMoodId = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading daily mood: $e');
    }
  }
} 