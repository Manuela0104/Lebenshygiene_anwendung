import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/gamification_model.dart';
import 'dart:math' as math;

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Benutzerfortschritt abrufen oder erstellen
  Future<UserProgress> getUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .doc('user_progress')
        .get();

    if (doc.exists) {
      return UserProgress.fromFirestore(doc);
    } else {
      // Neuen Fortschritt erstellen
      final newProgress = UserProgress(
        userId: user.uid,
        currentLevel: 1,
        currentPoints: 0,
        pointsToNextLevel: 100,
        totalPoints: 0,
        streakDays: 0,
        totalHabitsCompleted: 0,
        totalChallengesCompleted: 0,
        unlockedBadges: [],
        recentAchievements: [],
        lastUpdated: DateTime.now(),
        categoryPoints: {},
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc('user_progress')
          .set(newProgress.toFirestore());

      return newProgress;
    }
  }

  // Punkte hinzufügen
  Future<void> addPoints(int points, String reason, String category) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final progress = await getUserProgress();
    final newTotalPoints = progress.totalPoints + points;
    final newCurrentPoints = progress.currentPoints + points;

    // Level-Up prüfen
    int newLevel = progress.currentLevel;
    int newPointsToNextLevel = progress.pointsToNextLevel;

    if (newCurrentPoints >= progress.pointsToNextLevel) {
      newLevel++;
      newPointsToNextLevel = _calculatePointsForNextLevel(newLevel);
    }

    // Fortschritt aktualisieren
    final updatedProgress = UserProgress(
      userId: progress.userId,
      currentLevel: newLevel,
      currentPoints: newCurrentPoints,
      pointsToNextLevel: newPointsToNextLevel,
      totalPoints: newTotalPoints,
      streakDays: progress.streakDays,
      totalHabitsCompleted: progress.totalHabitsCompleted,
      totalChallengesCompleted: progress.totalChallengesCompleted,
      unlockedBadges: progress.unlockedBadges,
      recentAchievements: progress.recentAchievements,
      lastUpdated: DateTime.now(),
      categoryPoints: progress.categoryPoints,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .doc('user_progress')
        .set(updatedProgress.toFirestore());

    // Transaktion protokollieren
    final transaction = PointsTransaction(
      id: '',
      userId: user.uid,
      points: points,
      reason: reason,
      category: category,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .add(transaction.toFirestore());

    // Achievements prüfen
    await _checkAchievements(updatedProgress);
  }

  // Punkte für das nächste Level berechnen
  int _calculatePointsForNextLevel(int level) {
    // Exponentieller Anstieg: 100, 200, 400, 800, 1600, ...
    return 100 * (1 << (level - 1));
  }

  // Badges prüfen und freischalten
  Future<void> checkAndUnlockBadges() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final progress = await getUserProgress();
    final allBadges = BadgeDefinitions.getAllBadges();
    final unlockedBadges = List<String>.from(progress.unlockedBadges);

    for (final badge in allBadges) {
      if (!unlockedBadges.contains(badge.id)) {
        final shouldUnlock = await _checkBadgeCriteria(badge, user.uid);
        if (shouldUnlock) {
          unlockedBadges.add(badge.id);
          
          // Badge-Unlock protokollieren
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('badge_unlocks')
              .add({
            'badgeId': badge.id,
            'badgeName': badge.name,
            'unlockedAt': Timestamp.now(),
          });

          // Punkte für Badge-Unlock
          await addPoints(25, 'Badge freigeschaltet: ${badge.name}', 'badge');
        }
      }
    }

    // Fortschritt aktualisieren
    final updatedProgress = UserProgress(
      userId: progress.userId,
      currentLevel: progress.currentLevel,
      currentPoints: progress.currentPoints,
      pointsToNextLevel: progress.pointsToNextLevel,
      totalPoints: progress.totalPoints,
      streakDays: progress.streakDays,
      totalHabitsCompleted: progress.totalHabitsCompleted,
      totalChallengesCompleted: progress.totalChallengesCompleted,
      unlockedBadges: unlockedBadges,
      recentAchievements: progress.recentAchievements,
      lastUpdated: DateTime.now(),
      categoryPoints: progress.categoryPoints,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .doc('user_progress')
        .set(updatedProgress.toFirestore());
  }

  // Badge-Kriterien prüfen
  Future<bool> _checkBadgeCriteria(Badge badge, String userId) async {
    switch (badge.category) {
      case 'water':
        return await _checkWaterBadge(badge, userId);
      case 'steps':
        return await _checkStepsBadge(badge, userId);
      case 'sleep':
        return await _checkSleepBadge(badge, userId);
      case 'mood':
        return await _checkMoodBadge(badge, userId);
      case 'habits':
        return await _checkHabitsBadge(badge, userId);
      case 'streak':
        return await _checkStreakBadge(badge, userId);
      default:
        return false;
    }
  }

  Future<bool> _checkWaterBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    int consecutiveDays = 0;
    final dates = snapshot.docs
        .map((doc) => (doc.data()['date'] as Timestamp).toDate())
        .toList()
      ..sort();

    for (final doc in snapshot.docs) {
      final water = (doc.data()['water'] ?? 0.0).toDouble();
      if (water >= 2.0) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkStepsBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    int consecutiveDays = 0;
    for (final doc in snapshot.docs) {
      final steps = (doc.data()['steps'] ?? 0.0).toDouble();
      if (steps >= 8000) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkSleepBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    int consecutiveDays = 0;
    for (final doc in snapshot.docs) {
      final sleep = (doc.data()['sleep'] ?? 0.0).toDouble();
      if (sleep >= 7.0) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkMoodBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final uniqueDays = snapshot.docs
        .map((doc) => DateFormat('yyyy-MM-dd').format((doc.data()['timestamp'] as Timestamp).toDate()))
        .toSet();

    return uniqueDays.length >= days;
  }

  Future<bool> _checkHabitsBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    int consecutiveDays = 0;
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_status')
          .doc(dateStr)
          .get();

      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        final totalHabits = data.length;
        final completedHabits = data.values.where((value) => value == true).length;
        final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

        if (completionRate >= 0.8) {
          consecutiveDays++;
        } else {
          consecutiveDays = 0;
        }
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkStreakBadge(Badge badge, String userId) async {
    final days = _getRequiredDays(badge.id);
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    int consecutiveDays = 0;
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final allGoalsMet = await _checkAllDailyGoals(userId, date);
      if (allGoalsMet) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkAllDailyGoals(String userId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    // Wasser prüfen
    final waterData = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .doc(dateStr)
        .get();
    
    final water = waterData.exists ? (waterData.data()?['water'] ?? 0.0).toDouble() : 0.0;
    final steps = waterData.exists ? (waterData.data()?['steps'] ?? 0.0).toDouble() : 0.0;
    final sleep = waterData.exists ? (waterData.data()?['sleep'] ?? 0.0).toDouble() : 0.0;

    // Stimmung prüfen
    final moodSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .where('timestamp', isLessThan: Timestamp.fromDate(date.add(const Duration(days: 1))))
        .get();

    final moodTracked = moodSnapshot.docs.isNotEmpty;

    // Gewohnheiten prüfen
    final statusSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('daily_status')
        .doc(dateStr)
        .get();

    double habitCompletion = 0.0;
    if (statusSnapshot.exists) {
      final data = statusSnapshot.data() as Map<String, dynamic>;
      final totalHabits = data.length;
      final completedHabits = data.values.where((value) => value == true).length;
      habitCompletion = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
    }

    return water >= 2.0 && steps >= 8000 && sleep >= 7.0 && moodTracked && habitCompletion >= 0.8;
  }

  int _getRequiredDays(String badgeId) {
    if (badgeId.contains('beginner')) return 7;
    if (badgeId.contains('expert')) return 30;
    if (badgeId.contains('master')) return 100;
    if (badgeId.contains('7')) return 7;
    if (badgeId.contains('30')) return 30;
    if (badgeId.contains('100')) return 100;
    return 7;
  }

  // Achievements prüfen
  Future<void> _checkAchievements(UserProgress progress) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final allAchievements = AchievementDefinitions.getAllAchievements();
    final recentAchievements = List<String>.from(progress.recentAchievements);

    for (final achievement in allAchievements) {
      if (!recentAchievements.contains(achievement.id)) {
        final shouldUnlock = await _checkAchievementCriteria(achievement, user.uid);
        if (shouldUnlock) {
          recentAchievements.add(achievement.id);
          
          // Achievement-Unlock protokollieren
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('achievement_unlocks')
              .add({
            'achievementId': achievement.id,
            'achievementTitle': achievement.title,
            'pointsReward': achievement.pointsReward,
            'unlockedAt': Timestamp.now(),
          });

          // Punkte für Achievement
          await addPoints(achievement.pointsReward, 'Achievement: ${achievement.title}', 'achievement');
        }
      }
    }

    // Fortschritt aktualisieren
    final updatedProgress = UserProgress(
      userId: progress.userId,
      currentLevel: progress.currentLevel,
      currentPoints: progress.currentPoints,
      pointsToNextLevel: progress.pointsToNextLevel,
      totalPoints: progress.totalPoints,
      streakDays: progress.streakDays,
      totalHabitsCompleted: progress.totalHabitsCompleted,
      totalChallengesCompleted: progress.totalChallengesCompleted,
      unlockedBadges: progress.unlockedBadges,
      recentAchievements: recentAchievements,
      lastUpdated: DateTime.now(),
      categoryPoints: progress.categoryPoints,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('progress')
        .doc('user_progress')
        .set(updatedProgress.toFirestore());
  }

  Future<bool> _checkAchievementCriteria(Achievement achievement, String userId) async {
    switch (achievement.category) {
      case 'daily':
        return await _checkDailyAchievement(achievement, userId);
      case 'weekly':
        return await _checkWeeklyAchievement(achievement, userId);
      case 'monthly':
        return await _checkMonthlyAchievement(achievement, userId);
      case 'special':
        return await _checkSpecialAchievement(achievement, userId);
      default:
        return false;
    }
  }

  Future<bool> _checkDailyAchievement(Achievement achievement, String userId) async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(today);

    switch (achievement.id) {
      case 'daily_water_goal':
        final waterData = await _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyData')
            .doc(dateStr)
            .get();
        final water = waterData.exists ? (waterData.data()?['water'] ?? 0.0).toDouble() : 0.0;
        return water >= 2.0;

      case 'daily_steps_goal':
        final stepsData = await _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyData')
            .doc(dateStr)
            .get();
        final steps = stepsData.exists ? (stepsData.data()?['steps'] ?? 0.0).toDouble() : 0.0;
        return steps >= 8000;

      case 'daily_sleep_goal':
        final sleepData = await _firestore
            .collection('users')
            .doc(userId)
            .collection('dailyData')
            .doc(dateStr)
            .get();
        final sleep = sleepData.exists ? (sleepData.data()?['sleep'] ?? 0.0).toDouble() : 0.0;
        return sleep >= 7.0;

      case 'daily_mood_tracking':
        final moodSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('moodEntries')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
            .where('timestamp', isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))))
            .get();
        return moodSnapshot.docs.isNotEmpty;

      case 'daily_habits_complete':
        final statusSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('daily_status')
            .doc(dateStr)
            .get();
        if (statusSnapshot.exists) {
          final data = statusSnapshot.data() as Map<String, dynamic>;
          final totalHabits = data.length;
          final completedHabits = data.values.where((value) => value == true).length;
          return totalHabits > 0 && completedHabits == totalHabits;
        }
        return false;

      default:
        return false;
    }
  }

  Future<bool> _checkWeeklyAchievement(Achievement achievement, String userId) async {
    final days = 7;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    switch (achievement.id) {
      case 'weekly_water_streak':
        return await _checkStreak(userId, 'water', 2.0, days, startDate, endDate);
      case 'weekly_steps_streak':
        return await _checkStreak(userId, 'steps', 8000, days, startDate, endDate);
      case 'weekly_sleep_streak':
        return await _checkStreak(userId, 'sleep', 7.0, days, startDate, endDate);
      case 'weekly_mood_streak':
        return await _checkMoodStreak(userId, days, startDate, endDate);
      case 'weekly_habits_streak':
        return await _checkHabitsStreak(userId, days, startDate, endDate);
      default:
        return false;
    }
  }

  Future<bool> _checkMonthlyAchievement(Achievement achievement, String userId) async {
    final days = 30;
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    switch (achievement.id) {
      case 'monthly_water_master':
        return await _checkStreak(userId, 'water', 2.0, days, startDate, endDate);
      case 'monthly_steps_master':
        return await _checkStreak(userId, 'steps', 8000, days, startDate, endDate);
      case 'monthly_sleep_master':
        return await _checkStreak(userId, 'sleep', 7.0, days, startDate, endDate);
      case 'monthly_mood_master':
        return await _checkMoodStreak(userId, days, startDate, endDate);
      case 'monthly_habits_master':
        return await _checkHabitsStreak(userId, days, startDate, endDate);
      default:
        return false;
    }
  }

  Future<bool> _checkSpecialAchievement(Achievement achievement, String userId) async {
    final progress = await getUserProgress();

    switch (achievement.id) {
      case 'first_level_up':
        return progress.currentLevel >= 2;
      case 'level_10_milestone':
        return progress.currentLevel >= 10;
      case 'level_50_milestone':
        return progress.currentLevel >= 50;
      case 'first_badge':
        return progress.unlockedBadges.isNotEmpty;
      case 'badge_collector':
        return progress.unlockedBadges.length >= 10;
      case 'badge_master':
        return progress.unlockedBadges.length >= 18;
      default:
        return false;
    }
  }

  Future<bool> _checkStreak(String userId, String metric, double target, int days, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('dailyData')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    int consecutiveDays = 0;
    for (final doc in snapshot.docs) {
      final value = (doc.data()[metric] ?? 0.0).toDouble();
      if (value >= target) {
        consecutiveDays++;
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  Future<bool> _checkMoodStreak(String userId, int days, DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('moodEntries')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final uniqueDays = snapshot.docs
        .map((doc) => DateFormat('yyyy-MM-dd').format((doc.data()['timestamp'] as Timestamp).toDate()))
        .toSet();

    return uniqueDays.length >= days;
  }

  Future<bool> _checkHabitsStreak(String userId, int days, DateTime startDate, DateTime endDate) async {
    int consecutiveDays = 0;
    for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final statusSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_status')
          .doc(dateStr)
          .get();

      if (statusSnapshot.exists) {
        final data = statusSnapshot.data() as Map<String, dynamic>;
        final totalHabits = data.length;
        final completedHabits = data.values.where((value) => value == true).length;
        final completionRate = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

        if (completionRate >= 0.8) {
          consecutiveDays++;
        } else {
          consecutiveDays = 0;
        }
      } else {
        consecutiveDays = 0;
      }
    }

    return consecutiveDays >= days;
  }

  // Alle Badges abrufen
  Future<List<Badge>> getAllBadges() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final progress = await getUserProgress();
    final allBadges = BadgeDefinitions.getAllBadges();

    return allBadges.map((badge) {
      return Badge(
        id: badge.id,
        name: badge.name,
        description: badge.description,
        iconPath: badge.iconPath,
        requiredPoints: badge.requiredPoints,
        category: badge.category,
        isUnlocked: progress.unlockedBadges.contains(badge.id),
        unlockedAt: progress.unlockedBadges.contains(badge.id) ? DateTime.now() : null,
      );
    }).toList();
  }

  // Alle Achievements abrufen
  Future<List<Achievement>> getAllAchievements() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final progress = await getUserProgress();
    final allAchievements = AchievementDefinitions.getAllAchievements();

    return allAchievements.map((achievement) {
      return Achievement(
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        pointsReward: achievement.pointsReward,
        category: achievement.category,
        criteria: achievement.criteria,
        isCompleted: progress.recentAchievements.contains(achievement.id),
      );
    }).toList();
  }

  // Transaktionsverlauf abrufen
  Future<List<PointsTransaction>> getTransactionHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Benutzer nicht angemeldet');

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) => PointsTransaction.fromFirestore(doc))
        .toList();
  }

  // Leaderboard-Daten abrufen
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    final snapshot = await _firestore
        .collectionGroup('progress')
        .orderBy('totalPoints', descending: true)
        .limit(10)
        .get();

    final leaderboard = <Map<String, dynamic>>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final userId = data['userId'] as String;
      
      // Benutzername abrufen
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final username = userDoc.data()?['username'] ?? 'Unbekannter Benutzer';

      leaderboard.add({
        'userId': userId,
        'username': username,
        'totalPoints': data['totalPoints'] ?? 0,
        'currentLevel': data['currentLevel'] ?? 1,
      });
    }

    return leaderboard;
  }
} 