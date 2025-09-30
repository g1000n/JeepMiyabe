import 'package:flutter/material.dart';
import 'map_screen.dart'; // Import your new MapScreen

void main() {
  // Flutter must initialize the widget binding before loading assets
  WidgetsFlutterBinding.ensureInitialized();

  // You would typically load .env files here if you had an API key for Google Maps Platform,
  // but for now, we assume the API key is set in AndroidManifest.xml and Info.plist.

  runApp(const JeepneyApp());
}

class JeepneyApp extends StatelessWidget {
  const JeepneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JeepMiyabe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Start the application with your MapScreen
      home: const MapScreen(),
    );
  }
}
