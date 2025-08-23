# 🏥 Lebenshygiene-Anwendung

## 📋 Projektbeschreibung

Eine mobile Anwendung zur Überwachung und Verbesserung der Lebenshygiene, entwickelt im Rahmen einer Masterarbeit. Die App kombiniert moderne Technologien mit benutzerfreundlicher Gestaltung, um Nutzern dabei zu helfen, gesunde Gewohnheiten zu entwickeln und zu verfolgen.

## 🏗️ Technische Architektur

### **Frontend Framework**
- **Flutter 3.29.3** - Cross-platform UI Framework
- **Dart 3.0+** - Programmiersprache
- **Material Design 3** - Design System

### **Backend & Cloud Services**
- **Firebase Authentication** - Benutzerverwaltung
- **Cloud Firestore** - NoSQL Datenbank
- **Firebase Storage** - Dateispeicherung
- **Firebase Hosting** - Web-Deployment

### **State Management & Daten**
- **Provider Pattern** - State Management
- **SharedPreferences** - Lokale Datenspeicherung
- **Offline-First** - Funktion ohne Internetverbindung

## 🚀 Installation & Konfiguration

### **Voraussetzungen**
- Flutter SDK 3.29.3 oder höher
- Dart SDK 3.0+ oder höher
- Android Studio / VS Code
- Git
- Firebase-Konto

### **Schritt-für-Schritt Installation**

```bash
# 1. Repository klonen
git clone https://github.com/ihr-username/lebenshygiene_anwendung.git
cd lebenshygiene_anwendung

# 2. Dependencies installieren
flutter pub get

# 3. Firebase konfigurieren (siehe Firebase-Sektion)
# 4. Anwendung starten
flutter run
```

## 🔥 Firebase-Konfiguration

