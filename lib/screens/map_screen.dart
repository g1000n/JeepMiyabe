import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';
import 'dart:math';

// Local Project Files
import '../data_loader.dart'; 
import '../graph_models.dart';
import '../geo_utils.dart'; // Assumed to exist for calculating bounds
import '../route_segment_model.dart' as model; // 🎯 FIX: Explicitly import model
import '../route_finder.dart';

// UI Components (Refactored Widgets) - Assumed to exist
import '../widgets/route_info_bubble.dart'; 
import '../widgets/map_search_header.dart';
import '../widgets/route_action_button.dart';

// --- COLOR CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E); // App's primary orange-red
const Color kBackgroundColor = Color(0xFFFDF8E2); // Light background color (Pale Yellow/Off-White)

// --- Instruction Tile ---
class InstructionTile extends StatelessWidget {
  // 🎯 FIX: Use the prefixed type for the segment field
  final model.RouteSegment segment; 
  
  const InstructionTile({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    // 🎯 FIX: Use the prefixed SegmentType 
    switch (segment.type) {
      case model.SegmentType.WALK:
        icon = Icons.directions_walk;
        iconColor = Colors.grey.shade600;
        break;
      case model.SegmentType.JEEPNEY:
        icon = Icons.directions_bus_filled;
        iconColor = segment.color;
        break;
      case model.SegmentType.TRANSFER:
        icon = Icons.swap_horiz;
        iconColor = kPrimaryColor; 
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 30),
      title: Text(
        segment.description,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          // 🎯 FIX: Use prefixed SegmentType
          color: segment.type == model.SegmentType.JEEPNEY ? Colors.black : Colors.black87, 
        ),
      ),
      subtitle: Text(
        '${segment.durationMin.toStringAsFixed(0)} min / ${segment.distanceKm.toStringAsFixed(2)} km',
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }
}
// --- END Instruction Tile ---


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  
  // Separate Polylines for Network (static) and Result (dynamic)
  final Set<Polyline> _networkPolylines = LinkedHashSet(); 
  final Set<Polyline> _resultPolylines = LinkedHashSet(); 
  
  // Separate Markers for Network (static) and Result (dynamic/user)
  final Set<Marker> _networkMarkers = LinkedHashSet(); 
  final Set<Marker> _userMarkers = LinkedHashSet(); 
  
  JeepneyGraph? _jeepneyGraph;
  RouteFinder? _routeFinder; 

