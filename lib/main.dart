import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RockPaperScissorsApp());
}

class RockPaperScissorsApp extends StatefulWidget {
  const RockPaperScissorsApp({super.key});

  @override
  State<RockPaperScissorsApp> createState() => _RockPaperScissorsAppState();
}

class _RockPaperScissorsAppState extends State<RockPaperScissorsApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stone Paper Scissors',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode,
      // ✅ Use AuthWrapper as the home screen
      home: AuthWrapper(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleTheme,
      ),
      routes: {
        '/login': (context) => LoginScreen(
          onThemeToggle: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
        '/signup': (context) => SignUpScreen(
          onThemeToggle: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
        '/home': (context) => HomeScreen(
          isDarkMode: _themeMode == ThemeMode.dark,
          onThemeToggle: _toggleTheme,
        ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// ✅ AuthWrapper - This handles automatic navigation after login
class AuthWrapper extends StatelessWidget {
  final bool isDarkMode;
  final void Function(bool isDark) onThemeToggle;

  const AuthWrapper({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔍 Auth State: ${snapshot.connectionState}');
        print('🔍 User Data: ${snapshot.data}');

        // Show splash screen while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('📱 Showing Splash Screen');
          return SplashScreen(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          );
        }

        // ✅ If user is logged in, show home screen
        if (snapshot.hasData && snapshot.data != null) {
          print('🏠 User logged in - Showing Home Screen');
          print('👤 User: ${snapshot.data!.email ?? 'Anonymous'}');
          return HomeScreen(
            isDarkMode: isDarkMode,
            onThemeToggle: onThemeToggle,
          );
        }

        // ✅ If user is not logged in, show login screen
        print('🔐 No user - Showing Login Screen');
        return LoginScreen(
          isDarkMode: isDarkMode,
          onThemeToggle: onThemeToggle,
        );
      },
    );
  }
}
