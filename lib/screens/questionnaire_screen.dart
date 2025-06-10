import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionnaireScreen extends StatefulWidget {
  final String? category;
  const QuestionnaireScreen({super.key, this.category});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _answers = {};
  bool _isLoading = true;
  int _totalScore = 0;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (widget.category == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questionnaires')
          .doc(widget.category)
          .collection('questions')
          .orderBy('order')
          .get();

      final loadedQuestions = snapshot.docs.map((doc) => doc.data()).toList();

      setState(() {
        _questions = loadedQuestions;
        _isLoading = false;
      });

    } catch (e) {
      print("Error loading questions: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _defaultScores(Map<String, dynamic> question) {
    if (question['type'] == 'boolean') {
      return {'true': 1, 'false': 0};
    } else if (question['type'] == 'number') {
      return {for (var i = (question['min'] ?? 0); i <= (question['max'] ?? 10); i++) i.toString(): 1};
    } else if (question['type'] == 'scale') {
      return {for (var i = 1; i <= (question['labels']?.length ?? 5); i++) i.toString(): i};
    }
    return {};
  }

  void _calculateScore(dynamic answer, Map<String, dynamic> question) {
    if (answer == null) return;
    int score = 0;
    final scores = question['scores'] ?? _defaultScores(question);
    switch (question['type']) {
      case 'boolean':
        score = scores[answer.toString()] ?? 0;
        break;
      case 'number':
        score = scores[answer.toString()] ?? 0;
        break;
      case 'scale':
        score = scores[answer.toString()] ?? 0;
        break;
    }
    setState(() {
      _totalScore += score;
    });
  }

  void _answerQuestion(dynamic answer) {
    final question = _questions[_currentQuestionIndex];
    final questionKey = '${widget.category}_$_currentQuestionIndex';
    setState(() {
      _answers[questionKey] = answer;
    });
    _calculateScore(answer, question);
    Future.delayed(const Duration(milliseconds: 300), _handleNextQuestion);
  }

  Future<void> _saveAnswers() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('questionnaire_answers')
            .add({
          'answers': _answers,
          'score': _totalScore,
          'maxPossibleScore': _calculateMaxPossibleScore(),
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Antworten gespeichert. Score: $_totalScore')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _calculateMaxPossibleScore() {
    int maxScore = 0;
    for (var question in _questions) {
      if (question['scores'] != null) {
        var scores = question['scores'].values.toList();
        if (scores.isNotEmpty) {
          var maxValue = scores[0];
          for (var score in scores) {
            if (score > maxValue) {
              maxValue = score;
            }
          }
          maxScore += maxValue as int;
        }
      }
    }
    return maxScore;
  }

  String _getScoreCategory(int score, int maxScore) {
    final percentage = (score / maxScore) * 100;
    if (percentage >= 80) return 'Sehr gut';
    if (percentage >= 60) return 'Gut';
    if (percentage >= 40) return 'Mittel';
    if (percentage >= 20) return 'Verbesserung nötig';
    return 'Kritisch';
  }

  void _handleNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _showResult = true;
      });
    }
  }

  bool _showResult = false;

  Widget _buildQuestionInput(Map<String, dynamic> question) {
    switch (question['type']) {
      case 'number':
        return TextField(
                keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
                  hintText: 'Antwort eingeben',
            suffixText: question['unit'] ?? '',
              ),
          onSubmitted: (value) {
            final number = int.tryParse(value);
            if (number != null && 
                number >= (question['min'] ?? 0) && 
                number <= (question['max'] ?? 999999)) {
              _answerQuestion(number);
            }
          },
        );
      
      case 'boolean':
        return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _answerQuestion(true),
                    child: const Text('Ja'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () => _answerQuestion(false),
                    child: const Text('Nein'),
                  ),
                ],
        );
      
      case 'scale':
        return Column(
          children: [
            for (int i = 0; i < question['labels'].length; i++)
              ListTile(
                title: Text(question['labels'][i]),
                leading: Radio<int>(
                  value: i + 1,
                  groupValue: _answers['${widget.category}_$_currentQuestionIndex'],
                  onChanged: (value) => _answerQuestion(value),
                ),
              ),
          ],
        );
      
      case 'date':
        return ElevatedButton(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _answerQuestion(date.toIso8601String());
            }
          },
          child: const Text('Datum auswählen'),
        );
      
      default:
        return const Text('Unbekannter Fragetyp');
    }
  }

  Future<void> _showAnswerHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('questionnaire_answers')
            .orderBy('timestamp', descending: true)
            .get();

        if (!mounted) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Antwortverlauf'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.docs[index];
                  final data = doc.data();
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  final answers = data['answers'] as Map<String, dynamic>;

                  return ExpansionTile(
                    title: Text('Umfrage vom ${timestamp.toString().split(' ')[0]}'),
                    children: [
                      for (var question in _questions)
                        ListTile(
                          title: Text(question['text']),
                          subtitle: Text(
                            _formatAnswer(
                              answers['${widget.category}_$_currentQuestionIndex'],
                              question['type'],
                              question,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Schließen'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e')),
        );
      }
    }
  }

  String _formatAnswer(dynamic answer, String type, Map<String, dynamic> question) {
    if (answer == null) return 'Keine Antwort';
    
    switch (type) {
      case 'boolean':
        return answer ? 'Ja' : 'Nein';
      case 'number':
        return answer.toString();
      case 'scale':
        return question['labels'][answer - 1];
      case 'date':
        return DateTime.parse(answer).toString().split(' ')[0];
      default:
        return answer.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category ?? 'Fragebogen')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category ?? 'Fragebogen')),
        body: const Center(child: Text('Keine Fragen für diese Kategorie gefunden.')),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    if (_showResult) {
      final maxScore = _questions.fold<int>(0, (sum, q) {
        final scores = q['scores'] ?? _defaultScores(q);
        if (scores.values.isNotEmpty) {
          final maxValue = scores.values.reduce((a, b) => (a as num) > (b as num) ? a : b) as num;
          return sum + maxValue.toInt();
        } else {
          return sum + 1;
        }
      });
      final appreciation = _getScoreCategory(_totalScore, maxScore);
      return Scaffold(
        appBar: AppBar(title: Text(widget.category!)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Dein Score: $_totalScore / $maxScore', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Bewertung: $appreciation', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 32),
            ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fertig'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category!),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAnswerHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          if (_totalScore > 0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Aktueller Score: $_totalScore',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_answer,
                    size: 50,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    question['text'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
              ),
                  const SizedBox(height: 30),
                  _buildQuestionInput(question),
          ],
        ),
            ),
          ),
        ],
      ),
    );
  }
}