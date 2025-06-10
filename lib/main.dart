import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/training_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/habit_tracker_screen.dart';
import 'utils/firestore_utils.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //await uploadQuestionsToFirestore();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the color palette
    const Color primaryColor = Color(0xFFEC407A); // Slightly richer pink/rose
    const Color secondaryColor = Color(0xFFAB47BC); // A complementary vibrant color (e.g., purple)
    const Color accentColor = Color(0xFFFFB74D); // A vibrant orange/peach accent
    const Color cardColor = Color(0xFFFFFFFF); // Pure white for cards
    const Color backgroundColor = Color(0xFFFCE4EC); // Very light pink background
    const Color textColorPrimary = Color(0xFF212121); // Dark grey for primary text
    const Color textColorSecondary = Color(0xFF757575); // Medium grey for secondary text

    // Define the text themes using Google Fonts
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.poppins(fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5, color: textColorPrimary),
      displayMedium: GoogleFonts.poppins(fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5, color: textColorPrimary),
      displaySmall: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w400, color: textColorPrimary),
      headlineMedium: GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: textColorPrimary),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w400, color: textColorPrimary),
      titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: textColorPrimary),
      titleMedium: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, color: textColorPrimary), // Default for ListTile titles, etc.
      titleSmall: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: textColorPrimary),
      bodyLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: textColorPrimary), // Default for body text
      bodyMedium: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: textColorPrimary), // Default text
      labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25, color: Colors.white), // Default for button text
      bodySmall: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: textColorSecondary), // Smaller text, hints, etc.
      labelSmall: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5, color: textColorSecondary), // Very small text
    );

    return MaterialApp(
      title: 'Lebenshygiene App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use colorScheme to define the primary colors
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor, // Base color for the theme
          primary: primaryColor,
          secondary: secondaryColor,
          surface: cardColor, // Use for cards and surfaces
          background: backgroundColor, // Use for scaffold background
          error: Colors.red, // Define an error color
          onPrimary: Colors.white, // Text/icons on primary color
          onSecondary: textColorPrimary, // Text/icons on secondary color
          onSurface: textColorPrimary, // Text/icons on surface color
          onBackground: textColorPrimary, // Text/icons on background color
          onError: Colors.white, // Text/icons on error color
          brightness: Brightness.light, // Light theme
        ),
        // Apply the custom text theme
        textTheme: textTheme,

        // Customize other theme properties
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor, // AppBar background color
          foregroundColor: Colors.white, // AppBar text and icon color
          centerTitle: true,
          titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white), // AppBar title text style
        ),
        cardTheme: CardTheme(
          color: cardColor, // Card background color
          elevation: 4.0, // Card elevation
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardColor, // Background color for input fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: textColorSecondary, width: 1.0), // Add a subtle border
          ),
          focusedBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: BorderSide(color: primaryColor, width: 2.0), // Highlight focused border
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding inside input fields
          hintStyle: textTheme.bodyMedium?.copyWith(color: textColorSecondary), // Hint text style
          labelStyle: textTheme.bodyMedium, // Label text style
          prefixIconColor: textColorSecondary, // Color for prefix icons
          suffixIconColor: textColorSecondary, // Color for suffix icons
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Button background color
            foregroundColor: Colors.white, // Button text color
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Rounded corners
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Button padding
            textStyle: textTheme.labelLarge, // Button text style
            elevation: 4.0, // Button elevation
          ),
        ),
        // You can add more theme customizations here (e.g., buttonTheme, iconTheme, etc.)

        useMaterial3: true,
      ),
      initialRoute: '/',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return const Home();
          }
          
          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const Home(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/fragebogen': (context) => const QuestionnaireScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/training': (context) => const TrainingScreen(),
        '/habits': (context) => const HabitTrackerScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
