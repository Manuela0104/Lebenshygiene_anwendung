import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  static const String _fontSizeKey = 'font_size';
  
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = Colors.teal;
  double _fontSize = 1.0; // Multiplier for font size
  
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  double get fontSize => _fontSize;
  
  // Available color themes
  static const Map<String, Color> availableColors = {
    'Teal': Colors.teal,
    'Blue': Colors.blue,
    'Green': Colors.green,
    'Purple': Colors.purple,
    'Orange': Colors.orange,
    'Pink': Colors.pink,
    'Indigo': Colors.indigo,
    'Red': Colors.red,
  };

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    final colorName = prefs.getString(_primaryColorKey) ?? 'Teal';
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 1.0;
    
    _themeMode = ThemeMode.values[themeIndex];
    _primaryColor = availableColors[colorName] ?? Colors.teal;
    _fontSize = fontSize;
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setPrimaryColor(String colorName) async {
    if (availableColors.containsKey(colorName)) {
      _primaryColor = availableColors[colorName]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryColorKey, colorName);
      notifyListeners();
    }
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(0.8, 1.4); // Limit font size between 80% and 140%
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, _fontSize);
    notifyListeners();
  }

  ThemeData getLightTheme() {
    return ThemeData(
      primarySwatch: _getPrimarySwatch(),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      textTheme: _getTextTheme(),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  ThemeData getDarkTheme() {
    return ThemeData(
      primarySwatch: _getPrimarySwatch(),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1a202c),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      textTheme: _getTextTheme(),
      cardTheme: CardThemeData(
        color: const Color(0xFF2d3748),
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  MaterialColor _getPrimarySwatch() {
    // Convert Color to MaterialColor
    return MaterialColor(_primaryColor.value, {
      50: _primaryColor.withOpacity(0.1),
      100: _primaryColor.withOpacity(0.2),
      200: _primaryColor.withOpacity(0.3),
      300: _primaryColor.withOpacity(0.4),
      400: _primaryColor.withOpacity(0.5),
      500: _primaryColor,
      600: _primaryColor.withOpacity(0.7),
      700: _primaryColor.withOpacity(0.8),
      800: _primaryColor.withOpacity(0.9),
      900: _primaryColor,
    });
  }

  TextTheme _getTextTheme() {
    final baseSize = _fontSize;
    return TextTheme(
      displayLarge: TextStyle(fontSize: 96 * baseSize, fontWeight: FontWeight.w300, letterSpacing: -1.5, color: _primaryColor),
      displayMedium: TextStyle(fontSize: 60 * baseSize, fontWeight: FontWeight.w300, letterSpacing: -0.5, color: _primaryColor),
      displaySmall: TextStyle(fontSize: 48 * baseSize, fontWeight: FontWeight.w400, color: _primaryColor),
      headlineMedium: TextStyle(fontSize: 34 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: _primaryColor),
      headlineSmall: TextStyle(fontSize: 24 * baseSize, fontWeight: FontWeight.w400, color: _primaryColor),
      titleLarge: TextStyle(fontSize: 20 * baseSize, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: _primaryColor),
      titleMedium: TextStyle(fontSize: 16 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 0.15, color: _primaryColor),
      titleSmall: TextStyle(fontSize: 14 * baseSize, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: _primaryColor),
      bodyLarge: TextStyle(fontSize: 16 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: _primaryColor),
      bodyMedium: TextStyle(fontSize: 14 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: _primaryColor),
      labelLarge: TextStyle(fontSize: 14 * baseSize, fontWeight: FontWeight.w500, letterSpacing: 1.25, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: _primaryColor),
      labelSmall: TextStyle(fontSize: 10 * baseSize, fontWeight: FontWeight.w400, letterSpacing: 1.5, color: _primaryColor),
    );
  }
} 