import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';
  
  Locale _locale = const Locale('de', 'DE');
  
  Locale get locale => _locale;
  
  // Available languages
  static const Map<String, Locale> availableLanguages = {
    'Deutsch': Locale('de', 'DE'),
    'English': Locale('en', 'US'),
    'Français': Locale('fr', 'FR'),
    'Español': Locale('es', 'ES'),
    'Italiano': Locale('it', 'IT'),
  };

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'de';
    final countryCode = prefs.getString('${_languageKey}_country') ?? 'DE';
    
    _locale = Locale(languageCode, countryCode);
    notifyListeners();
  }

  Future<void> setLanguage(String languageName) async {
    if (availableLanguages.containsKey(languageName)) {
      _locale = availableLanguages[languageName]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _locale.languageCode);
      await prefs.setString('${_languageKey}_country', _locale.countryCode ?? '');
      notifyListeners();
    }
  }

  String getCurrentLanguageName() {
    for (final entry in availableLanguages.entries) {
      if (entry.value.languageCode == _locale.languageCode) {
        return entry.key;
      }
    }
    return 'Deutsch';
  }
} 