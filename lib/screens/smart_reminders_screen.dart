import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart'; // Für die Datumsformatierung
import 'dart:async'; // Für Timer
import 'package:timezone/timezone.dart' as tz; // Für Zeitzonen
import 'package:timezone/data/latest.dart' as tzdata; // Für Zeitzonendaten
import 'package:cloud_firestore/cloud_firestore.dart'; // Für Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Für den aktuellen Benutzer

class SmartRemindersScreen extends StatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  State<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends State<SmartRemindersScreen> {
  SharedPreferences? _prefs;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _reminderTimer;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Schlüssel für SharedPreferences
  final String _lastHydrationKey = 'last_hydration_time';
  final String _lastWalkKey = 'last_walk_time';
  final String _lastSleepKey = 'last_sleep_time';
  final String _lastShowerKey = 'last_shower_time';

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones(); // Zeitzonendaten initialisieren
    _initSharedPreferences();
    _initNotifications();
    _startReminderTimer(); // Timer für periodische Überprüfungen starten
    _scheduleDailyEveningShowerReminder(); // Beispiel für geplante Erinnerung
  }

  @override
  void dispose() {
    _reminderTimer?.cancel(); // Timer beenden, wenn der Bildschirm verlassen wird
    super.dispose();
  }

  Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Möglicherweise die letzten Aktionszeiten hier laden, falls für die initiale Anzeige benötigt
    if (mounted) {
      setState(() {}); // UI aktualisieren, wenn die letzten Zeiten angezeigt werden
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Ersetzen Sie 'app_icon' durch den Namen Ihres Icons (ohne Erweiterung)

    // TODO: Initialisierungseinstellungen für iOS und macOS hinzufügen
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {
      // TODO: Klick auf Benachrichtigung behandeln
      // Beispiel: Navigation zu einer anderen App-Seite
    });
    // Berechtigung für Benachrichtigungen anfordern (erforderlich für einige Android/iOS-Versionen)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _recordActionTime(String actionKey) async {
    if (_prefs == null) return;
    final now = DateTime.now();
    await _prefs!.setString(actionKey, now.toIso8601String());

    // Aktion in Firestore speichern
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
    // Nach dem Aufzeichnen der Aktion können wir prüfen, ob eine geplante Erinnerung storniert werden muss
    // oder ob eine neue bedingte Überprüfung ausgelöst werden soll
    _checkAndTriggerReminders(); // Erinnerungen nach jeder aufgezeichneten Aktion prüfen
    if (mounted) {
      setState(() {}); // UI aktualisieren, wenn die letzten Zeiten angezeigt werden
    }
  }

   DateTime? _getLastActionTime(String actionKey) {
    if (_prefs == null) return null;
    final timeString = _prefs!.getString(actionKey);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      debugPrint('Fehler beim Parsen des Datums für $actionKey: $e');
      return null;
    }
  }

  void _startReminderTimer() {
    // Erinnerungen alle 30 Minuten prüfen (anpassbar nach Bedarf)
    _reminderTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      debugPrint('Periodische Überprüfung der Erinnerungen...');
      _checkAndTriggerReminders();
    });
  }

  Future<void> _checkAndTriggerReminders() async {
    if (_prefs == null) return;

    final now = DateTime.now();

    // Überprüfung für Hydration
    final lastHydrationTime = _getLastActionTime(_lastHydrationKey);
    if (lastHydrationTime != null) {
      final hydrationDuration = now.difference(lastHydrationTime);
      if (hydrationDuration.inHours >= 3) {
        await _showNotification(
          0,
          'Erinnerung: Hydration',
          'Du hast seit ${hydrationDuration.inHours} Stunden nichts getrunken. Wie wäre es mit einem Glas Wasser? 💧',
          'hydration_payload',
        );
      }
    } else {
      debugPrint('Keine vorherige Aufzeichnung für Hydration.');
    }

    // Überprüfung für Bewegung
    final lastWalkTime = _getLastActionTime(_lastWalkKey);
    if (lastWalkTime != null) {
      final walkDuration = now.difference(lastWalkTime);
      if (walkDuration.inHours >= 24) {
         await _showNotification(
          1,
          'Erinnerung: Bewegung',
          'Zeit für Bewegung! Dein letzter Spaziergang war vor ${walkDuration.inHours} Stunden 🚶‍♀️🚶‍♂️',
          'walk_payload',
        );
      }
    } else {
       debugPrint('Keine vorherige Aufzeichnung für Bewegung.');
    }

    // Überprüfung für Schlaf
    final lastSleepTime = _getLastActionTime(_lastSleepKey);
    if (lastSleepTime != null) {
      final sleepDuration = now.difference(lastSleepTime);
      if (sleepDuration.inHours >= 24 && now.hour >= 21) {
         await _showNotification(
          2,
          'Erinnerung: Schlaf',
          'Du hast heute noch keinen Schlaf eingetragen. Zeit für eine gute Nacht! 😴',
          'sleep_payload',
        );
      }
    } else {
       debugPrint('Keine vorherige Aufzeichnung für Schlaf.');
    }

    // Überprüfung für Dusche
    final lastShowerTime = _getLastActionTime(_lastShowerKey);
    if (lastShowerTime != null) {
      final showerDuration = now.difference(lastShowerTime);
      if (showerDuration.inHours >= 48) {
         await _showNotification(
          3,
          'Erinnerung: Dusche',
          'Deine letzte Dusche war vor ${showerDuration.inHours} Stunden. Zeit für eine Erfrischung? 🛀',
          'shower_payload',
        );
      }
    } else {
       debugPrint('Keine vorherige Aufzeichnung für Dusche.');
    }
  }

  Future<void> _showNotification(
      int id, String title, String body, String payload) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('smart_reminder_channel', // Kanal-ID
            'Intelligente Erinnerungen', // Kanalname
            channelDescription: 'Benachrichtigungen für intelligente Erinnerungen', // Kanalbeschreibung
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker');

    // TODO: Benachrichtigungsdetails für iOS und macOS hinzufügen
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(id, title, body, notificationDetails,
        payload: payload);
  }

  Future<void> _scheduleDailyEveningShowerReminder() async {
    const int reminderId = 10;
    const String channelId = 'scheduled_reminders_channel';
    const String channelName = 'Geplante Erinnerungen';
    const String channelDescription = 'Benachrichtigungen für geplante Erinnerungen zu bestimmten Zeiten';

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(channelId, channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high);

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        21,
        0,
        0
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
        reminderId,
        'Abendroutine',
        'Vergiss nicht deine Abenddusche! 🛀',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);

    debugPrint('Duscherinnerung geplant für ${scheduledTime.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    final lastHydration = _getLastActionTime(_lastHydrationKey);
    final lastWalk = _getLastActionTime(_lastWalkKey);
    final lastSleep = _getLastActionTime(_lastSleepKey);
    final lastShower = _getLastActionTime(_lastShowerKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intelligente Erinnerungen'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Aktion aufzeichnen:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _recordActionTime(_lastHydrationKey),
                child: const Text("Ich habe Wasser getrunken"),
              ),
              ElevatedButton(
                onPressed: () => _recordActionTime(_lastWalkKey),
                child: const Text("Ich habe einen Spaziergang gemacht"),
              ),
              ElevatedButton(
                onPressed: () => _recordActionTime(_lastSleepKey),
                child: const Text("Ich habe geschlafen"),
              ),
              ElevatedButton(
                onPressed: () => _recordActionTime(_lastShowerKey),
                child: const Text("Ich habe geduscht"),
              ),
              const SizedBox(height: 40),
              const Text(
                'Letzte aufgezeichnete Aktion:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(lastHydration != null ? 'Hydration: ${DateFormat('dd.MM.yyyy HH:mm').format(lastHydration)}' : 'Hydration: Noch nicht aufgezeichnet'),
              Text(lastWalk != null ? 'Spaziergang: ${DateFormat('dd.MM.yyyy HH:mm').format(lastWalk)}' : 'Spaziergang: Noch nicht aufgezeichnet'),
              Text(lastSleep != null ? 'Schlaf: ${DateFormat('dd.MM.yyyy HH:mm').format(lastSleep)}' : 'Schlaf: Noch nicht aufgezeichnet'),
              Text(lastShower != null ? 'Dusche: ${DateFormat('dd.MM.yyyy HH:mm').format(lastShower)}' : 'Dusche: Noch nicht aufgezeichnet'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _checkAndTriggerReminders,
                child: const Text('Erinnerungen prüfen (Test)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 