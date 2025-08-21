import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Trends-Bildschirm für die Visualisierung von Gesundheitsdaten
/// 
/// Bietet umfassende Funktionalitäten für:
/// - Zeitraum-basierte Datenanalyse (Woche, Monat, Jahr)
/// - Chart-basierte Visualisierung verschiedener Metriken
/// - Trend-Analyse für Schritte, Stimmung, Gewicht und Schlaf
/// - Durchschnittsberechnungen und Statistiken
/// - Interaktive Diagramme für bessere Datenverständnis
/// - Integration mit dem täglichen Daten-Tracking
/// 
/// Der Bildschirm hilft Benutzern, langfristige Trends
/// in ihren Gesundheitsdaten zu erkennen.
class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

/// State-Klasse für den Trends-Bildschirm
/// 
/// Verwaltet Trenddaten, Zeitraum-Auswahl und Chart-Visualisierung.
/// Implementiert Firestore-Integration für Datenabfrage,
/// Flutter-Charts für Datenvisualisierung,
/// Zeitraum-basierte Datenfilterung und -aggregation.
/// Bietet eine umfassende Trend-Analyse aller
/// wichtigen Gesundheitsmetriken.
class _TrendsScreenState extends State<TrendsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String _selectedPeriod = 'Woche';
  final List<String> _periods = ['Woche', 'Monat', 'Jahr'];
  
  // Daten für die Diagramme
  List<Map<String, dynamic>> _dailyStats = [];
  List<Map<String, dynamic>> _dailyStepsData = [];
  List<Map<String, dynamic>> _dailyMoodData = [];
  List<Map<String, dynamic>> _dailyWeightData = [];
  List<Map<String, dynamic>> _dailySleepData = [];
  double _averageSleep = 0.0;
  double _overallCompletionRate = 0.0;
  double _userWeight = 0.0;
  double _weeklyAverageSleep = 0.0; // Variable für den wöchentlichen Durchschnittsschlaf

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadDailyStatsForPeriod();
      _loadUserData();
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
        startDate = now.subtract(const Duration(days: 6));
    }
    
    // Ensure start date is not in the future
    if (startDate.isAfter(now)) {
      startDate = DateTime(now.year, now.month, now.day);
    }

    final statsSnapshot = await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('daily_stats')
        .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startDate))
        .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(endDate))
        .get();
    
    List<Map<String, dynamic>> dailyStats = [];
    List<Map<String, dynamic>> dailyStepsData = [];
    List<Map<String, dynamic>> dailyMoodData = [];
    List<Map<String, dynamic>> dailyWeightData = [];
    List<Map<String, dynamic>> dailySleepData = [];
    
    for (var doc in statsSnapshot.docs) {
      final data = doc.data();
      if (data == null) continue;
      
      final dynamic dateData = data['date'];
      if (dateData != null && dateData is String && dateData.isNotEmpty) {
        final date = dateData as String;
        dailyStats.add({
          'date': date,
          'totalRate': data['totalCompletionRate'] is double ? data['totalCompletionRate'] : double.tryParse(data['totalCompletionRate'].toString()) ?? 0.0,
        });
      }
    }
    
    final validDates = dailyStats.map((e) => e['date']).whereType<String>().toList();

    if (validDates.isNotEmpty) {
      // Schrittdaten laden
      final dailyDataSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('dailyData')
          .where(FieldPath.documentId, whereIn: validDates)
          .get();
      
      for (var doc in dailyDataSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final date = doc.id;
        if (date.isNotEmpty) {
          dailyStepsData.add({
            'date': date,
            'steps': (data['steps'] ?? 0) as int,
          });
        }
      }

      // Stimmungsdaten laden
      final moodSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('moodEntries')
          .where(FieldPath.documentId, whereIn: validDates)
          .get();

      for (var doc in moodSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final date = doc.id;
        if (date != null && date.isNotEmpty) {
          dailyMoodData.add({
            'date': date,
            'level': (data['level'] as num?)?.toDouble() ?? 3.0,
          });
        }
      }

      // Gewichtsdaten laden
      final weightSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('weightEntries')
          .where(FieldPath.documentId, whereIn: validDates)
          .get();

      for (var doc in weightSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final date = doc.id;
        if (date != null && date.isNotEmpty) {
          dailyWeightData.add({
            'date': date,
            'weight': (data['weight'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }

      // Schlafdaten laden
      final sleepSnapshot = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('sleepEntries')
          .where(FieldPath.documentId, whereIn: validDates)
          .get();

      for (var doc in sleepSnapshot.docs) {
        final data = doc.data();
        if (data == null) continue;
        final date = doc.id;
        if (date != null && date.isNotEmpty) {
          dailySleepData.add({
            'date': date,
            'duration': (data['duration'] as num?)?.toDouble() ?? 0.0,
          });
        }
      }
    }
    
    // Alle Daten nach Datum sortieren
    dailyStats.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a['date']).compareTo(DateFormat('yyyy-MM-dd').parse(b['date'])));
    dailyStepsData.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a['date']).compareTo(DateFormat('yyyy-MM-dd').parse(b['date'])));
    dailyMoodData.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a['date']).compareTo(DateFormat('yyyy-MM-dd').parse(b['date'])));
    dailyWeightData.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a['date']).compareTo(DateFormat('yyyy-MM-dd').parse(b['date'])));
    dailySleepData.sort((a, b) => DateFormat('yyyy-MM-dd').parse(a['date']).compareTo(DateFormat('yyyy-MM-dd').parse(b['date'])));
    
    // Berechne wöchentlichen Durchschnittsschlaf, falls Periode 'Woche' ist
    if (_selectedPeriod == 'Woche' && _dailySleepData.isNotEmpty) {
      final totalSleep = _dailySleepData.fold(0.0, (sum, item) => sum + (item['duration'] ?? 0.0));
      _weeklyAverageSleep = totalSleep / _dailySleepData.length;
    } else {
      _weeklyAverageSleep = 0.0;
    }

    setState(() {
      _dailyStats = dailyStats;
      _dailyStepsData = dailyStepsData;
      _dailyMoodData = dailyMoodData;
      _dailyWeightData = dailyWeightData;
      _dailySleepData = dailySleepData;

      // Gesamterfüllungsrate berechnen
      if (_dailyStats.isNotEmpty) {
        final totalDailyCompletionRate = _dailyStats.fold(0.0, (sum, item) => sum + (item['totalRate'] ?? 0.0));
        _overallCompletionRate = totalDailyCompletionRate / _dailyStats.length;
      } else {
        _overallCompletionRate = 0.0;
      }

      // Durchschnittlichen Schlaf berechnen
      if (_dailySleepData.isNotEmpty) {
        final totalSleep = _dailySleepData.fold(0.0, (sum, item) => sum + (item['duration'] ?? 0.0));
        _averageSleep = totalSleep / _dailySleepData.length;
      } else {
        _averageSleep = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Berichte'),
      ),
      body: SingleChildScrollView(
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
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Statistiken erfolgreicher Gewohnheiten (Diagramm)
            const Text(
              'Erfolgsquote der Gewohnheiten',
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
                            return Text('${value.toInt()}%'); // Display as percentage
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
                          return FlSpot(entry.key.toDouble(), (entry.value['totalRate'] ?? 0.0) * 100); // Display as percentage
                        }).toList(),
                        isCurved: true,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    minY: 0,
                    maxY: 100, // Percentage goes up to 100
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Gewichtsverlauf
            const Text(
              'Gewichtsverlauf',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_dailyWeightData.isEmpty)
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
                            return Text(value.toStringAsFixed(1));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _dailyWeightData.length) return const Text('');
                            final dateString = _dailyWeightData[value.toInt()]['date'] as String?;
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
                        spots: _dailyWeightData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), (entry.value['weight'] ?? 0.0).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.green,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Stimmungs-Kurve
            const Text(
              'Stimmungs-Kurve',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_dailyMoodData.isEmpty)
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
                            return Text(value.toStringAsFixed(1));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _dailyMoodData.length) return const Text('');
                            final dateString = _dailyMoodData[value.toInt()]['date'] as String?;
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
                        spots: _dailyMoodData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), entry.value['level'] as double);
                        }).toList(),
                        isCurved: true,
                        color: Colors.purple, // Ensure this color is different from habit completion rate
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Schlafdauer (Stunden) und wöchentlicher Durchschnitt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Schlafdauer (Stunden)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_selectedPeriod == 'Woche' && _weeklyAverageSleep > 0)
                  Text(
                    'Ø Woche: ${_weeklyAverageSleep.toStringAsFixed(1)} h',
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_dailySleepData.isEmpty)
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
                            return Text(value.toStringAsFixed(1));
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= _dailySleepData.length) return const Text('');
                            final dateString = _dailySleepData[value.toInt()]['date'] as String?;
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
                        spots: _dailySleepData.asMap().entries.map((entry) {
                          return FlSpot(entry.key.toDouble(), (entry.value['duration'] ?? 0.0).toDouble());
                        }).toList(),
                        isCurved: true,
                        color: Colors.blue, // Ensure this color is different from habit completion rate and mood
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Schritt-Fortschritt
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
                        color: Colors.orange, // Ensure this color is different from other charts
                        barWidth: 3,
                        dotData: FlDotData(show: true),
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
} 