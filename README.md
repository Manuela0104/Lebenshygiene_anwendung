# Lebenshygiene-Anwendung

## 📋 Description du projet
Application mobile de suivi de l'hygiène de vie développée dans le cadre d'un mémoire de fin d'études.

## 🏗️ Architecture technique

### Base de données
- **Base locale** : SQLite (sqflite) pour le stockage local et hors ligne
- **Base cloud** : Firebase Firestore pour la synchronisation et le partage des données
- **Authentification** : Firebase Auth pour la gestion des utilisateurs
- **Stockage** : Firebase Storage pour les fichiers et images

### Technologies utilisées
- **Framework** : Flutter 3.35.1
- **Langage** : Dart
- **État** : Provider pour la gestion d'état
- **Interface** : Material Design 3
- **Graphiques** : fl_chart pour les visualisations
- **Permissions** : permission_handler pour l'accès aux fonctionnalités

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK 3.35.1 ou supérieur
- Dart SDK 3.9.0 ou supérieur
- Compte Firebase

### Installation
1. Cloner le repository
2. Installer les dépendances : `flutter pub get`
3. Configurer Firebase (voir section Firebase)
4. Lancer l'application : `flutter run`

## 🔥 Configuration Firebase

### 1. Créer un projet Firebase
- Aller sur [console.firebase.google.com](https://console.firebase.google.com)
- Créer un nouveau projet
- Activer Authentication, Firestore et Storage

### 2. Configuration de l'application
- Ajouter une application web dans Firebase
- Copier la configuration dans `lib/firebase_options.dart`
- Activer les règles de sécurité Firestore

### 3. Règles Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 📱 Fonctionnalités principales

- **Authentification** : Inscription/Connexion utilisateur
- **Suivi des habitudes** : Tracker personnalisable
- **Analyses avancées** : Graphiques et statistiques
- **Personnalisation** : Thèmes et langues
- **Synchronisation** : Données locales + cloud
- **Notifications** : Rappels intelligents

## 🗂️ Structure du projet

```
lib/
├── models/          # Modèles de données
├── screens/         # Écrans de l'application
├── services/        # Services (Auth, Firebase)
├── utils/           # Utilitaires et providers
└── widgets/         # Composants réutilisables
```

## 🔧 Développement

### Commandes utiles
```bash
flutter clean          # Nettoyer le projet
flutter pub get        # Installer les dépendances
flutter run            # Lancer en mode debug
flutter build web      # Construire pour le web
flutter test           # Exécuter les tests
```

### Tests
```bash
flutter test           # Tests unitaires
flutter test --platform chrome  # Tests web
```

## 📊 Base de données

### Structure Firestore
```
users/
├── {userId}/
│   ├── profile: {firstName, email, createdAt}
│   ├── habits: [{name, frequency, streak}]
│   ├── goals: [{title, target, progress}]
│   └── analytics: {data, charts}
```

### Synchronisation
- Données stockées localement pour performance
- Synchronisation automatique avec Firebase
- Gestion des conflits et résolution

## 🎨 Interface utilisateur

- **Design System** : Material Design 3
- **Thèmes** : Mode clair/sombre
- **Responsive** : Adaptation tablette et mobile
- **Accessibilité** : Support des lecteurs d'écran

## 📈 Performance

- **Lazy Loading** : Chargement à la demande
- **Cache local** : Données fréquemment utilisées
- **Optimisation** : Tree-shaking et minification
- **PWA** : Support des fonctionnalités web avancées

## 🔒 Sécurité

- **Authentification** : Firebase Auth
- **Autorisations** : Règles Firestore
- **Validation** : Vérification des données
- **Chiffrement** : HTTPS et sécurité Firebase

## 📝 Documentation

- **Code** : Commentaires en allemand
- **API** : Documentation des services
- **Architecture** : Diagrammes et explications
- **Tests** : Couverture et exemples

## 🤝 Contribution

Ce projet est développé dans le cadre d'un mémoire de fin d'études.
Pour toute question ou suggestion, contacter l'auteur.

## 📄 Licence

Projet académique - Tous droits réservés

---

**Auteur** : [Votre nom]  
**Date** : [Date actuelle]  
**Version** : 1.0.0  
**Flutter** : 3.35.1  
**Dart** : 3.9.0
