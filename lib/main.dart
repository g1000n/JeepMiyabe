import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_page.dart';
import 'screens/welcome_page.dart';
import 'screens/signup_page.dart';
import 'screens/login_page.dart';
import 'screens/mfa_page.dart';
import 'map_screen.dart'; // Import your new MapScreen

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

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
      debugShowCheckedModeBanner: false,
      title: 'JeepMiyabe',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        fontFamily: 'Afacad',
      ),
      //home: const WelcomePage(), Welcome page initial route
      initialRoute: '/', //Initial route set to SplashPage
      routes: {
        '/': (context) => const SplashPage(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) =>  const SignUpPage(),
        '/dashboard': (context) => const PlaceholderPage(title: 'Dashboard'), //TODO: change with actual dashboard
        '/mfa': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String;
          return MFAPage(email: args);
        },
        '/map': (context) => const MapScreen(),
      },
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('This is the $title screen')),
    );
  }
}
