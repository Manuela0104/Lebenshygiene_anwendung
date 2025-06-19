# Diagramme d'Architecture - Lebenshygiene-Anwendung

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PRÉSENTATION LAYER                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │
│  │   main.dart     │    │  MaterialApp    │    │  StreamBuilder   │        │
│  │                 │    │                 │    │                 │        │
│  │ • Firebase Init │    │ • Theme Config  │    │ • Auth State    │        │
│  │ • Route Config  │    │ • Navigation    │    │ • Auto Redirect │        │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘        │
│           │                       │                       │                │
│           └───────────────────────┼───────────────────────┘                │
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        SCREENS (lib/screens/)                      │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │   Home      │ │   Login     │ │  Register   │ │  Profile    │   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • Dashboard │ │ • Auth      │ │ • Sign Up   │ │ • User Info │   │   │
│  │ │ • Overview  │ │ • Validation│ │ • Form      │ │ • Settings  │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │Habit Tracker│ │Mood Tracker │ │Smart Remind │ │Water Counter│   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • Habits    │ │ • Mood Log  │ │ • Notif     │ │ • Hydration │   │   │
│  │ │ • Progress  │ │ • Analytics │ │ • Schedule  │ │ • Tracking  │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │Sleep Counter│ │Calorie Count│ │Mini Challenge│ │Trends Report│   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • Sleep Log │ │ • Nutrition │ │ • Challenges│ │ • Analytics │   │   │
│  │ │ • Quality   │ │ • Calories  │ │ • Goals     │ │ • Charts    │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                        │
└───────────────────────────────────┼────────────────────────────────────────┘
                                    │
┌───────────────────────────────────┼────────────────────────────────────────┐
│                           BUSINESS LOGIC LAYER                            │
├───────────────────────────────────┼────────────────────────────────────────┤
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        SERVICES (lib/services/)                    │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │ AuthService │ │HabitService │ │MoodService  │ │ReminderServ │   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • Login     │ │ • CRUD      │ │ • Mood Log  │ │ • Schedule  │   │   │
│  │ │ • Register  │ │ • Progress  │ │ • Analytics │ │ • Notif     │   │   │
│  │ │ • Logout    │ │ • Stats     │ │ • Trends    │ │ • Triggers  │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        UTILS (lib/utils/)                          │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │FirestoreUtil│ │DateUtil     │ │ValidationUtil│ │NotificationUtil│   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • DB Ops    │ │ • Format    │ │ • Input     │ │ • Local     │   │   │
│  │ │ • Queries   │ │ • Parse     │ │ • Validate  │ │ • Push      │   │   │
│  │ │ • Batch     │ │ • Calculate │ │ • Sanitize  │ │ • Schedule  │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        MODELS (lib/models/)                        │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │   AppUser   │ │   Habit     │ │   Mood      │ │  Reminder   │   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • uid       │ │ • id        │ │ • level     │ │ • id        │   │   │
│  │ │ • email     │ │ • name      │ │ • comment   │ │ • title     │   │   │
│  │ │ • name      │ │ • category  │ │ • timestamp │ │ • time      │   │   │
│  │ │ • createdAt │ │ • createdAt │ │ • userId    │ │ • repeat    │   │   │
│  │ │ • createdAt │ │ • createdAt │ │ • userId    │ │ • repeat    │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        FIREBASE INTEGRATION                         │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │Firebase Auth│ │Firestore DB │ │Firebase     │ │Firebase     │   │   │
│  │ │             │ │             │ │Storage      │ │Functions    │   │   │
│  │ │ • Login     │ │ • Users     │ │ • Images    │ │ • Backend   │   │   │
│  │ │ • Register  │ │ • Habits    │ │ • Files     │ │ • Triggers  │   │   │
│  │ │ • Logout    │ │ • Mood      │ │ • Assets    │ │ • Webhooks  │   │   │
│  │ │ • State     │ │ • Progress  │ │ • Backups   │ │ • Cron Jobs │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        LOCAL STORAGE                                 │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │                                                                     │   │
│  │ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │   │
│  │ │Shared Prefs │ │Local DB     │ │Cache        │ │Temp Files   │   │   │
│  │ │             │ │             │ │             │ │             │   │   │
│  │ │ • Settings  │ │ • Offline   │ │ • Images    │ │ • Downloads │   │   │
│  │ │ • Theme     │ │ • Sync      │ │ • Data      │ │ • Exports   │   │   │
│  │ │ • Language  │ │ • Backup    │ │ • Queries   │ │ • Reports   │   │   │
│  │ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL INTEGRATIONS                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │ Pedometer   │ │ Notifications│ │ Google Fonts│ │ Fl Charts   │          │
│  │             │ │             │ │             │ │             │          │
│  │ • Steps     │ │ • Local     │ │ • Typography│ │ • Analytics │          │
│  │ • Activity  │ │ • Push      │ │ • Icons     │ │ • Progress  │          │
│  │ • Health    │ │ • Schedule  │ │ • Styling   │ │ • Trends    │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
│                                                                             │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
│  │ Image Picker│ │ Permission  │ │ Timezone    │ │ Intl        │          │
│  │             │ │ Handler     │ │             │ │             │          │
│  │ • Camera    │ │ • Camera    │ │ • Local     │ │ • Date      │          │
│  │ • Gallery   │ │ • Storage   │ │ • UTC       │ │ • Number    │          │
│  │ • Upload    │ │ • Location  │ │ • Format    │ │ • Currency  │          │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                           DATA FLOW                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  User Action → Screen → Service → Model → Firebase → Response              │
│       ↑                                                           ↓        │
│  UI Update ← Widget ← State ← Stream ← Firestore ← Data Change             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    AUTHENTICATION FLOW                              │   │
│  │                                                                     │   │
│  │  Login/Register → Firebase Auth → User State → Route Redirect      │   │
│  │       ↑                                    ↓                        │   │
│  │  UI Update ← StreamBuilder ← Auth State Changes                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    DATA SYNCHRONIZATION                             │   │
│  │                                                                     │   │
│  │  Local Action → Firestore Update → Real-time Sync → UI Refresh     │   │
│  │       ↑                                    ↓                        │   │
│  │  Offline Cache ← Batch Operations ← Conflict Resolution            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Légende du Diagramme

### Couches Principales :
- **PRÉSENTATION LAYER** : Interface utilisateur et navigation
- **BUSINESS LOGIC LAYER** : Services et logique métier
- **DATA LAYER** : Modèles de données et persistance
- **EXTERNAL INTEGRATIONS** : Services tiers et plugins

### Composants Clés :
- **Screens** : Écrans de l'application (16 écrans principaux)
- **Services** : Logique métier et interactions avec Firebase
- **Models** : Structure des données utilisateur
- **Utils** : Fonctions utilitaires et helpers
- **Firebase** : Backend-as-a-Service (Auth, Firestore, Storage)

### Flux de Données :
- **Authentication Flow** : Gestion de l'authentification en temps réel
- **Data Synchronization** : Synchronisation bidirectionnelle avec Firebase
- **Real-time Updates** : Mise à jour automatique de l'interface

Cette architecture modulaire permet une séparation claire des responsabilités, facilite la maintenance et l'évolution de l'application tout en garantissant une expérience utilisateur fluide et réactive. 