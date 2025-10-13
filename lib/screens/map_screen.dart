import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';
import '../jeepney_network_data.dart';
import '../graph_models.dart';
import '../geo_utils.dart';
import '../route_segment.dart';
import '../route_finder.dart';
import '../widgets/route_info_bubble.dart';
import '../widgets/map_search_header.dart'; // We'll keep this but the new header will overlay it
import '../widgets/route_action_button.dart';

int _currentStepIndex = 0;
bool _showStepOverlay = false;

// --- NEW STATE FOR CONFIRMATION & FAVORITES ---
bool _isConfirmed = false;
bool _isFavoriteTo = false;

// --- COLOR CONSTANTS ADDED HERE ---
const Color kPrimaryColor = Color(0xFFE4572E); // App's primary orange-red
const Color kBackgroundColor =
    Color(0xFFFDF8E2); // Light background color (Pale Yellow/Off-White)
const Color kHeaderColor = Color(0xFFFFFFFF); // White for the selection header

// --- START Instruction Tile ---
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
        iconColor = kPrimaryColor;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 30),
      title: Text(
        segment.description,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: segment.type == SegmentType.JEEPNEY
              ? Colors.black
              : Colors.black87,
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
  final Set<Polyline> _polylines = LinkedHashSet();
  final Set<Marker> _markers = LinkedHashSet();
  final RouteFinder _routeFinder = RouteFinder();

  LatLng? _startPoint;
  LatLng? _endPoint;
  List<RouteSegment> _currentRoute = [];
  bool _isSearching = false;
  bool _isSelectingPoints = false;

  // Camera focused on the sample data area
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(15.1466, 120.5960),
    zoom: 13.5,
  );

  // 🛑 MAP BOUNDARY CONSTRAINTS (Adjusted for tighter view) 🛑
  static final LatLngBounds _cameraBounds = LatLngBounds(
    southwest: const LatLng(15.05, 120.50),
    northeast: const LatLng(15.25, 120.70),
  );
  // Increased Min Zoom Level (tighter zoom-out limit)
  static const double _minZoomLevel = 12.0;
  static const double _maxZoomLevel = 18.0;

  // --- COMPUTED PROPERTIES (Used for the UI components) ---
  double get _totalTime =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin);
  double get _totalDistance =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm);

  @override
  void initState() {
    super.initState();
    _loadNetworkVisualization();
  }

  /// Enables the user to tap the map to set start and end points.
  void _enablePointSelection() {
    setState(() {
      // If a route is already set, clear it first
      if (_startPoint != null || _endPoint != null) {
        _clearRoute(); // This sets _isSelectingPoints = false internally
      }
      // Then, enable the selection mode
      _isSelectingPoints = true;
    });
    // Show a hint
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Point selection ENABLED. Tap the map to set Start Location.')),
    );
  }

  /// Loads all nodes as markers and all route segments as faint polylines
  void _loadNetworkVisualization() {
    _polylines.clear();
    _markers.clear();
    _currentRoute.clear();

    // Add all permanent network nodes as small markers
    for (var node in allNodes.values) {
      _markers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          infoWindow: InfoWindow.noText,
          onTap: () => _onMapTapped(node.position),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
    debugPrint(
        'Network Dashboard loaded: ${_markers.length} nodes and ${_polylines.length} route segments.');
  }

  /// Handles map tap events to set start and end points for route finding.
  void _onMapTapped(LatLng tapPosition) {
    if (!_isSelectingPoints || _isSearching) return;

    setState(() {
      if (_startPoint == null) {
        _startPoint = tapPosition;
        _endPoint = null;
        _currentRoute.clear();
        _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
        _updateMarkers();
        _isConfirmed = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Start point set (Green marker). Tap again for Destination.')),
        );
      } else if (_endPoint == null) {
        _endPoint = tapPosition;
        _updateMarkers();
        _isSelectingPoints = false;
        _isConfirmed = false;
      } else {
        _clearRoute();
        _isSelectingPoints = true;
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
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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

  Future<void> _findRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    setState(() {
      _isSearching = true;
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('network_'));
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
    });
    try {
      final segments =
          await _routeFinder.findPathWithGPS(_startPoint!, _endPoint!);
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
        SnackBar(
            content: Text(
                'An error occurred during route finding: ${e.toString().split(':')[0]}')),
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
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _updateMarkers();
      _loadNetworkVisualization();
      _isSelectingPoints = false;
      _isConfirmed = false;
      _isFavoriteTo = false;
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
          width: segment.type == SegmentType.WALK ? 3 : 6,
          patterns: segment.type == SegmentType.WALK
              ? [PatternItem.dash(10), PatternItem.gap(5)]
              : const <PatternItem>[],
          zIndex: 10,
        ),
      );
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _currentRoute
                .expand((s) => s.path)
                .map((p) => p.latitude)
                .reduce((a, b) => a < b ? a : b),
            _currentRoute
                .expand((s) => s.path)
                .map((p) => p.longitude)
                .reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            _currentRoute
                .expand((s) => s.path)
                .map((p) => p.latitude)
                .reduce((a, b) => a > b ? a : b),
            _currentRoute
                .expand((s) => s.path)
                .map((p) => p.longitude)
                .reduce((a, b) => a > b ? a : b),
          ),
        ),
        100.0,
      ),
    );
  }

  void _showInstructionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBackgroundColor,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.2,
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
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Distance: ${_totalDistance.toStringAsFixed(1)} km',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.directions_run),
                            label: const Text('Go Now'),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _showStepOverlay = true;
                                _currentStepIndex = 0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFavoriteTo
                                ? Colors.amber
                                : Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                              _isFavoriteTo ? Icons.star : Icons.star_border),
                          label: const Text('Favorite To:'),
                          onPressed: () {
                            setState(() {
                              _isFavoriteTo = !_isFavoriteTo;
                            });
                          },
                        ),
                      ],
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

  Widget _buildSelectionHeader() {
    String fromText = _startPoint == null
        ? 'Tap map to set Start Point'
        : 'FROM: ${getApproximateLocationName(_startPoint!)}';

    String toText = _endPoint == null
        ? (_startPoint == null
            ? 'Tap "Start New Route" to begin'
            : 'Tap map to set Destination')
        : 'TO: ${getApproximateLocationName(_endPoint!)}';

    TextStyle statusStyle =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: kHeaderColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trip_origin, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fromText,
                    style: statusStyle.copyWith(
                      color: _startPoint != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 10, thickness: 1),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toText,
                    style: statusStyle.copyWith(
                      color: _endPoint != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            padding: EdgeInsets.only(
                bottom: 100.0, top: _isSelectingPoints ? 150.0 : 0),
            zoomControlsEnabled: false,
            cameraTargetBounds: CameraTargetBounds(_cameraBounds),
            minMaxZoomPreference:
                const MinMaxZoomPreference(_minZoomLevel, _maxZoomLevel),
            mapToolbarEnabled: false,
          ),

          if (_isSelectingPoints)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildSelectionHeader(),
            )
          else
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: SafeArea(
                child: MapSearchHeader(primaryColor: primaryColor),
              ),
            ),

          if (_currentRoute.isNotEmpty && !_isSelectingPoints)
            Positioned(
              top: 350,
              left: MediaQuery.of(context).size.width / 2 - 80,
              child: RouteInfoBubble(
                totalTime: _totalTime,
                totalDistance: _totalDistance,
              ),
            ),

          Positioned(
            bottom: 110,
            right: 20,
            child: RouteActionButton(
              primaryColor: primaryColor,
              isSearching: _isSearching,
              startPointSet: _startPoint != null,
              endPointSet: _endPoint != null,
              clearRoute: _clearRoute,
              isSelectingPoints: _isSelectingPoints,
              enableSelection: _enablePointSelection,
            ),
          ),

          // --- CONFIRM BUTTON ---
          if (_startPoint != null && _endPoint != null && !_isConfirmed)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: SafeArea(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Confirm Route',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    setState(() {
                      _isConfirmed = true;
                    });
                    await _findRoute();
                    if (_currentRoute.isNotEmpty) {
                      _showInstructionsSheet();
                    }
                  },
                ),
              ),
            ),

          // --- STEP-BY-STEP OVERLAY ---
          if (_showStepOverlay && _currentRoute.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kHeaderColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Step ${_currentStepIndex + 1} of ${_currentRoute.length}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      InstructionTile(
                          segment: _currentRoute[_currentStepIndex]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStepIndex > 0)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentStepIndex--;
                                });
                              },
                              child: const Text('Previous'),
                            ),
                          if (_currentStepIndex < _currentRoute.length - 1)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _currentStepIndex++;
                                });
                              },
                              child: const Text('Next'),
                            ),
                          if (_currentStepIndex == _currentRoute.length - 1)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _showStepOverlay = false;
                                });
                              },
                              child: const Text('Done'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String getApproximateLocationName(LatLng point) {
    return 'Marker Location (${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)})';
  }
}
