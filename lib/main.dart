import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/game_screen.dart';
import 'screens/results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(
    // Wrap the app in ProviderScope
    const ProviderScope(
      child: PatternMindApp(),
    ),
  );
}

class PatternMindApp extends StatelessWidget {
  const PatternMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color neonCyan = Color(0xFF00E5FF);
    const Color neonPurple = Color(0xFFBD00FF);
    const Color deepBlack = Color(0xFF050505);
    const Color cardDark = Color(0xFF1A1A1F);

    return MaterialApp(
      title: 'PatternMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: deepBlack,
        primaryColor: neonCyan,
        colorScheme: ColorScheme.dark(
          primary: neonCyan,
          secondary: neonPurple,
          surface: cardDark,
          background: deepBlack,
        ),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.orbitron(
            color: neonCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
          displayMedium: GoogleFonts.orbitron(
            color: neonCyan,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: GoogleFonts.orbitron(
            color: neonCyan,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardDark.withOpacity(0.85),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: neonCyan, width: 1.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: neonCyan, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: neonCyan,
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 54),
            textStyle: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 8,
            shadowColor: neonCyan.withOpacity(0.5),
          ),
        ),
      ),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/splash':
            page = const SplashScreen();
            break;
          case '/login':
            page = const AuthScreen();
            break;
          case '/home':
            page = const HomeScreen();
            break;
          case '/game':
            page = const GameScreen();
            break;
          case '/results':
            page = const ResultsScreen();
            break;
          default:
            page = const SplashScreen();
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          settings: settings,
        );
      },
    );
  }
}
