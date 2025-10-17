import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:collection';
import 'package:collection/collection.dart';

// --- Imports for Extracted and External Logic ---
import '../jeepney_network_data.dart'; // allNodes, jeepneyNetwork, uniqueNodeNames
import '../graph_models.dart'; // Node, Edge
import '../geo_utils.dart'; // calculateStaggeredPoints
import '../route_segment.dart'; // RouteSegment, SegmentType
import '../route_finder.dart'; // RouteFinder
import '../widgets/route_info_bubble.dart';
import '../widgets/map_search_header.dart';
import '../widgets/route_action_button.dart';
import '../widgets/map_selection_header.dart';
import '../widgets/route_details_sheet.dart';
import '../widgets/instruction_tile.dart';
import 'package:flutter/scheduler.dart';

// --- Supabase/Auth/UUID (kept for type definitions/API calls) ---
import 'package:supabase_flutter/supabase_flutter.dart';

// NOTE: This client is only needed if other files need it, but it's okay to keep here.
final supabase = Supabase.instance.client;

// Global state variables for the overlays
int _currentStepIndex = 0;
bool _showStepOverlay = false;

// --- STATE FOR CONFIRMATION & FAVORITES ---
bool _isConfirmed = false;
bool _isFavoriteTo = false;

// --- COLOR CONSTANTS (Assuming a central location for these in a real app) ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kHeaderColor = Color(0xFFFFFFFF);

// 🌟 NEW CLASS: Model to pass pre-set destination data from other pages (like Favorites)
// 🌟 NEW CLASS: Model to pass pre-set destination data from other pages (like Favorites)
class PreSetDestination {
  final String name;
  final double latitude;
  final double longitude;

  PreSetDestination(
      {required this.name, required this.latitude, required this.longitude});

  // 🏆 CRITICAL FIX: Overriding == and hashCode to enable proper comparison 🏆
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PreSetDestination &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => name.hashCode ^ latitude.hashCode ^ longitude.hashCode;
}

// ---------------------------------------------------------------------------

class MapScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;

  // 🌟 NEW FIELD: Accepts pre-set destination from Favorites Page 🌟
  final PreSetDestination? toPlace;

  const MapScreen({
    super.key,
    this.initialLatitude = 15.1466,
    this.initialLongitude = 120.5960,
    this.initialZoom = 13.5,
    this.toPlace, // Initialize new field
  });

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

  // 🛑 MAP BOUNDARY CONSTRAINTS 🛑
  static final LatLngBounds _cameraBounds = LatLngBounds(
    southwest: const LatLng(15.05, 120.50),
    northeast: const LatLng(15.25, 120.70),
  );
  static const double _minZoomLevel = 12.0;
  static const double _maxZoomLevel = 18.0;

  // --- COMPUTED PROPERTIES ---
  double get _totalTime =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin);
  double get _totalDistance =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm);

  @override
  void initState() {
    super.initState();
    _loadNetworkVisualization();

    // 🛑 REMOVED: Initial setup for toPlace moved to didChangeDependencies
    // to avoid the ScaffoldMessenger error.
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🏆 FIX: This check now works because PreSetDestination implements ==
    if (widget.toPlace != null && widget.toPlace != oldWidget.toPlace) {
      // Only run if the new destination is available AND is DIFFERENT from the old one.
      _setPreSetDestination(widget.toPlace!);
    }
  }

  // 🌟 FIX: Use didChangeDependencies for logic that relies on 'context' 🌟
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // We check if it's the first time and a destination was passed.
    if (widget.toPlace != null && _endPoint == null) {
      _setPreSetDestination(widget.toPlace!);
    }
  }

  void setExternalDestination(PreSetDestination destination) {
  // Clear any existing route before setting the new destination
  // This is crucial for restarting the flow.
  _clearRoute(); 
  
  // Call the existing logic to process and set the destination
  _setPreSetDestination(destination); 
}

  void _enablePointSelection() {
    setState(() {
      // Clear all points when explicitly starting a new route selection
      _clearRoute();
      _isSelectingPoints = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Point selection ENABLED. Tap the map to set Start Location.')),
    );
  }

  void _loadNetworkVisualization() {
    _polylines.clear();
    _markers.removeWhere((m) => m.markerId.value.startsWith('USER_'));
    _currentRoute.clear();

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

    final Map<String, List<Edge>> sharedSegments = {};
    for (var edges in jeepneyNetwork.adjacencyList.values) {
      for (var edge in edges) {
        final key = '${edge.startNodeId}-${edge.endNodeId}';
        sharedSegments.putIfAbsent(key, () => []).add(edge);
      }
    }

    int polylineIndex = 0;
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
  }

  /// 🎯 REFINED LOGIC: Handles all map taps (setting start, setting end, or clearing/restarting).
  void _onMapTapped(LatLng tapPosition) {
    if (!_isSelectingPoints || _isSearching) return;

    setState(() {
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _isConfirmed = false;
      _isFavoriteTo = false;

      if (_startPoint == null && _endPoint == null) {
        // 1. Neither set: Set start point
        _startPoint = tapPosition;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Start point set. Tap again for Destination.')),
        );
      } else if (_startPoint != null && _endPoint == null) {
        // 2. Start set, End NOT set: Set end point
        _endPoint = tapPosition;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Destination set. Tap Confirm Route.')),
        );
      } else if (_startPoint == null && _endPoint != null) {
        // 3. End set (via search/favorites), Start NOT set: Set start point
        _startPoint = tapPosition;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start point set. Tap Confirm Route.')),
        );
      } else {
        // 4. Both set: Clear and set new start point (restarting the selection)
        _clearRoute();
        // Since _clearRoute sets _isSelectingPoints to false, we immediately re-enable it.
        _isSelectingPoints = true;
        _startPoint = tapPosition; // Start new selection immediately
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Route cleared. Start point set. Tap for Destination.')),
        );
      }

      _updateMarkers();
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
        _isConfirmed = true;
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
      _showStepOverlay = false;
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

    if (segments.isEmpty) return;

    final allPoints = segments.expand((s) => s.path).toList();

    if (allPoints.length < 2) return;

    double minLat =
        allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat =
        allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng =
        allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng =
        allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        100.0,
      ),
    );
  }

  // 🌟 HELPER FUNCTION: Unifies logic for setting end point (from search or favorites) 🌟
  void _setPreSetDestination(PreSetDestination toPlace) {
    final LatLng newPosition = LatLng(toPlace.latitude, toPlace.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newPosition, 16.0),
    );

    setState(() {
      _endPoint = newPosition;
      // Clear start point if the user somehow searched for a location already set as start
      if (_startPoint == newPosition) {
        _startPoint = null;
      }
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _updateMarkers();

      // Crucial: Manually enable the selection mode to allow the user to tap for the start point
      _isSelectingPoints = true;
      _isConfirmed = false;
      _isFavoriteTo = false;
    });

    // 🏆 FIX: Schedule the SnackBar call for after the current frame is built 🏆
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted)
        return; // Always check mounted if using async/post-frame callbacks
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Destination set to: "${toPlace.name}". Tap the map to set your Start Location.'),
          duration: const Duration(milliseconds: 3000),
        ),
      );
    });
  }

  /// 🎯 EDITED LOGIC: Now uses the helper function to set the End Point.
  void onSearchCallback(String query) {
    final String lowercaseQuery = query.toLowerCase();

    final Node? matchingNode = allNodes.values.firstWhereOrNull(
      (node) => node.name.toLowerCase() == lowercaseQuery,
    );

    if (matchingNode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Node "$query" not found in the network data.')),
      );
      return;
    }

    // 🌟 Use the new helper function 🌟
    _setPreSetDestination(PreSetDestination(
      name: matchingNode.name,
      latitude: matchingNode.position.latitude,
      longitude: matchingNode.position.longitude,
    ));
  }

  // Uses the extracted helper function and manages parent state updates via callback
  void _showInstructionsSheet() {
    showRouteDetailsSheet(
      context: context,
      currentRoute: _currentRoute,
      endPoint: _endPoint,
      totalTime: _totalTime,
      totalDistance: _totalDistance,
      isFavoriteTo: _isFavoriteTo,
      onFavoriteToggle: (isFavorite) {
        setState(() {
          _isFavoriteTo = isFavorite;
        });
      },
      onGoNowPressed: () {
        setState(() {
          _showStepOverlay = true;
          _currentStepIndex = 0;
        });
      },
    );
  }

  // Called from the step overlay to show the full sheet again
  void _showFullInstructions() {
    setState(() {
      _showStepOverlay = false;
    });
    _showInstructionsSheet();
  }

  void _nextStep() {
    if (_currentStepIndex < _currentRoute.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
    }
  }

  void _previousStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = kPrimaryColor;

    // Use the parameters passed into the widget to create the CameraPosition
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(widget.initialLatitude, widget.initialLongitude),
      zoom: widget.initialZoom,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- GOOGLE MAP ---
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            // Tap logic is now refined to handle Start-first or End-first selection
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

          // --- HEADER: Selection or Search ---
          if (_startPoint != null || _endPoint != null || _isSelectingPoints)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // Use the new extracted MapSelectionHeader widget
              child: MapSelectionHeader(
                startPoint: _startPoint,
                endPoint: _endPoint,
              ),
            )
          else
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: SafeArea(
                // Use the new extracted MapSearchHeader widget
                child: MapSearchHeader(
                  primaryColor: primaryColor,
                  nodeNames: uniqueNodeNames,
                  onSearch:
                      onSearchCallback, // This now triggers End Point selection
                ),
              ),
            ),

          // --- ROUTE INFO BUBBLE ---
          if (_currentRoute.isNotEmpty &&
              !_isSelectingPoints &&
              !_showStepOverlay)
            Positioned(
              top: 350,
              left: MediaQuery.of(context).size.width / 2 - 80,
              // Use the new extracted RouteInfoBubble widget
              child: RouteInfoBubble(
                totalTime: _totalTime,
                totalDistance: _totalDistance,
              ),
            ),

          // --- ACTION BUTTON (Select/Clear) ---
          Positioned(
            bottom: 110,
            right: 20,
            // Use the new extracted RouteActionButton widget
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

          // NEW FIX: Button to bring back the full instructions sheet
          if (_isConfirmed && _currentRoute.isNotEmpty && !_showStepOverlay)
            Positioned(
              bottom: 30, // Position it to the right
              right: 20,
              child: FloatingActionButton.extended(
                heroTag: 'show_instructions_sheet',
                onPressed: _showInstructionsSheet,
                label: const Text('Route Details'),
                icon: const Icon(Icons.list_alt),
                backgroundColor: primaryColor.withOpacity(0.95),
                foregroundColor: Colors.white,
              ),
            ),

          // --- CONFIRM BUTTON (positioned center/bottom, opposite to Route Details FAB) ---
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
                    boxShadow: const [
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
                      // Use the new InstructionTile widget
                      InstructionTile(
                          segment: _currentRoute[_currentStepIndex]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _showFullInstructions,
                            icon: const Icon(Icons.list),
                            label: const Text('Full Route'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                                side: BorderSide(color: kPrimaryColor)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_currentStepIndex > 0)
                                ElevatedButton(
                                  onPressed: _previousStep,
                                  child: const Text('Previous'),
                                ),
                              const SizedBox(width: 8),
                              if (_currentStepIndex < _currentRoute.length - 1)
                                ElevatedButton(
                                  onPressed: _nextStep,
                                  child: const Text('Next'),
                                ),
                              if (_currentStepIndex == _currentRoute.length - 1)
                                ElevatedButton(
                                  onPressed: () {
                                    _clearRoute();
                                  },
                                  child: const Text('Done'),
                                ),
                            ],
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
}
