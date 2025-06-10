import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.html) 'dart:html' as html;

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> with TickerProviderStateMixin {
  SharedPreferences? _prefs;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _reminderTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showAddRoutine = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasNotificationPermission = false;
  Map<String, int> _streaks = {};
  Map<String, List<DateTime>> _activityHistory = {};
  List<Map<String, dynamic>> _earnedBadges = [];

  final String _lastHydrationKey = 'last_hydration_time';
  final String _lastWalkKey = 'last_walk_time';
  final String _lastSleepKey = 'last_sleep_time';
  final String _lastShowerKey = 'last_shower_time';

  List<Map<String, dynamic>> _activities = [
    {
      'key': 'hydration',
      'title': 'Wasser trinken',
      'icon': Icons.water_drop,
      'color': Color(0xFF4facfe),
      'gradient': [Color(0xFF4facfe), Color(0xFF00f2fe)],
      'reminderHours': 2,
      'reminderText': 'Zeit für ein Glas Wasser! 💧',
      'customReminder': false,
      'reminderTime': null,
      'streak': 0,
      'badges': [
        {'name': 'Hydration Hero', 'description': '3 Tage in Folge Wasser getrunken', 'requirement': 3},
        {'name': 'Wasser-Champion', 'description': '7 Tage in Folge Wasser getrunken', 'requirement': 7},
      ],
    },
    {
      'key': 'walk',
      'title': 'Spaziergang',
      'icon': Icons.directions_walk,
      'color': Color(0xFF43e97b),
      'gradient': [Color(0xFF43e97b), Color(0xFF38f9d7)],
      'reminderHours': 24,
      'reminderText': 'Ein kleiner Spaziergang wäre gut! 🚶‍♂️',
      'customReminder': false,
      'reminderTime': null,
      'streak': 0,
      'badges': [
        {'name': 'Bewegungs-Starter', 'description': '3 Tage in Folge spazieren gegangen', 'requirement': 3},
        {'name': 'Bewegungs-Profi', 'description': '7 Tage in Folge spazieren gegangen', 'requirement': 7},
      ],
    },
    {
      'key': 'sleep',
      'title': 'Schlaf',
      'icon': Icons.bedtime,
      'color': Color(0xFF764ba2),
      'gradient': [Color(0xFF764ba2), Color(0xFF667eea)],
      'reminderHours': 24,
      'reminderText': 'Zeit für erholsamen Schlaf! 😴',
      'customReminder': false,
      'reminderTime': null,
      'streak': 0,
      'badges': [
        {'name': 'Schlaf-Starter', 'description': '3 Tage in Folge gut geschlafen', 'requirement': 3},
        {'name': 'Schlaf-Meister', 'description': '7 Tage in Folge gut geschlafen', 'requirement': 7},
      ],
    },
    {
      'key': 'shower',
      'title': 'Dusche',
      'icon': Icons.shower,
      'color': Color(0xFFfa709a),
      'gradient': [Color(0xFFfa709a), Color(0xFFfee140)],
      'reminderHours': 24,
      'reminderText': 'Eine erfrischende Dusche? 🚿',
      'customReminder': false,
      'reminderTime': null,
      'streak': 0,
      'badges': [
        {'name': 'Hygiene-Starter', 'description': '3 Tage in Folge geduscht', 'requirement': 3},
        {'name': 'Hygiene-Profi', 'description': '7 Tage in Folge geduscht', 'requirement': 7},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      tzdata.initializeTimeZones();
      await _checkNotificationPermissions();
      await _initSharedPreferences();
      await _initNotifications();
      await _loadCustomActivities();
      await _loadStreaks();
      await _loadActivityHistory();
      _startReminderTimer();
      _fadeController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Fehler beim Laden der Daten: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _checkNotificationPermissions() async {
    if (kIsWeb) {
      // Sur le web, on considère que les notifications sont toujours disponibles
      setState(() {
        _hasNotificationPermission = true;
      });
      return;
    }

    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      setState(() {
        _hasNotificationPermission = status.isGranted;
      });

      if (!status.isGranted) {
        final result = await Permission.notification.request();
        setState(() {
          _hasNotificationPermission = result.isGranted;
        });
      }
    }
  }

  Future<void> _initNotifications() async {
    if (!_hasNotificationPermission && !kIsWeb) {
      debugPrint('Keine Benachrichtigungsberechtigungen');
      return;
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('Notification clicked: ${response.payload}');
        if (response.payload != null) {
          final activity = _activities.firstWhere(
            (a) => a['key'] == response.payload,
            orElse: () => _activities[0],
          );
          _showActivityDialog(activity);
        }
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }
  }

  Future<void> _loadCustomActivities() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customActivities')
            .get();
        
        final customActivities = snapshot.docs.map((doc) => {
          'key': doc.id,
          'title': doc['title'],
          'icon': IconData(doc['iconCode'], fontFamily: 'MaterialIcons'),
          'color': Color(doc['color']),
          'gradient': [Color(doc['color']), Color(doc['color']).withOpacity(0.7)],
          'reminderHours': doc['reminderHours'],
          'reminderText': doc['reminderText'],
          'customReminder': true,
          'reminderTime': doc['reminderTime']?.toDate(),
          'streak': 0,
          'badges': [
            {
              'name': '${doc['title']}-Starter',
              'description': '3 Tage in Folge ${doc['title']} geschafft',
              'requirement': 3
            },
            {
              'name': '${doc['title']}-Meister',
              'description': '7 Tage in Folge ${doc['title']} geschafft',
              'requirement': 7
            },
          ],
        }).toList();

        setState(() {
          _activities.addAll(customActivities);
        });
      } catch (e) {
        debugPrint('Fehler beim Laden der benutzerdefinierten Aktivitäten: $e');
      }
    }
  }

  Future<void> _loadStreaks() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('stats')
            .doc('streaks')
            .get();
        
        if (doc.exists) {
          setState(() {
            _streaks = Map<String, int>.from(doc.data() ?? {});
          });
        }
      } catch (e) {
        debugPrint('Fehler beim Laden der Streaks: $e');
      }
    }
  }

  Future<void> _loadActivityHistory() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('actionHistory')
            .get();
        
        final history = <String, List<DateTime>>{};
        for (var doc in snapshot.docs) {
          final actionType = doc['actionType'] as String;
          final timestamp = (doc['timestamp'] as Timestamp).toDate();
          
          if (!history.containsKey(actionType)) {
            history[actionType] = [];
          }
          history[actionType]!.add(timestamp);
        }
        
        setState(() {
          _activityHistory = history;
        });
      } catch (e) {
        debugPrint('Fehler beim Laden der Aktivitätshistorie: $e');
      }
    }
  }

  Future<void> _addCustomActivity(String title, IconData icon, Color color, int reminderHours, TimeOfDay? reminderTime) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('customActivities')
            .add({
          'title': title,
          'iconCode': icon.codePoint,
          'color': color.value,
          'reminderHours': reminderHours,
          'reminderText': 'Zeit für $title! 🎯',
          'reminderTime': reminderTime != null
              ? DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  reminderTime.hour,
                  reminderTime.minute,
                )
              : null,
        });

        final newActivity = {
          'key': docRef.id,
          'title': title,
          'icon': icon,
          'color': color,
          'gradient': [color, color.withOpacity(0.7)],
          'reminderHours': reminderHours,
          'reminderText': 'Zeit für $title! 🎯',
          'customReminder': true,
          'reminderTime': reminderTime != null
              ? DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  reminderTime.hour,
                  reminderTime.minute,
                )
              : null,
          'streak': 0,
          'badges': [
            {
              'name': '$title-Starter',
              'description': '3 Tage in Folge $title geschafft',
              'requirement': 3
            },
            {
              'name': '$title-Meister',
              'description': '7 Tage in Folge $title geschafft',
              'requirement': 7
            },
          ],
        };

        setState(() {
          _activities.add(newActivity);
        });

        if (reminderTime != null) {
          _scheduleCustomReminder(newActivity);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title wurde zu deinen Routinen hinzugefügt! 🎉'),
            backgroundColor: color,
          ),
        );
      } catch (e) {
        debugPrint('Fehler beim Hinzufügen der benutzerdefinierten Aktivität: $e');
      }
    }
  }

  Future<void> _scheduleCustomReminder(Map<String, dynamic> activity) async {
    if (activity['reminderTime'] == null) return;

    final now = DateTime.now();
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      activity['reminderTime'].hour,
      activity['reminderTime'].minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'custom_reminders_channel',
      'Benutzerdefinierte Erinnerungen',
      channelDescription: 'Erinnerungen für benutzerdefinierte Routinen',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _activities.indexOf(activity),
      'Erinnerung: ${activity['title']}',
      activity['reminderText'],
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _updateStreak(String key) {
    final now = DateTime.now();
    final history = _activityHistory[key] ?? [];
    history.sort((a, b) => b.compareTo(a));

    var streak = 1;
    var lastDate = now;

    for (var i = 0; i < history.length; i++) {
      final date = history[i];
      if (lastDate.difference(date).inDays == 1) {
        streak++;
        lastDate = date;
      } else if (lastDate.difference(date).inDays > 1) {
        break;
      }
    }

    setState(() {
      _streaks[key] = streak;
    });

    _checkAndAwardBadges(key, streak);
  }

  void _checkAndAwardBadges(String key, int streak) {
    final activity = _activities.firstWhere((a) => a['key'] == key);
    final badges = activity['badges'] as List<Map<String, dynamic>>;

    for (var badge in badges) {
      if (streak >= badge['requirement'] &&
          !_earnedBadges.any((b) => b['name'] == badge['name'])) {
        setState(() {
          _earnedBadges.add(badge);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Neuer Badge freigeschaltet: ${badge['name']}! 🎉'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF667eea),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeApp,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasNotificationPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off,
              color: Colors.orange,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Benachrichtigungen sind deaktiviert',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Um Erinnerungen zu erhalten, aktiviere bitte die Benachrichtigungen in deinen Einstellungen.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await _checkNotificationPermissions();
                if (_hasNotificationPermission) {
                  await _initNotifications();
                }
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Benachrichtigungen aktivieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 40 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isTablet),
                  const SizedBox(height: 30),
                  _buildStreakOverview(isTablet),
                  const SizedBox(height: 30),
                  _buildActivityGrid(isTablet),
                  const SizedBox(height: 30),
                  _buildBadgesSection(isTablet),
                  const SizedBox(height: 30),
                  _buildLastActivitiesList(isTablet),
                  if (_showAddRoutine) ...[
                    const SizedBox(height: 30),
                    _buildAddRoutineForm(isTablet),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (_isLoading || _errorMessage != null) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        setState(() {
          _showAddRoutine = !_showAddRoutine;
        });
      },
      backgroundColor: const Color(0xFF667eea),
      child: Icon(
        _showAddRoutine ? Icons.close : Icons.add,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: const FlexibleSpaceBar(
          title: Text(
            'Intelligente Erinnerungen',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: false,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: Colors.white,
              size: isTablet ? 40 : 32,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Tägliche Aktivitäten',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Halten Sie Ihre Routinen im Blick',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakOverview(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktuelle Streaks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_streaks.values.fold(0, (p, c) => p + c)} Tage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _activities.map((activity) {
              final streak = _streaks[activity['key']] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      activity['icon'],
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$streak Tage',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(bool isTablet) {
    if (_earnedBadges.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2d3748), Color(0xFF1a202c)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Errungenschaften',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _earnedBadges.map((badge) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          badge['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      badge['description'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRoutineForm(bool isTablet) {
    final titleController = TextEditingController();
    final reminderHoursController = TextEditingController();
    TimeOfDay? selectedTime;
    IconData selectedIcon = Icons.star;
    Color selectedColor = const Color(0xFF667eea);

    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2d3748), Color(0xFF1a202c)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Neue Routine erstellen',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name der Routine',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF667eea),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: reminderHoursController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Erinnerung alle X Stunden',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF667eea),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    selectedTime = time;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.access_time),
                label: const Text('Uhrzeit'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    Icons.fitness_center,
                    Icons.self_improvement,
                    Icons.book,
                    Icons.music_note,
                    Icons.brush,
                    Icons.sports_esports,
                    Icons.favorite,
                    Icons.psychology,
                  ].map((icon) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedIcon = icon;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon
                              ? const Color(0xFF667eea)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    const Color(0xFF4facfe),
                    const Color(0xFF43e97b),
                    const Color(0xFF667eea),
                    const Color(0xFFfa709a),
                    const Color(0xFFfee140),
                    const Color(0xFF38f9d7),
                  ].map((color) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: selectedColor == color
                              ? Border.all(
                                  color: Colors.white,
                                  width: 2,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    reminderHoursController.text.isNotEmpty) {
                  _addCustomActivity(
                    titleController.text,
                    selectedIcon,
                    selectedColor,
                    int.parse(reminderHoursController.text),
                    selectedTime,
                  );
                  setState(() {
                    _showAddRoutine = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Routine hinzufügen',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityGrid(bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 4 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return _buildActivityCard(activity, isTablet);
      },
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isTablet) {
    final lastTime = _activityHistory[activity['key']]?.last;
    final hasActivity = lastTime != null;
    
    return GestureDetector(
      onTap: () => _recordActionTime(activity['key']),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: activity['gradient'],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: activity['color'].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (hasActivity)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(lastTime),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 12 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    activity['icon'],
                    color: Colors.white,
                    size: isTablet ? 40 : 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activity['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastActivitiesList(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 30 : 25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2d3748),
            Color(0xFF1a202c),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.history,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                'Letzte Aktivitäten',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._activities.map((activity) {
            final lastTime = _activityHistory[activity['key']]?.last;
            if (lastTime == null) return const SizedBox.shrink();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: activity['gradient'],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity['icon'],
                      color: Colors.white,
                      size: isTablet ? 24 : 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zuletzt: ${DateFormat('dd.MM.yyyy HH:mm').format(lastTime)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).where((widget) => widget != const SizedBox.shrink()).toList(),
        ],
      ),
    );
  }

  Future<void> _recordActionTime(String actionKey) async {
    if (_prefs == null) return;
    final now = DateTime.now();
    await _prefs!.setString(actionKey, now.toIso8601String());

    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('actionHistory')
            .add({
          'actionType': actionKey,
          'timestamp': Timestamp.fromDate(now),
        });
        debugPrint('Aktion $actionKey in Firestore gespeichert um $now');
      } catch (e) {
        debugPrint('Fehler beim Firestore-Speichern für $actionKey: $e');
      }
    } else {
      debugPrint('Kein Benutzer angemeldet. Firestore-Speicherung abgebrochen.');
    }

    debugPrint('Aktion $actionKey um $now aufgezeichnet');
    _checkAndTriggerReminders();
    if (mounted) {
      setState(() {});
    }
  }

  void _startReminderTimer() {
    _reminderTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      debugPrint('Periodische Überprüfung der Erinnerungen...');
      _checkAndTriggerReminders();
    });
  }

  Future<void> _checkAndTriggerReminders() async {
    if (_prefs == null) return;

    final now = DateTime.now();

    for (var activity in _activities) {
      final lastTime = _activityHistory[activity['key']]?.last;
      if (lastTime != null) {
        final duration = now.difference(lastTime);
        if (duration.inHours >= activity['reminderHours']) {
          await _showNotification(
            _activities.indexOf(activity),
            'Erinnerung: ${activity['title']}',
            activity['reminderText'],
            activity['key'],
          );
        }
      } else {
        debugPrint('Keine vorherige Aufzeichnung für ${activity['title']}.');
      }
    }
  }

  Future<void> _showNotification(
      int id, String title, String body, String payload) async {
    if (kIsWeb) {
      try {
        if (html.Notification.supported) {
          final permission = await html.Notification.requestPermission();
          if (permission == 'granted') {
            html.Notification(title, body: body);
          }
        }
      } catch (e) {
        debugPrint('Erreur lors de l\'affichage de la notification web: $e');
      }
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'smart_reminder_channel',
      'Intelligente Erinnerungen',
      channelDescription: 'Benachrichtigungen für intelligente Erinnerungen',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  void _showActivityDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d3748),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              activity['icon'],
              color: activity['color'],
            ),
            const SizedBox(width: 12),
            Text(
              activity['title'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Letzte Aktivität: ${_getLastActivityTimeString(activity['key'])}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Streak: ${_streaks[activity['key']] ?? 0} Tage',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _recordActionTime(activity['key']);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activity['color'],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Jetzt aufzeichnen'),
          ),
        ],
      ),
    );
  }

  String _getLastActivityTimeString(String key) {
    final lastTime = _activityHistory[key]?.last;
    if (lastTime == null) return 'Keine Aufzeichnung';
    
    final now = DateTime.now();
    final difference = now.difference(lastTime);
    
    if (difference.inMinutes < 60) {
      return 'Vor ${difference.inMinutes} Minuten';
    } else if (difference.inHours < 24) {
      return 'Vor ${difference.inHours} Stunden';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(lastTime);
    }
  }
}