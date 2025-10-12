import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; // <--- NEW IMPORT

// Local Files
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/mfa_page.dart';
import 'screens/map_screen.dart'; 
import 'screens/dashboard_page.dart'; 
import 'route_controller.dart'; // <--- NEW IMPORT

// Initialize Supabase before running the app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: 'https://pstnvvhduwzlpphttcvm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzdG52dmhkdXd6bHBwaHR0Y3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NjIwMzEsImV4cCI6MjA3NDQzODAzMX0.qsRhQuEyf0tn1PgBvg9AQX_g9l9F0cnn96SofgwU7II',
  );

  runApp(const JeepMiyabeApp());
}

class JeepMiyabeApp extends StatelessWidget {
  const JeepMiyabeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepMiyabe Route Finder',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      
      initialRoute: '/', 
      
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        
        // 🎯 FIX: Wrap the DashboardPage route with the ChangeNotifierProvider
        '/dashboard': (context) => ChangeNotifierProvider(
          create: (context) {
            final controller = RouteController();
            // Start loading the graph immediately when entering the Dashboard
            controller.initialize(); 
            return controller;
          },
          child: const DashboardPage(),
        ), 
        
        // The MapScreen route is no longer strictly needed if MapScreen is embedded in Dashboard
        // but it's kept here for potential direct access (if MapScreen still exists as a standalone route).
        '/map': (context) => const MapScreen(), 
        
        '/mfa': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          if (args == null) {
            Navigator.pop(context);
            return const SizedBox.shrink();
          }
          return MFAPage(email: args);
        },
      },
    );
  }
}