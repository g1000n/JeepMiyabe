import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'route_data_loader.dart'; // Assumes this file is in the same 'lib' folder

// Center of Angeles City (default camera focus)
const LatLng defaultCameraPosition = LatLng(15.1513, 120.5996); 

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // State variables to hold the loaded data
  Set<Polyline> _polylines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllRoutes();
  }

  // Asynchronously loads the JSON data and updates the polylines state
  Future<void> _loadAllRoutes() async {
    // 1. Load the data using the function from route_data_loader.dart
    final List<RouteData> routeDataList = await loadRoutes();

    // 2. Convert the list of RouteData into a Set of Polyline objects for the GoogleMap widget
    final Set<Polyline> polylines = routeDataList.map((data) => data.polyline).toSet();

    if (mounted) {
      setState(() {
        _polylines = polylines;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Angeles Jeepney Routes'),
        backgroundColor: Colors.blueGrey,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Loading route data...', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            )
          : GoogleMap(
              // The initial position when the map first loads
              initialCameraPosition: const CameraPosition(
                target: defaultCameraPosition,
                zoom: 13, // Good zoom level to see the entire city
              ),
              // Pass the entire set of loaded polylines to the map
              polylines: _polylines, 
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
            ),
    );
  }
}
