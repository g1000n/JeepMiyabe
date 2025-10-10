import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';

// Local Project Files (Imports necessary for your complex logic)
import '../jeepney_network_data.dart'; 
import '../graph_models.dart';
import '../geo_utils.dart';
import '../route_segment.dart';
import '../route_finder.dart';

// UI Components (Refactored Widgets)
import '../widgets/route_info_bubble.dart'; 
import '../widgets/map_search_header.dart';
import '../widgets/route_action_button.dart';
import '../widgets/custom_bottom_nav_bar.dart'; 

// UI Utility/Logic (Refactored Instructions Sheet)
import '../utils/instructions_sheet.dart'; 


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = LinkedHashSet(); 
  final Set<Marker> _markers = LinkedHashSet();
  final RouteFinder _routeFinder = RouteFinder();

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<RouteSegment> _currentRoute = [];
  bool _isSearching = false;

  // Camera focused on the sample data area
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(15.1466, 120.5960),
    zoom: 13.5, 
  );

  // --- COMPUTED PROPERTIES (Used for the UI components) ---
  double get _totalTime => _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin);
  double get _totalDistance => _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm);


  @override
  void initState() {
    super.initState();
    _loadNetworkVisualization(); 
  }

  /// Loads all nodes as markers and all route segments as faint polylines
  void _loadNetworkVisualization() {
    _polylines.clear();
    _markers.clear();
    _currentRoute.clear();

    // Add all permanent network nodes as small violet markers
    for (var node in allNodes.values) {
      _markers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          infoWindow: InfoWindow(title: node.name, snippet: node.id),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          alpha: 0.6, 
        ),
      );
    }

    // Process edges to group shared segments for staggering
    final Map<String, List<Edge>> sharedSegments = {};
    for (var edges in jeepneyNetwork.adjacencyList.values) {
      for (var edge in edges) {
        final key = '${edge.startNodeId}-${edge.endNodeId}';
        sharedSegments.putIfAbsent(key, () => []).add(edge);
      }
    }

    int polylineIndex = 0;
    // Draw all segments, staggering them visually if they overlap
    sharedSegments.forEach((key, edges) {
      final totalSegments = edges.length;

      for (int i = 0; i < totalSegments; i++) {
        final edge = edges[i];

        final List<LatLng> staggeredPoints = calculateStaggeredPoints(
          edge.polylinePoints,
          i,
          totalSegments,
        );

        _polylines.add(
          Polyline(
            polylineId: PolylineId('network_route_$polylineIndex'),
            points: staggeredPoints,
            color: edge.routeColor.withOpacity(0.5), 
            width: 3,
            zIndex: 1, 
          ),
        );
        polylineIndex++;
      }
    });

    setState(() {});
    debugPrint('Network Dashboard loaded: ${_markers.length} nodes and ${_polylines.length} route segments.');
  }

  /// Handles map tap events to set start and end points for route finding.
  void _onMapTapped(LatLng tapPosition) {
    if (_isSearching) return;
    
    // Dismiss any existing instruction sheet
    Navigator.of(context).popUntil((route) => route.isFirst);

    setState(() {
      if (_startPoint == null) {
        // Set Start Point
        _startPoint = tapPosition;
        _endPoint = null;
        _currentRoute.clear();
        _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
        _updateMarkers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start point set (Green marker). Tap again for Destination.')),
        );
      } else if (_endPoint == null) {
        // Set End Point and Find Route
        _endPoint = tapPosition;
        _updateMarkers();
        _findRoute();
      } else {
        // Clear everything if both are set
        _clearRoute();
      }
    });
  }

  /// Updates the temporary user markers (Start/End) on the map.
  void _updateMarkers() {
    // Remove old user markers
    _markers.removeWhere((m) => m.markerId.value.startsWith('USER_'));

    if (_startPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('USER_START'),
          position: _startPoint!,
          infoWindow: const InfoWindow(title: 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          zIndex: 10,
          alpha: 1.0,
        ),
      );
    }
    if (_endPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('USER_END'),
          position: _endPoint!,
          infoWindow: const InfoWindow(title: 'End Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          zIndex: 10,
          alpha: 1.0,
        ),
      );
    }
  }

  /// Executes the pathfinding logic.
  Future<void> _findRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isSearching = true;
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('network_'));
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
    });

    try {
      final segments = await _routeFinder.findPathWithGPS(_startPoint!, _endPoint!);

      setState(() {
        _currentRoute = segments;
        _drawRoutePolylines(segments);
      });

      if (segments.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No possible jeepney route found.')),
        );
      }
    } catch (e) {
      debugPrint('Route finding error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during route finding: ${e.toString().split(':')[0]}')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// Clears the current route result and reloads the network dashboard view.
  void _clearRoute() {
    // Dismiss any existing instruction sheet
    Navigator.of(context).popUntil((route) => route.isFirst); 

    setState(() {
      _startPoint = null;
      _endPoint = null;
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _updateMarkers(); 
      _loadNetworkVisualization(); 
    });
  }

  /// Draws the calculated RouteSegments on the map using distinctive polylines.
  void _drawRoutePolylines(List<RouteSegment> segments) {
    int index = 0;
    for (var segment in segments) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('result_${index++}'),
          points: segment.path,
          color: segment.color,
          width: segment.type == SegmentType.WALK ? 3 : 6,
          patterns: segment.type == SegmentType.WALK
              ? [PatternItem.dash(10), PatternItem.gap(5)] // Dashed line for walking
              : const <PatternItem>[],
          zIndex: 10, 
        ),
      );
    }
    // Pan camera to view the entire route (Logic unchanged)
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _currentRoute.expand((s) => s.path).map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
            _currentRoute.expand((s) => s.path).map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            _currentRoute.expand((s) => s.path).map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
            _currentRoute.expand((s) => s.path).map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
          ),
        ),
        100.0, // padding
      ),
    );
  }
  
  /// Function passed to the bottom nav bar pin to trigger the instructions sheet.
  void _handleInstructionsPinPressed() {
    if (_currentRoute.isNotEmpty) {
      showInstructionsSheet(context, _currentRoute, _totalTime, _totalDistance);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on the map twice to find a route first.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          // 1. Google Map Widget (The base layer)
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false, 
            padding: const EdgeInsets.only(bottom: 180.0), 
            zoomControlsEnabled: false,
          ),

          // 2. Custom Top Header/Search Bar (Using the new widget)
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: MapSearchHeader(primaryColor: primaryColor),
            ),
          ),

          // 3. Floating Route Information Bubble (Using the new widget)
          if (_currentRoute.isNotEmpty)
            Positioned(
              top: 350, 
              left: MediaQuery.of(context).size.width / 2 - 80, 
              child: RouteInfoBubble(
                totalTime: _totalTime,
                totalDistance: _totalDistance,
              ),
            ),

          // 4. Floating Button: 'Tap to set start point' / 'Clear Route' (Using the new widget)
          Positioned(
            bottom: 110, 
            right: 20, 
            child: RouteActionButton(
              primaryColor: primaryColor,
              isSearching: _isSearching,
              startPointSet: _startPoint != null,
              endPointSet: _endPoint != null,
              clearRoute: _clearRoute,
            ),
          ),
          
          // 5. Custom Bottom Navigation Bar (Using the new widget)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavBar(
              primaryColor: primaryColor,
              onPinPressed: _handleInstructionsPinPressed, // Pass the logic here
            ),
          ),
        ],
      ),
    );
  }
}
