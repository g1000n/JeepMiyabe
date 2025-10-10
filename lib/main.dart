import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import all screens used in the route map
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/mfa_page.dart';
import 'screens/map_screen.dart'; // Your MapScreen

// Initialize Supabase before running the app
Future<void> main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pstnvvhduwzlpphttcvm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzdG52dmhkdXd6bHBwaHR0Y3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NjIwMzEsImV4cCI6MjA3NDQzODAzMX0.qsRhQuEyf0tn1PgBvg9AQX_g9l9F0cnn96SofgwU7II',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepMiyabe Route Finder',
      theme: ThemeData(
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
        // The dashboard is usually the first screen after successful login/auth check
        '/dashboard': (context) => const PlaceholderPage(title: 'Dashboard'), 
        
        // Your map screen is now accessible via the /map route
        '/map': (context) => const MapScreen(), 
        
        // MFA page for multi-factor authentication setup
        '/mfa': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return MFAPage(email: args);
        },
      },
    );
  }
}

/// A simple page used as a placeholder for screens that haven't been built yet.
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('This is the $title screen', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Example of navigating to your map screen after a successful "login" or "dashboard" view
                Navigator.of(context).pushNamedAndRemoveUntil('/map', (route) => false);
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Go to Map Screen'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Supabase.instance.client.auth.signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
