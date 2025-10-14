import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import all screens used in the route map
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/verify_page.dart';
import 'screens/mfa_page.dart';
import 'screens/map_screen.dart'; // Your MapScreen
import 'screens/dashboard_page.dart'; // Team's Dashboard Page


// Initialize Supabase before running the app
Future<void> main() async {
  // Required to run Supabase and other plugin setup before runApp
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pstnvvhduwzlpphttcvm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzdG52dmhkdXd6bHBwaHR0Y3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NjIwMzEsImV4cCI6MjA3NDQzODAzMX0.qsRhQuEyf0tn1PgBvg9AQX_g9l9F0cnn96SofgwU7II',
  );

  // Using the new app class name
  runApp(const JeepMiyabeApp());
}

// Using the new app class name from the 'main' branch
//Stateful Widget to handle auth state changes for automatic redirection after sign up verification
class JeepMiyabeApp extends StatefulWidget {
  const JeepMiyabeApp({super.key});

  @override
  State<JeepMiyabeApp> createState() => _JeepMiyabeAppState();
}

class _JeepMiyabeAppState extends State<JeepMiyabeApp> {
  late final supabase = Supabase.instance.client;

  @override
  void initState(){
    super.initState();

    supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final event = data.event;
      if (event == AuthChangeEvent.signedIn && session != null && mounted) {
        //If user just verified via email, go to dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JeepMiyabe Route Finder',
      theme: ThemeData(
        // Keeping the existing theme setup
        primarySwatch: Colors.indigo,
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      
      // Initial route set to SplashPage, which handles session status
      initialRoute: '/', 
      
      // All app routes, including the /map screen
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        
        // Use the official DashboardPage from the team's code
        '/dashboard': (context) => const DashboardPage(), 
        
        // Your map screen is now accessible via the /map route
        '/map': (context) => const MapScreen(), 
        
        // MFA page for multi-factor authentication setup
        '/mfa': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          if (args == null) {
            // Fallback if no email argument
            Navigator.pop(context);
            return const SizedBox.shrink();
          }
          return MFAPage(email: args);
        },

        //Verification page after signup
        '/verify': (context) => const VerifyPage(),
      },
    );
  }
}