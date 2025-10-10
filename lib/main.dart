import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/mfa_page.dart';
import 'screens/verify_page.dart';
import 'screens/dashboard_page.dart';  // Add this import (adjust path if needed)
import 'map_screen.dart'; // Import your new MapScreen


Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pstnvvhduwzlpphttcvm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzdG52dmhkdXd6bHBwaHR0Y3ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4NjIwMzEsImV4cCI6MjA3NDQzODAzMX0.qsRhQuEyf0tn1PgBvg9AQX_g9l9F0cnn96SofgwU7II',
  );

  runApp(const JeepMiyabeApp());
}

//Stateful Widget to handle auth state changes for automatic redirection after sign up verifcation
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
      title: 'JeepMiyabe',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Afacad',
      ),
      initialRoute: '/', //Initial route set to SplashPage
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) =>  const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/mfa': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          if (args == null) {
            // Fallback if no email argument
            Navigator.pop(context);
            return const SizedBox.shrink();
          }
          return MFAPage(email: args);
        },
        '/verify': (context) => const VerifyPage(), //verufy page for sign up
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
