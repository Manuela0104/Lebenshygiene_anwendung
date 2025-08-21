import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Level-Datenmodell für das Gamification-System
/// 
/// Definiert die Struktur für:
/// - Level-Nummer und Titel
/// - Beschreibung der Level-Anforderungen
/// - Erforderliche Punkte für Level-Aufstieg
/// - Freigeschaltete Features pro Level
/// - Spezielle Belohnungen für besondere Level
/// - Serialisierung für Datenpersistierung
/// 
/// Das Modell strukturiert das Fortschrittssystem
/// und motiviert Benutzer durch klar definierte Ziele.
class Level {
  final int level;
  final String title;
  final String description;
  final int requiredPoints;
  final List<String> unlockedFeatures;
  final String? specialReward;

  Level({
    required this.level,
    required this.title,
    required this.description,
    required this.requiredPoints,
    required this.unlockedFeatures,
    this.specialReward,
  });

  factory Level.fromMap(Map<String, dynamic> map) {
    return Level(
      level: map['level'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      requiredPoints: map['requiredPoints'] ?? 0,
      unlockedFeatures: List<String>.from(map['unlockedFeatures'] ?? []),
      specialReward: map['specialReward'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'title': title,
      'description': description,
      'requiredPoints': requiredPoints,
      'unlockedFeatures': unlockedFeatures,
      'specialReward': specialReward,
    };
  }
}

/// Benutzerfortschritt-Datenmodell für das Gamification-System
/// 
/// Verwaltet umfassende Informationen zu:
/// - Aktuelles Level und Punktestand
/// - Fortschritt zum nächsten Level
/// - Streak-Zählungen für kontinuierliche Aktivität
/// - Abgeschlossene Gewohnheiten und Challenges
/// - Freigeschaltete Badges und Erfolge
/// - Kategorie-spezifische Punkte
/// - Firestore-Integration für Datensynchronisation
/// 
/// Das Modell ist die zentrale Datenstruktur für
/// alle gamification-bezogenen Benutzeraktivitäten.
class UserProgress {
  final String userId;
  final int currentLevel;
  final int currentPoints;
  final int pointsToNextLevel;
  final int totalPoints;
  final int streakDays;
  final int totalHabitsCompleted;
  final int totalChallengesCompleted;
  final List<String> unlockedBadges;
  final List<String> recentAchievements;
  final DateTime lastUpdated;
  final Map<String, int> categoryPoints;

  UserProgress({
    required this.userId,
    required this.currentLevel,
    required this.currentPoints,
    required this.pointsToNextLevel,
    required this.totalPoints,
    required this.streakDays,
    required this.totalHabitsCompleted,
    required this.totalChallengesCompleted,
    required this.unlockedBadges,
    required this.recentAchievements,
    required this.lastUpdated,
    required this.categoryPoints,
  });

  factory UserProgress.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserProgress(
      userId: data['userId'] ?? '',
      currentLevel: data['currentLevel'] ?? 1,
      currentPoints: data['currentPoints'] ?? 0,
      pointsToNextLevel: data['pointsToNextLevel'] ?? 100,
      totalPoints: data['totalPoints'] ?? 0,
      streakDays: data['streakDays'] ?? 0,
      totalHabitsCompleted: data['totalHabitsCompleted'] ?? 0,
      totalChallengesCompleted: data['totalChallengesCompleted'] ?? 0,
      unlockedBadges: List<String>.from(data['unlockedBadges'] ?? []),
      recentAchievements: List<String>.from(data['recentAchievements'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      categoryPoints: Map<String, int>.from(data['categoryPoints'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'currentLevel': currentLevel,
      'currentPoints': currentPoints,
      'pointsToNextLevel': pointsToNextLevel,
      'totalPoints': totalPoints,
      'streakDays': streakDays,
      'totalHabitsCompleted': totalHabitsCompleted,
      'totalChallengesCompleted': totalChallengesCompleted,
      'unlockedBadges': unlockedBadges,
      'recentAchievements': recentAchievements,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'categoryPoints': categoryPoints,
    };
  }

  double get progressPercentage {
    return currentPoints / pointsToNextLevel;
  }

  bool get isLevelUp {
    return currentPoints >= pointsToNextLevel;
  }

  // Calculer les points nécessaires pour le prochain niveau
  int get pointsForNextLevel {
    return (100 * math.pow(currentLevel, 1.5)).round();
  }

  // Calculer le pourcentage de progression vers le prochain niveau
  double get progressToNextLevel {
    return currentPoints / pointsForNextLevel;
  }
}

/// Badge-Datenmodell für das Belohnungssystem
/// 
/// Definiert die Struktur für:
/// - Eindeutige Badge-Identifikation und Name
/// - Beschreibung der Badge-Anforderungen
/// - Icon-Pfad für visuelle Darstellung
/// - Erforderliche Punkte für Badge-Freischaltung
/// - Kategorie-Zuordnung (Wasser, Schritte, Schlaf, etc.)
/// - Freischaltungsstatus und -zeitpunkt
/// - Firestore-Integration für Datensynchronisation
/// 
/// Das Modell ermöglicht ein flexibles Badge-System
/// für verschiedene Gesundheitsaktivitäten.
class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final int requiredPoints;
  final String category; // 'water', 'steps', 'sleep', 'mood', 'habits', 'streak'
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.requiredPoints,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      iconPath: map['iconPath'] ?? '',
      requiredPoints: map['requiredPoints'] ?? 0,
      category: map['category'] ?? '',
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null ? (map['unlockedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'requiredPoints': requiredPoints,
      'category': category,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}

/// Achievement-Datenmodell für das Erfolgssystem
/// 
/// Definiert die Struktur für:
/// - Eindeutige Achievement-Identifikation und Titel
/// - Detaillierte Beschreibung der Erfolgsanforderungen
/// - Punktebelohnung für Achievement-Abschluss
/// - Kategorie-Zuordnung für Organisation
/// - Flexible Kriterien für verschiedene Erfolgstypen
/// - Abschlussstatus und -zeitpunkt
/// - Firestore-Integration für Fortschrittsverfolgung
/// 
/// Das Modell ermöglicht ein vielseitiges Achievement-System
/// für langfristige Benutzer-Motivation.
class Achievement {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final String category;
  final Map<String, dynamic> criteria;
  final bool isCompleted;
  final DateTime? completedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.category,
    required this.criteria,
    this.isCompleted = false,
    this.completedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pointsReward: map['pointsReward'] ?? 0,
      category: map['category'] ?? '',
      criteria: map['criteria'] ?? {},
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsReward': pointsReward,
      'category': category,
      'criteria': criteria,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}

class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final String reason;
  final String category;
  final DateTime timestamp;

  PointsTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.reason,
    required this.category,
    required this.timestamp,
  });

  factory PointsTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PointsTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      points: data['points'] ?? 0,
      reason: data['reason'] ?? '',
      category: data['category'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'points': points,
      'reason': reason,
      'category': category,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

// Vordefinierte Badges
class BadgeDefinitions {
  static List<Badge> getAllBadges() {
    return [
      // Wasser-Badges
      Badge(
        id: 'water_beginner',
        name: 'Wasser-Anfänger',
        description: 'Trinken Sie 7 Tage in Folge 2L Wasser',
        iconPath: 'assets/icons/badges/water_beginner.png',
        requiredPoints: 50,
        category: 'water',
      ),
      Badge(
        id: 'water_expert',
        name: 'Wasser-Experte',
        description: 'Trinken Sie 30 Tage in Folge 2L Wasser',
        iconPath: 'assets/icons/badges/water_expert.png',
        requiredPoints: 200,
        category: 'water',
      ),
      Badge(
        id: 'water_master',
        name: 'Wasser-Meister',
        description: 'Trinken Sie 100 Tage in Folge 2L Wasser',
        iconPath: 'assets/icons/badges/water_master.png',
        requiredPoints: 500,
        category: 'water',
      ),

      // Schritte-Badges
      Badge(
        id: 'steps_beginner',
        name: 'Schritt-Anfänger',
        description: 'Gehen Sie 7 Tage in Folge 8000 Schritte',
        iconPath: 'assets/icons/badges/steps_beginner.png',
        requiredPoints: 50,
        category: 'steps',
      ),
      Badge(
        id: 'steps_expert',
        name: 'Schritt-Experte',
        description: 'Gehen Sie 30 Tage in Folge 8000 Schritte',
        iconPath: 'assets/icons/badges/steps_expert.png',
        requiredPoints: 200,
        category: 'steps',
      ),
      Badge(
        id: 'steps_master',
        name: 'Schritt-Meister',
        description: 'Gehen Sie 100 Tage in Folge 8000 Schritte',
        iconPath: 'assets/icons/badges/steps_master.png',
        requiredPoints: 500,
        category: 'steps',
      ),

      // Schlaf-Badges
      Badge(
        id: 'sleep_beginner',
        name: 'Schlaf-Anfänger',
        description: 'Schlafen Sie 7 Tage in Folge 7+ Stunden',
        iconPath: 'assets/icons/badges/sleep_beginner.png',
        requiredPoints: 50,
        category: 'sleep',
      ),
      Badge(
        id: 'sleep_expert',
        name: 'Schlaf-Experte',
        description: 'Schlafen Sie 30 Tage in Folge 7+ Stunden',
        iconPath: 'assets/icons/badges/sleep_expert.png',
        requiredPoints: 200,
        category: 'sleep',
      ),
      Badge(
        id: 'sleep_master',
        name: 'Schlaf-Meister',
        description: 'Schlafen Sie 100 Tage in Folge 7+ Stunden',
        iconPath: 'assets/icons/badges/sleep_master.png',
        requiredPoints: 500,
        category: 'sleep',
      ),

      // Stimmungs-Badges
      Badge(
        id: 'mood_beginner',
        name: 'Stimmungs-Anfänger',
        description: 'Bewerten Sie Ihre Stimmung 7 Tage in Folge',
        iconPath: 'assets/icons/badges/mood_beginner.png',
        requiredPoints: 30,
        category: 'mood',
      ),
      Badge(
        id: 'mood_expert',
        name: 'Stimmungs-Experte',
        description: 'Bewerten Sie Ihre Stimmung 30 Tage in Folge',
        iconPath: 'assets/icons/badges/mood_expert.png',
        requiredPoints: 150,
        category: 'mood',
      ),
      Badge(
        id: 'mood_master',
        name: 'Stimmungs-Meister',
        description: 'Bewerten Sie Ihre Stimmung 100 Tage in Folge',
        iconPath: 'assets/icons/badges/mood_master.png',
        requiredPoints: 400,
        category: 'mood',
      ),

      // Gewohnheits-Badges
      Badge(
        id: 'habits_beginner',
        name: 'Gewohnheits-Anfänger',
        description: 'Vervollständigen Sie 7 Tage in Folge 80% Ihrer Gewohnheiten',
        iconPath: 'assets/icons/badges/habits_beginner.png',
        requiredPoints: 100,
        category: 'habits',
      ),
      Badge(
        id: 'habits_expert',
        name: 'Gewohnheits-Experte',
        description: 'Vervollständigen Sie 30 Tage in Folge 80% Ihrer Gewohnheiten',
        iconPath: 'assets/icons/badges/habits_expert.png',
        requiredPoints: 300,
        category: 'habits',
      ),
      Badge(
        id: 'habits_master',
        name: 'Gewohnheits-Meister',
        description: 'Vervollständigen Sie 100 Tage in Folge 80% Ihrer Gewohnheiten',
        iconPath: 'assets/icons/badges/habits_master.png',
        requiredPoints: 800,
        category: 'habits',
      ),

      // Streak-Badges
      Badge(
        id: 'streak_7',
        name: '7-Tage-Streak',
        description: 'Erreichen Sie 7 Tage in Folge alle Ziele',
        iconPath: 'assets/icons/badges/streak_7.png',
        requiredPoints: 200,
        category: 'streak',
      ),
      Badge(
        id: 'streak_30',
        name: '30-Tage-Streak',
        description: 'Erreichen Sie 30 Tage in Folge alle Ziele',
        iconPath: 'assets/icons/badges/streak_30.png',
        requiredPoints: 500,
        category: 'streak',
      ),
      Badge(
        id: 'streak_100',
        name: '100-Tage-Streak',
        description: 'Erreichen Sie 100 Tage in Folge alle Ziele',
        iconPath: 'assets/icons/badges/streak_100.png',
        requiredPoints: 1000,
        category: 'streak',
      ),
    ];
  }
}

// Vordefinierte Achievements
class AchievementDefinitions {
  static List<Achievement> getAllAchievements() {
    return [
      // Tägliche Achievements
      Achievement(
        id: 'daily_water_goal',
        title: 'Tägliches Wasserziel',
        description: 'Trinken Sie 2L Wasser an einem Tag',
        pointsReward: 10,
        category: 'daily',
        criteria: {'water': 2.0},
      ),
      Achievement(
        id: 'daily_steps_goal',
        title: 'Tägliches Schrittziel',
        description: 'Gehen Sie 8000 Schritte an einem Tag',
        pointsReward: 15,
        category: 'daily',
        criteria: {'steps': 8000},
      ),
      Achievement(
        id: 'daily_sleep_goal',
        title: 'Tägliches Schlafziel',
        description: 'Schlafen Sie 7+ Stunden in einer Nacht',
        pointsReward: 10,
        category: 'daily',
        criteria: {'sleep': 7.0},
      ),
      Achievement(
        id: 'daily_mood_tracking',
        title: 'Stimmungsverfolgung',
        description: 'Bewerten Sie Ihre Stimmung an einem Tag',
        pointsReward: 5,
        category: 'daily',
        criteria: {'mood_tracked': true},
      ),
      Achievement(
        id: 'daily_habits_complete',
        title: 'Gewohnheiten vervollständigt',
        description: 'Vervollständigen Sie 100% Ihrer Gewohnheiten an einem Tag',
        pointsReward: 20,
        category: 'daily',
        criteria: {'habits_completion': 1.0},
      ),

      // Wöchentliche Achievements
      Achievement(
        id: 'weekly_water_streak',
        title: 'Wöchentliche Wasserstreak',
        description: 'Trinken Sie 7 Tage in Folge 2L Wasser',
        pointsReward: 50,
        category: 'weekly',
        criteria: {'water_streak': 7},
      ),
      Achievement(
        id: 'weekly_steps_streak',
        title: 'Wöchentliche Schrittreak',
        description: 'Gehen Sie 7 Tage in Folge 8000 Schritte',
        pointsReward: 75,
        category: 'weekly',
        criteria: {'steps_streak': 7},
      ),
      Achievement(
        id: 'weekly_sleep_streak',
        title: 'Wöchentliche Schlafstreak',
        description: 'Schlafen Sie 7 Tage in Folge 7+ Stunden',
        pointsReward: 50,
        category: 'weekly',
        criteria: {'sleep_streak': 7},
      ),
      Achievement(
        id: 'weekly_mood_streak',
        title: 'Wöchentliche Stimmungsstreak',
        description: 'Bewerten Sie Ihre Stimmung 7 Tage in Folge',
        pointsReward: 30,
        category: 'weekly',
        criteria: {'mood_streak': 7},
      ),
      Achievement(
        id: 'weekly_habits_streak',
        title: 'Wöchentliche Gewohnheitsstreak',
        description: 'Vervollständigen Sie 7 Tage in Folge 80% Ihrer Gewohnheiten',
        pointsReward: 100,
        category: 'weekly',
        criteria: {'habits_streak': 7},
      ),

      // Monatliche Achievements
      Achievement(
        id: 'monthly_water_master',
        title: 'Monatlicher Wasser-Meister',
        description: 'Trinken Sie 30 Tage in Folge 2L Wasser',
        pointsReward: 200,
        category: 'monthly',
        criteria: {'water_streak': 30},
      ),
      Achievement(
        id: 'monthly_steps_master',
        title: 'Monatlicher Schritt-Meister',
        description: 'Gehen Sie 30 Tage in Folge 8000 Schritte',
        pointsReward: 300,
        category: 'monthly',
        criteria: {'steps_streak': 30},
      ),
      Achievement(
        id: 'monthly_sleep_master',
        title: 'Monatlicher Schlaf-Meister',
        description: 'Schlafen Sie 30 Tage in Folge 7+ Stunden',
        pointsReward: 200,
        category: 'monthly',
        criteria: {'sleep_streak': 30},
      ),
      Achievement(
        id: 'monthly_mood_master',
        title: 'Monatlicher Stimmungs-Meister',
        description: 'Bewerten Sie Ihre Stimmung 30 Tage in Folge',
        pointsReward: 150,
        category: 'monthly',
        criteria: {'mood_streak': 30},
      ),
      Achievement(
        id: 'monthly_habits_master',
        title: 'Monatlicher Gewohnheits-Meister',
        description: 'Vervollständigen Sie 30 Tage in Folge 80% Ihrer Gewohnheiten',
        pointsReward: 400,
        category: 'monthly',
        criteria: {'habits_streak': 30},
      ),

      // Spezielle Achievements
      Achievement(
        id: 'first_level_up',
        title: 'Erstes Level-Up',
        description: 'Erreichen Sie Level 2',
        pointsReward: 50,
        category: 'special',
        criteria: {'level': 2},
      ),
      Achievement(
        id: 'level_10_milestone',
        title: 'Level 10 Meilenstein',
        description: 'Erreichen Sie Level 10',
        pointsReward: 500,
        category: 'special',
        criteria: {'level': 10},
      ),
      Achievement(
        id: 'level_50_milestone',
        title: 'Level 50 Meilenstein',
        description: 'Erreichen Sie Level 50',
        pointsReward: 2000,
        category: 'special',
        criteria: {'level': 50},
      ),
      Achievement(
        id: 'first_badge',
        title: 'Erstes Badge',
        description: 'Erhalten Sie Ihr erstes Badge',
        pointsReward: 25,
        category: 'special',
        criteria: {'badges_count': 1},
      ),
      Achievement(
        id: 'badge_collector',
        title: 'Badge-Sammler',
        description: 'Erhalten Sie 10 Badges',
        pointsReward: 200,
        category: 'special',
        criteria: {'badges_count': 10},
      ),
      Achievement(
        id: 'badge_master',
        title: 'Badge-Meister',
        description: 'Erhalten Sie alle Badges',
        pointsReward: 1000,
        category: 'special',
        criteria: {'badges_count': 18}, // Gesamtzahl der verfügbaren Badges
      ),
    ];
  }
}

// Configuration des points pour différentes actions
class PointsConfig {
  static const Map<String, int> actionPoints = {
    'habit_completed': 10,
    'streak_day': 5,
    'challenge_completed': 50,
    'water_goal_reached': 15,
    'steps_goal_reached': 20,
    'sleep_goal_reached': 25,
    'mood_logged': 5,
    'perfect_day': 100, // Toutes les habitudes complétées
    'weekly_report_generated': 30,
    'monthly_report_generated': 100,
  };

  static const Map<String, int> streakBonus = {
    '3_days': 10,
    '7_days': 25,
    '14_days': 50,
    '30_days': 100,
    '60_days': 200,
    '100_days': 500,
  };

  static const Map<String, int> categoryMultipliers = {
    'water': 1,
    'steps': 1,
    'sleep': 1,
    'mood': 1,
    'habits': 2, // Les habitudes donnent plus de points
    'challenges': 3, // Les défis donnent encore plus de points
  };
}

// Configuration des niveaux
class LevelConfig {
  static List<Level> get levels => [
    Level(
      level: 1,
      title: 'Débutant',
      description: 'Bienvenue dans votre voyage vers une vie plus saine !',
      requiredPoints: 0,
      unlockedFeatures: ['basic_tracking', 'daily_habits'],
    ),
    Level(
      level: 2,
      title: 'Motivé',
      description: 'Vous commencez à prendre de bonnes habitudes !',
      requiredPoints: 100,
      unlockedFeatures: ['mood_tracking', 'water_tracking'],
    ),
    Level(
      level: 3,
      title: 'Engagé',
      description: 'Votre constance est remarquable !',
      requiredPoints: 250,
      unlockedFeatures: ['sleep_tracking', 'step_tracking'],
    ),
    Level(
      level: 4,
      title: 'Déterminé',
      description: 'Vous êtes sur la bonne voie !',
      requiredPoints: 500,
      unlockedFeatures: ['challenges', 'weekly_reports'],
    ),
    Level(
      level: 5,
      title: 'Consistant',
      description: 'Vos habitudes deviennent naturelles !',
      requiredPoints: 1000,
      unlockedFeatures: ['predictions', 'advanced_analytics'],
    ),
    Level(
      level: 6,
      title: 'Expert',
      description: 'Vous maîtrisez l\'art des bonnes habitudes !',
      requiredPoints: 2000,
      unlockedFeatures: ['custom_challenges', 'social_features'],
      specialReward: 'Badge Expert',
    ),
    Level(
      level: 7,
      title: 'Maître',
      description: 'Vous inspirez les autres par votre exemple !',
      requiredPoints: 3500,
      unlockedFeatures: ['mentor_mode', 'community_leader'],
      specialReward: 'Badge Maître',
    ),
    Level(
      level: 8,
      title: 'Légende',
      description: 'Vous êtes une légende de la santé et du bien-être !',
      requiredPoints: 5000,
      unlockedFeatures: ['all_features', 'exclusive_content'],
      specialReward: 'Badge Légende',
    ),
  ];
} 