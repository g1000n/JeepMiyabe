import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';

// Local Project Files (Assuming these contain Node, Edge, Network, and utilities)
import 'jeepney_network_data.dart'; // Contains allNodes and jeepneyNetwork
import 'graph_models.dart';        // Contains Node, Edge, etc.
import 'geo_utils.dart';           // Contains coordinate utilities, including calculateStaggeredPoints
import 'route_segment.dart';       // Defines the RouteSegment model and SegmentType enum
import 'route_finder.dart';        // The A* pathfinding logic

// --- Instruction Tile ---
// This widget displays a single step (segment) of the calculated route.
class InstructionTile extends StatelessWidget {
  final RouteSegment segment;
  const InstructionTile({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (segment.type) {
      case SegmentType.WALK:
        icon = Icons.directions_walk;
        iconColor = Colors.grey.shade600;
        break;
      case SegmentType.JEEPNEY:
        icon = Icons.directions_bus_filled;
        iconColor = segment.color;
        break;
      case SegmentType.TRANSFER:
        icon = Icons.swap_horiz;
        iconColor = Colors.deepOrange;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 30),
      title: Text(
        segment.description,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: segment.type == SegmentType.JEEPNEY ? Colors.black : Colors.black87,
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
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  final RouteFinder _routeFinder = RouteFinder();

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<RouteSegment> _currentRoute = [];
  bool _isSearching = false;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(15.1466, 120.5960),
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _loadNetworkVisualization();
  }

  /// Loads all static jeepney routes onto the map.
  /// This function uses the `calculateStaggeredPoints` utility (assumed to be in geo_utils.dart)
  /// to slightly offset overlapping routes, minimizing visual clutter.
  void _loadNetworkVisualization() {
    _polylines.clear();
    _markers.clear();
    _currentRoute.clear();

    // 1. Load Node Markers
    for (var node in allNodes.values) {
      _markers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          infoWindow: InfoWindow(title: node.name, snippet: node.id),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    // 2. Load Edge Polylines (using staggering/splaying technique)
    final Map<String, List<Edge>> sharedSegments = {};

    // Group edges that share the same start-end coordinates
    for (var edges in jeepneyNetwork.adjacencyList.values) {
      for (var edge in edges) {
        // Create a canonical key for the segment (e.g., 'NODE_A-NODE_B')
        final key = '${edge.startNodeId}-${edge.endNodeId}';
        sharedSegments.putIfAbsent(key, () => []).add(edge);
      }
    }

    int polylineIndex = 0;
    sharedSegments.forEach((key, edges) {
      final totalSegments = edges.length;

      for (int i = 0; i < totalSegments; i++) {
        final edge = edges[i];

        // This utility shifts the polyline laterally based on its index (i)
        // and the total number of shared routes (totalSegments)
        final List<LatLng> staggeredPoints = calculateStaggeredPoints(
          edge.polylinePoints,
          i,
          totalSegments,
        );

        _polylines.add(
          Polyline(
            polylineId: PolylineId('network_route_$polylineIndex'),
            points: staggeredPoints,
            color: edge.routeColor.withOpacity(0.5), // Lighter color for background network
            width: 3,
            zIndex: 1, // Low Z-index so the calculated route draws on top
          ),
        );
        polylineIndex++;
      }
    });

    setState(() {});
    print('Network Dashboard loaded: ${_markers.length} nodes and ${_polylines.length} route segments.');
  }

  void _onMapTapped(LatLng tapPosition) {
    if (_isSearching) return;

    Navigator.of(context).popUntil((route) => route.isFirst);

    setState(() {
      if (_startPoint == null) {
        _startPoint = tapPosition;
        _endPoint = null;
        _currentRoute.clear();
        _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
        _updateMarkers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start point set (Green marker). Tap again for Destination.')),
        );
      } else if (_endPoint == null) {
        _endPoint = tapPosition;
        _updateMarkers();
        _findRoute();
      } else {
        _clearRoute();
      }
    });
  }

  void _updateMarkers() {
    _markers.removeWhere((m) => m.markerId.value.startsWith('USER_'));

    if (_startPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('USER_START'),
          position: _startPoint!,
          infoWindow: const InfoWindow(title: 'Start Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
        ),
      );
    }
  }

  Future<void> _findRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isSearching = true;
      _currentRoute.clear();
      // CRITICAL FIX: Only clear the previously calculated route result ('result_'), 
      // DO NOT clear the 'network_' polylines, which represent the full route visualization.
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
    });

    try {
      // Assuming RouteFinder.findPathWithGPS returns a list of segments, 
      // each with the detailed LatLng path that follows the roads.
      final segments = await _routeFinder.findPathWithGPS(_startPoint!, _endPoint!);

      setState(() {
        _currentRoute = segments;
        _drawRoutePolylines(segments);
      });

      if (segments.isNotEmpty) {
        _showInstructionsSheet();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No possible jeepney route found.')),
        );
      }
    } catch (e) {
      print('Route finding error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during route finding: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearRoute() {
    Navigator.of(context).popUntil((route) => route.isFirst);

    setState(() {
      _startPoint = null;
      _endPoint = null;
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _updateMarkers();
      // Reloading the visualization ensures all nodes and edges are visible if they were somehow cleared.
      _loadNetworkVisualization(); 
    });
  }

  void _drawRoutePolylines(List<RouteSegment> segments) {
    int index = 0;
    for (var segment in segments) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('result_${index++}'),
          points: segment.path,
          color: segment.color,
          // Make the walking segments dashed and thin, and jeepney segments solid and thick
          width: segment.type == SegmentType.WALK ? 3 : 6,
          patterns: segment.type == SegmentType.WALK
              ? [PatternItem.dash(10), PatternItem.gap(5)]
              : const <PatternItem>[],
          zIndex: 10, // High Z-index ensures it draws on top of the 'network_' polylines (Z=1)
        ),
      );
    }
  }

  void _showInstructionsSheet() {
    double totalTime = _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin);
    double totalDistance = _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.1,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Time: ${totalTime.toStringAsFixed(0)} mins',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Distance: ${totalDistance.toStringAsFixed(1)} km',
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
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String fabText;
    if (_isSearching) {
      fabText = 'Searching...';
    } else if (_startPoint == null) {
      fabText = 'Tap to Set Start Point';
    } else if (_endPoint == null) {
      fabText = 'Tap to Set Destination';
    } else {
      fabText = 'Clear Route';
    }

    Function() fabAction;
    if (_isSearching) {
      fabAction = () {};
    } else if (_endPoint != null) {
      fabAction = _clearRoute;
    } else {
      fabAction = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap the map to set your location.')),
        );
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('JeepMiyabe Route Finder'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearRoute,
            tooltip: 'Clear Route and Show Dashboard',
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: _polylines,
        onTap: _onMapTapped,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fabAction,
        label: Text(fabText),
        icon: Icon(_isSearching
            ? Icons.hourglass_top
            : (_endPoint != null ? Icons.clear : Icons.location_on)),
        backgroundColor: _endPoint != null ? Colors.redAccent : Colors.deepOrangeAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
