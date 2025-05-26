import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  double _currentMoodLevel = 3.0; // 1: Sehr schlecht, 5: Sehr gut
  final TextEditingController _moodCommentController = TextEditingController();
  bool _isLoading = false;
  String? _currentMoodId;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      _loadDailyMood();
    }
  }

  @override
  void dispose() {
    _moodCommentController.dispose();
    super.dispose();
  }

  String _getCurrentDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
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
         // Wenn keine Daten für heute gefunden, setze auf Standardwerte
        setState(() {
          _currentMoodLevel = 3.0;
          _moodCommentController.text = '';
          _currentMoodId = null;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der täglichen Stimmung: $e');
      if (mounted) {
         // Auch bei Fehlern auf Standardwerte setzen
        setState(() {
          _currentMoodLevel = 3.0;
          _moodCommentController.text = '';
          _currentMoodId = null;
          _isLoading = false; // Stoppe den Ladezustand im Fehlerfall
        });
      }
    }
  }

  Future<void> _saveDailyMood() async {
    if (_user == null) return;
    setState(() => _isLoading = true);
    try {
      final today = _getCurrentDate();
      final moodData = {
        'level': _currentMoodLevel,
        'comment': _moodCommentController.text.trim(),
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
          _currentMoodId = today; // Setze die ID nach erfolgreichem Speichern
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stimmung gespeichert!')),
        );
      }
      debugPrint('Tägliche Stimmung für $today gespeichert');
    } catch (e) {
      debugPrint('Fehler beim Speichern der täglichen Stimmung: $e');
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern der Stimmung: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // TODO: Funktion zur KI-Analyse des Kommentars hinzufügen
  void _analyzeMoodWithAI() {
    // Diese Funktion wird den Kommentar analysieren und Vorschläge machen
    debugPrint('KI-Analyse des Kommentars: ${_moodCommentController.text}');
    // Implementierung erfordert eine Verbindung zu einem KI-Dienst
    // und Logik zur Interpretation der Ergebnisse und Vorschläge

    // Beispielhafter Vorschlag (ersetzen durch KI-Ergebnis)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KI-Vorschlag'),
        content: const Text('Basierend auf deinem Kommentar könnte eine kurze Spaziergang oder eine Entspannungsübung hilfreich sein.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEmoji(double moodLevel) {
    // Einfache Logik zur Auswahl eines Emojis basierend auf dem Stimmungslevel
    if (moodLevel <= 1.5) return const Text('😞', style: TextStyle(fontSize: 40)); // Sehr schlecht
    if (moodLevel <= 2.5) return const Text('😟', style: TextStyle(fontSize: 40)); // Schlecht
    if (moodLevel <= 3.5) return const Text(' neutral', style: TextStyle(fontSize: 40)); // Neutral
    if (moodLevel <= 4.5) return const Text('😊', style: TextStyle(fontSize: 40)); // Gut
    return const Text('😄', style: TextStyle(fontSize: 40)); // Sehr gut
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stimmungs-Tracker'),
      ),
      body: _user == null
          ? const Center(
              child: Text('Bitte melden Sie sich an, um den Stimmungs-Tracker zu nutzen.'),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Wie fühlen Sie sich heute?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: _buildMoodEmoji(_currentMoodLevel),
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
                      const SizedBox(height: 20),
                      const Text(
                        'Kommentar (optional):',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _moodCommentController,
                        decoration: const InputDecoration(
                          hintText: 'Geben Sie hier Ihre Gedanken ein...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12.0),
                        ),
                        maxLines: 5,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveDailyMood, // Rufe Speicherfunktion auf
                        child: const Text('Stimmung speichern'),
                      ),
                      const SizedBox(height: 10), // Abstand zwischen Speichern und KI-Button
                       ElevatedButton(
                         onPressed: () {
                           // TODO: KI-Analyse Funktion hier aufrufen
                           _analyzeMoodWithAI(); // Beispielaufruf
                         },
                         child: const Text('KI-Analyse & Vorschläge erhalten'),
                       ),
                      // TODO: Bereich für KI-Vorschläge anzeigen, falls vorhanden
                    ],
                  ),
                ),
    );
  }
} 