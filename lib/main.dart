import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'routes.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JeepMiyabe',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  late GoogleMapController mapController;

  final LatLng _center = const LatLng(15.1449, 120.5887); // Angeles City

  int _selectedIndex = 0;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Map as background
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 14.0,
            ),
            polylines: Set<Polyline>.of(jeepneyRoutes), // <-- add this
            myLocationButtonEnabled: false,
          ),

          // Floating search bar
          Positioned(
            top: 50,
            left: 20,
            right: 70,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              color: Colors.white.withOpacity(0.9),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search routes...",
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          // Floating settings icon
          Positioned(
            top: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Settings action
              },
              mini: true,
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.settings),
            ),
          ),
        ],
      ),
      // Bottom navigation
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => _onNavTapped(0),
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _onNavTapped(1),
            ),
            SizedBox(width: 40), // space for floating maps button
            IconButton(
              icon: const Icon(Icons.favorite),
              onPressed: () => _onNavTapped(3),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => _onNavTapped(4),
            ),
          ],
        ),
      ),
      // Floating Maps button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onNavTapped(2),
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.map),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
