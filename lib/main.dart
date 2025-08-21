import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/habit_tracker_screen.dart';
import 'screens/advanced_analytics_screen.dart';
import 'screens/personalization_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'utils/theme_provider.dart';
import 'utils/language_provider.dart';

/// Hauptfunktion der Lebenshygiene-Anwendung
/// 
/// Initialisiert Firebase, lokale Datumsformatierung
/// und startet die Hauptanwendung.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting('de_DE', null);
  runApp(MyApp());
}

/// Hauptanwendungs-Widget mit Provider-Integration
/// 
/// Konfiguriert alle Provider (Auth, Theme, Language),
/// definiert unterstützte Sprachen und lokale Routen.
/// Bietet eine vollständig konfigurierte MaterialApp
/// mit mehrsprachiger Unterstützung und Theme-Management.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'Lebenshygiene-Anwendung',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('de', 'DE'),
              Locale('en', 'US'),
              Locale('fr', 'FR'),
              Locale('es', 'ES'),
              Locale('it', 'IT'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: themeProvider.themeMode,
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            initialRoute: '/',
            home: AuthWrapper(),
            routes: {
              '/home': (context) => const Home(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/profile': (context) => const ProfileScreen(),

              '/habits': (context) => const HabitTrackerScreen(),
              '/analytics': (context) => const AdvancedAnalyticsScreen(),
              '/personalization': (context) => const PersonalizationScreen(),
            },
          );
        },
      ),
    );
  }
}

/// Authentifizierungs-Wrapper für die Anwendung
/// 
/// Überwacht den Authentifizierungsstatus des Benutzers
/// und leitet entsprechend weiter:
/// - Zeigt Ladebildschirm während der Authentifizierung
/// - Leitet angemeldete Benutzer zum Home-Bildschirm weiter
/// - Leitet nicht angemeldete Benutzer zum Auth-Bildschirm weiter
/// 
/// Stellt sicher, dass Benutzer nur auf autorisierte
/// Bereiche der Anwendung zugreifen können.
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/health.jpg',
                    width: 120,
                    height: 120,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Laden...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const Home();
        }

        return const AuthScreen();
      },
    );
  }
}
