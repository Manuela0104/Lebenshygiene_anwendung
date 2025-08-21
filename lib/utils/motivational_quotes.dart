import 'package:shared_preferences/shared_preferences.dart';

class MotivationalQuotes {
  static const Map<String, List<String>> _quotes = {
    'de': [
      "Jeder Tag ist ein neuer Anfang.",
      "Du bist stärker als du denkst.",
      "Kleine Schritte führen zu großen Veränderungen.",
      "Heute ist ein guter Tag für einen guten Tag.",
      "Atme tief und lass los.",
      "Du verdienst Glück und Frieden.",
      "Vertraue dem Prozess des Lebens.",
      "Deine Gesundheit ist dein größter Reichtum.",
      "Jede Herausforderung macht dich stärker.",
      "Du hast die Kraft, deine Träume zu verwirklichen.",
      "Geduld ist der Schlüssel zum Erfolg.",
      "Lass dich von deinen Zielen leiten.",
      "Du bist auf dem richtigen Weg.",
      "Vertraue deiner inneren Weisheit.",
      "Jeder Moment ist eine Chance für Wachstum.",
    ],
    'en': [
      "Every day is a new beginning.",
      "You are stronger than you think.",
      "Small steps lead to big changes.",
      "Today is a good day for a good day.",
      "Breathe deeply and let go.",
      "You deserve happiness and peace.",
      "Trust the process of life.",
      "Your health is your greatest wealth.",
      "Every challenge makes you stronger.",
      "You have the power to achieve your dreams.",
      "Patience is the key to success.",
      "Let your goals guide you.",
      "You are on the right path.",
      "Trust your inner wisdom.",
      "Every moment is an opportunity for growth.",
    ],
    'fr': [
      "Chaque jour est un nouveau commencement.",
      "Tu es plus fort que tu ne le penses.",
      "Les petits pas mènent aux grands changements.",
      "Aujourd'hui est un bon jour pour une bonne journée.",
      "Respire profondément et lâche prise.",
      "Tu mérites le bonheur et la paix.",
      "Fais confiance au processus de la vie.",
      "Ta santé est ta plus grande richesse.",
      "Chaque défi te rend plus fort.",
      "Tu as le pouvoir de réaliser tes rêves.",
      "La patience est la clé du succès.",
      "Laisse tes objectifs te guider.",
      "Tu es sur le bon chemin.",
      "Fais confiance à ta sagesse intérieure.",
      "Chaque instant est une opportunité de croissance.",
    ],
    'es': [
      "Cada día es un nuevo comienzo.",
      "Eres más fuerte de lo que piensas.",
      "Los pequeños pasos llevan a grandes cambios.",
      "Hoy es un buen día para un buen día.",
      "Respira profundamente y suelta.",
      "Mereces felicidad y paz.",
      "Confía en el proceso de la vida.",
      "Tu salud es tu mayor riqueza.",
      "Cada desafío te hace más fuerte.",
      "Tienes el poder de lograr tus sueños.",
      "La paciencia es la clave del éxito.",
      "Deja que tus objetivos te guíen.",
      "Estás en el camino correcto.",
      "Confía en tu sabiduría interior.",
      "Cada momento es una oportunidad para crecer.",
    ],
    'it': [
      "Ogni giorno è un nuovo inizio.",
      "Sei più forte di quanto pensi.",
      "I piccoli passi portano a grandi cambiamenti.",
      "Oggi è un buon giorno per una buona giornata.",
      "Respira profondamente e lascia andare.",
      "Meriti felicità e pace.",
      "Fidati del processo della vita.",
      "La tua salute è la tua più grande ricchezza.",
      "Ogni sfida ti rende più forte.",
      "Hai il potere di realizzare i tuoi sogni.",
      "La pazienza è la chiave del successo.",
      "Lascia che i tuoi obiettivi ti guidino.",
      "Sei sulla strada giusta.",
      "Fidati della tua saggezza interiore.",
      "Ogni momento è un'opportunità di crescita.",
    ],
  };

  static String getQuoteOfTheDay(String languageCode) {
    final quotes = _quotes[languageCode] ?? _quotes['de']!;
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }

  static String getRandomQuote(String languageCode) {
    final quotes = _quotes[languageCode] ?? _quotes['de']!;
    final random = DateTime.now().millisecondsSinceEpoch;
    return quotes[random % quotes.length];
  }

  static List<String> getAllQuotes(String languageCode) {
    return _quotes[languageCode] ?? _quotes['de']!;
  }

  static Future<String> getSavedQuote() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_quote') ?? getQuoteOfTheDay('de');
  }

  static Future<void> saveQuote(String quote) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_quote', quote);
  }

  static Future<bool> isQuotesEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('quotes_enabled') ?? true;
  }

  static Future<void> setQuotesEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quotes_enabled', enabled);
  }
} 