  LatLng? _startPoint;
  LatLng? _endPoint;
  // 🎯 FIX: Use the prefixed type for the list
  List<model.RouteSegment> _currentRoute = []; 
  bool _isSearching = false;
  bool _isDataLoaded = false; 

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(15.1466, 120.5960),
    zoom: 13.5, 
  );

  // 🎯 FIX: Use the prefixed type for fold operations
  double get _totalTime => _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin); 
  double get _totalDistance => _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm); 
  
  // Helper to combine all markers for the GoogleMap widget
  Set<Marker> get _allMarkers => {..._networkMarkers, ..._userMarkers};
  
  // Helper to combine all polylines for the GoogleMap widget
  Set<Polyline> get _allPolylines => {..._networkPolylines, ..._resultPolylines};


  @override
  void initState() {
    super.initState();
    _initializeDataAndMap(); 
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Initializes the network data and calls visualization immediately
  Future<void> _initializeDataAndMap() async {
    setState(() { _isSearching = true; });
    try {
      final graph = await DataLoader().loadOptimizedNetwork();

      setState(() {
        _jeepneyGraph = graph;
        _routeFinder = RouteFinder(graph);
        _isDataLoaded = true;
      });

      // Load network visualization once upon successful data load.
      await _loadNetworkVisualization(); 

    } catch (e) {
      debugPrint('Initialization ERROR: $e');
      setState(() {
        _isDataLoaded = false;
      });
    } finally {
      setState(() { _isSearching = false; });
    }
  }

  // 🎯 FIX: Pass the prefixed RouteSegment type
  LatLngBounds _boundsFromSegments(List<model.RouteSegment> segments) {
    double? minLat, maxLat, minLng, maxLng;

    for (var segment in segments) {
      for (var point in segment.path) {
        // Calculate bounds using min/max utility functions from dart:math
        minLat = min(minLat ?? point.latitude, point.latitude);
        maxLat = max(maxLat ?? point.latitude, point.latitude);
        minLng = min(minLng ?? point.longitude, point.longitude);
        maxLng = max(maxLng ?? point.longitude, point.longitude);
      }
    }

    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      // Default bounds if no segments are present
      return LatLngBounds(
        southwest: const LatLng(15.1, 120.5),
        northeast: const LatLng(15.2, 120.7),
      );
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _loadNetworkVisualization() async {
    if (!_isDataLoaded || _jeepneyGraph == null || _jeepneyGraph!.nodes.isEmpty) {
        debugPrint('Network data not available for visualization.');
        return;
    }

    final graph = _jeepneyGraph!;

    _networkPolylines.clear();
    _networkMarkers.clear();

    for (var node in graph.nodes.values) {
      _networkMarkers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          infoWindow: InfoWindow.noText, 
          onTap: () => _onMapTapped(node.position), 
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          alpha: 0.6, 
        ),
      );
    }

    final Map<String, List<Edge>> sharedSegments = {};
    for (var edges in graph.adjacencyList.values) {
      for (var edge in edges) {
        final key = '${edge.startNodeId}-${edge.endNodeId}';
        sharedSegments.putIfAbsent(key, () => []).add(edge);
      }
    }

    int polylineIndex = 0;
    sharedSegments.forEach((key, edges) {
      final edge = edges.first; // Use the first edge's properties for the segment

      _networkPolylines.add(
        Polyline(
          polylineId: PolylineId('network_route_$polylineIndex'),
          points: edge.polylinePoints, 
          color: edge.routeColor.withOpacity(0.5), 
          width: 3,
          zIndex: 1, 
        ),
      );
      polylineIndex++;
    });

    // CRITICAL: Call setState to update the GoogleMap widget with the populated sets.
    setState(() {}); 
    debugPrint('Network Dashboard loaded: ${_networkMarkers.length} nodes and ${_networkPolylines.length} route segments.');
  }

  void _onMapTapped(LatLng tapPosition) {
    if (!_isDataLoaded || _isSearching || _routeFinder == null) return; 
    
    setState(() {
      if (_startPoint == null) {
        _startPoint = tapPosition;
        _endPoint = null;
        _currentRoute.clear();
        _resultPolylines.clear(); 
        _updateUserMarkers(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start point set (Green marker). Tap again for Destination.')),
        );
      } else if (_endPoint == null) {
        _endPoint = tapPosition;
        _updateUserMarkers(); 
        _findRoute(); 
      } else {
        _clearRoute();
        // After clearing, set the new tap as the start point for a fresh route
        _startPoint = tapPosition; 
        _updateUserMarkers(); 
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route cleared. Start point reset.')),
        );
      }
    });
  }

  // Updated to manage ONLY user-placed markers
  void _updateUserMarkers() {
    _userMarkers.clear();

    if (_startPoint != null) {
      _userMarkers.add(
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
      _userMarkers.add(
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

  Future<void> _findRoute() async {
    if (!_isDataLoaded || _startPoint == null || _endPoint == null || _routeFinder == null) return; 

    setState(() {
      _isSearching = true;
      _currentRoute.clear();
      _resultPolylines.clear(); // Ensure only the result polylines are cleared
    });

    try {
      // Correctly call the route finding method on the RouteFinder
      final segments = await _routeFinder!.findPathWithGPS(_startPoint!, _endPoint!); 

      setState(() {
        _currentRoute = segments;
        _drawRoutePolylines(segments);
      });

      if (segments.isNotEmpty) { 
        _panCameraToRoute(segments);
        _showInstructionsSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No possible jeepney route found.')),
        );
      }
    } catch (e) {
      debugPrint('Route finding error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: ${e.toString().split(':')[0]}')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearRoute() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _currentRoute.clear();
      _resultPolylines.clear(); // Clear ONLY the result polylines
      _updateUserMarkers(); 
    });
  }

  // 🎯 FIX: Pass the prefixed RouteSegment type
  void _drawRoutePolylines(List<model.RouteSegment> segments) {
    int index = 0;
    _resultPolylines.clear(); 

    for (var segment in segments) {
      _resultPolylines.add(
        Polyline(
          polylineId: PolylineId('result_${index++}'),
          points: segment.path,
          color: segment.color,
          // 🎯 FIX: Use prefixed SegmentType
          width: segment.type == model.SegmentType.WALK ? 3 : 6, 
          // 🎯 FIX: Use prefixed SegmentType
          patterns: segment.type == model.SegmentType.WALK
              ? [PatternItem.dash(10), PatternItem.gap(5)] 
              : const <PatternItem>[],
          zIndex: 10, 
        ),
      );
    }
  }
  
  // 🎯 FIX: Pass the prefixed RouteSegment type
  void _panCameraToRoute(List<model.RouteSegment> segments) {
    if (_mapController != null && segments.expand((s) => s.path).isNotEmpty) {
      final bounds = _boundsFromSegments(segments);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          100, // Padding
        ),
      );
    }
  }


  void _showInstructionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Container( 
              color: kBackgroundColor,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Time: ${_totalTime.toStringAsFixed(0)} mins',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Distance: ${_totalDistance.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _currentRoute.length,
                      itemBuilder: (context, index) {
                        return InstructionTile(segment: _currentRoute[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = kPrimaryColor; 

    return Scaffold(
      extendBodyBehindAppBar: true, 
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            // Combine all markers and polylines
            markers: _allMarkers,
            polylines: _allPolylines,
            
            onTap: _isDataLoaded ? _onMapTapped : null, 
            myLocationEnabled: true,
            myLocationButtonEnabled: false, 
            padding: const EdgeInsets.only(bottom: 100.0), 
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: SafeArea(
              child: MapSearchHeader(primaryColor: primaryColor),
            ),
          ),
          
          if (!_isDataLoaded || _isSearching)
            const Center(
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: kPrimaryColor),
                      SizedBox(height: 10),
                      Text("Loading network data...", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

          if (_currentRoute.isNotEmpty)
            Positioned(
              top: 350, 
              left: MediaQuery.of(context).size.width / 2 - 80, 
              child: RouteInfoBubble(
                totalTime: _totalTime,
                totalDistance: _totalDistance,
              ),
            ),

          if (_isDataLoaded)
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
        ],
      ),
    );
  }
}