### **1. Firebase-Projekt erstellen**
1. Gehen Sie zu [console.firebase.google.com](https://console.firebase.google.com)
2. Klicken Sie auf "Projekt hinzufügen"
3. Wählen Sie "lebenshygiene-anwendung" als Projektname
4. Aktivieren Sie Google Analytics (optional)

### **2. Firebase-Dienste aktivieren**
```bash
# Authentication aktivieren
- Gehen Sie zu Authentication > Sign-in method
- Aktivieren Sie "E-Mail/Passwort"

# Firestore aktivieren
- Gehen Sie zu Firestore Database
- Wählen Sie "Testmodus starten"

# Storage aktivieren
- Gehen Sie zu Storage
- Wählen Sie "Testmodus starten"
```

### **3. Anwendung konfigurieren**
```bash
# FlutterFire CLI installieren
dart pub global activate flutterfire_cli

# Firebase-Konfiguration generieren
flutterfire configure --project=lebenshygiene-anwendung
```

### **4. Sicherheitsregeln konfigurieren**

**Firestore Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /users/{userId} {
      allow read, write: if isOwner(userId);
      
      match /habits/{habitId} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

## 🚀 Deployment-Anleitung

### **A. Web-Deployment (Firebase Hosting)**

#### **1. Web-Build erstellen**
```bash
# Web-Build generieren
flutter build web --release

# Build-Verzeichnis überprüfen
ls build/web/
```

#### **2. Firebase Hosting konfigurieren**
```bash
# Firebase CLI installieren (falls noch nicht geschehen)
npm install -g firebase-tools

# Bei Firebase anmelden
firebase login

# Projekt initialisieren
firebase init hosting

# Folgende Optionen wählen:
# - Use an existing project: lebenshygiene-anwendung
# - Public directory: build/web
# - Configure as single-page app: Yes
# - Overwrite index.html: No
```

#### **3. Deployment durchführen**
```bash
# Anwendung deployen
firebase deploy --only hosting

# URL wird angezeigt (z.B.: https://lebenshygiene-anwendung.web.app)
```

### **B. Android-Deployment (Google Play Store)**

#### **1. Release-Build erstellen**
```bash
# Release-APK erstellen
flutter build apk --release

# Oder App Bundle (empfohlen für Play Store)
flutter build appbundle --release
```

#### **2. Signing konfigurieren**
```bash
# Keystore generieren
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Passwort notieren und in android/key.properties eintragen
```

**`android/key.properties`**:
```properties
storePassword=<Ihr-Passwort>
keyPassword=<Ihr-Passwort>
keyAlias=upload
storeFile=<Pfad-zur-keystore>/upload-keystore.jks
```

#### **3. Play Store vorbereiten**
1. [Google Play Console](https://play.google.com/console) öffnen
2. Neue App erstellen
3. APK/AAB hochladen
4. Store-Listing konfigurieren
5. Veröffentlichung beantragen

### **C. iOS-Deployment (App Store)**

#### **1. iOS-Build erstellen**
```bash
# iOS-Build (nur auf macOS möglich)
flutter build ios --release
```

#### **2. Xcode konfigurieren**
1. `ios/Runner.xcworkspace` in Xcode öffnen
2. Bundle Identifier anpassen
3. Signing & Capabilities konfigurieren
4. Archive erstellen

#### **3. App Store Connect**
1. [App Store Connect](https://appstoreconnect.apple.com) öffnen
2. Neue App erstellen
3. Build hochladen
4. App-Review beantragen

### **D. Desktop-Deployment**

#### **Windows**
```bash
# Windows-Build erstellen
flutter build windows --release

# Executable befindet sich in: build/windows/runner/Release/
```

#### **macOS**
```bash
# macOS-Build erstellen
flutter build macos --release

# App befindet sich in: build/macos/Build/Products/Release/
```

#### **Linux**
```bash
# Linux-Build erstellen
flutter build linux --release

# Executable befindet sich in: build/linux/x64/release/bundle/
```

## 📱 Hauptfunktionen

### **🔐 Authentifizierung**
- Benutzerregistrierung mit E-Mail/Passwort
- Sicheres Login-System
- Passwort-Reset-Funktionalität

### **📊 Gewohnheiten-Tracking**
- Personalisierte Gewohnheiten erstellen
- Streak-Zähler und Statistiken
- Fortschrittsvisualisierung

### **📈 Erweiterte Analysen**
- Interaktive Charts und Grafiken
- Trend-Analysen
- Export-Funktionalität

### **🎨 Personalisierung**
- Light/Dark Theme
- Mehrsprachige Unterstützung
- Anpassbare Benachrichtigungen

## 🗂️ Projektstruktur

```
lib/
├── models/           # Datenmodelle
│   ├── user_model.dart
│   ├── habit_model.dart
│   └── report_model.dart
├── screens/          # App-Bildschirme
│   ├── auth_screen.dart
│   ├── home.dart
│   ├── habit_tracker_screen.dart
│   └── analytics_screen.dart
├── services/         # Business Logic
│   ├── auth_service.dart
│   ├── firebase_service.dart
│   └── storage_service.dart
├── utils/            # Hilfsfunktionen
│   ├── theme_provider.dart
│   └── constants.dart
└── widgets/          # Wiederverwendbare Komponenten
```

## 🔧 Entwicklung

### **Nützliche Befehle**
```bash
# Projekt bereinigen
flutter clean

# Dependencies aktualisieren
flutter pub upgrade

# Code formatieren
dart format .

# Linting durchführen
flutter analyze

# Tests ausführen
flutter test

# Hot Reload (während der Entwicklung)
flutter run
```

### **Firebase Emulator (Lokale Entwicklung)**
```bash
# Emulatoren starten
firebase emulators:start

# Emulator-UI öffnen
firebase emulators:start --ui
```

## 📊 Datenbank-Schema

### **Firestore Collections**
```yaml
users/
├── {userId}/
│   ├── profile: {firstName, email, createdAt, profileImageUrl}
│   ├── habits: [{name, frequency, streak, createdAt}]
│   ├── dailyData: [{date, mood, water, sleep, steps}]
│   ├── goals: [{title, target, progress, deadline}]
│   └── analytics: {charts, statistics, trends}
```

## 🎨 UI/UX-Features

- **Material Design 3** - Moderne Design-Sprache
- **Responsive Design** - Optimiert für alle Bildschirmgrößen
- **Accessibility** - Barrierefreie Nutzung
- **Animations** - Flüssige Übergänge und Feedback

## 🔒 Sicherheit

- **Firebase Security Rules** - Datenzugriffskontrolle
- **HTTPS/TLS** - Verschlüsselte Kommunikation
- **Input Validation** - Datenvalidierung
- **Authentication** - Sichere Benutzerverwaltung

## 📈 Performance-Optimierung

- **Lazy Loading** - On-demand Datenladung
- **Caching** - Lokale Datenspeicherung
- **Image Optimization** - Komprimierte Bilder
- **Offline Support** - Funktion ohne Internet

## 🧪 Testing

### **Test-Typen**
```bash
# Unit Tests
flutter test

# Widget Tests
flutter test test/widget_test.dart

# Integration Tests
flutter drive --target=test_driver/app.dart
```

### **Test-Coverage**
```bash
# Coverage-Report generieren
flutter test --coverage

# HTML-Report öffnen
genhtml coverage/lcov.info -o coverage/html
```

## 📚 Dokumentation

- **Code-Kommentare** - Ausführliche Dokumentation
- **API-Dokumentation** - Service-Interfaces
- **Architektur-Diagramme** - System-Übersicht
- **Deployment-Guide** - Schritt-für-Schritt Anleitung

## 🤝 Beitragen

Dieses Projekt wurde im Rahmen einer Masterarbeit entwickelt. Für Fragen oder Anregungen kontaktieren Sie bitte den Autor.

## 📄 Lizenz

Akademisches Projekt - Alle Rechte vorbehalten

---

## 📊 Technologie-Stack Übersicht

| Kategorie | Technologie | Version | Zweck |
|-----------|-------------|---------|-------|
| **Frontend** | Flutter | 3.29.3 | Cross-platform UI |
| **Sprache** | Dart | 3.0+ | Programmiersprache |
| **Backend** | Firebase | Latest | Cloud Services |
| **Datenbank** | Firestore | Latest | NoSQL Database |
| **Auth** | Firebase Auth | Latest | Benutzerverwaltung |
| **Storage** | Firebase Storage | Latest | Dateispeicherung |
| **State** | Provider | 6.1.1 | State Management |
| **UI** | Material Design 3 | Latest | Design System |
| **Testing** | Flutter Test | Latest | Testing Framework |
| **Deployment** | Firebase Hosting | Latest | Web Deployment |

---

**👨‍🎓 Autor**: [Ihr Name]  
**📅 Datum**: Dezember 2024  
**🎯 Version**: 1.0.0  
**🏫 Institution**: [Ihre Universität]  
**📚 Projekt**: Masterarbeit - Lebenshygiene-Anwendung  

---

*Diese Dokumentation wird regelmäßig aktualisiert, um neue Funktionen und Änderungen zu reflektieren.*
