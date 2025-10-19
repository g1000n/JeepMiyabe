import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/scheduler.dart';
import '../jeepney_network_data.dart';
import '../graph_models.dart';
import '../geo_utils.dart';
import '../route_segment.dart';
import '../route_finder.dart';
import '../widgets/route_info_bubble.dart';
import '../widgets/map_search_header.dart';
import '../widgets/route_action_button.dart';
import '../widgets/map_selection_header.dart';
import '../widgets/route_details_sheet.dart';
import '../widgets/instruction_tile.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final supabase = Supabase.instance.client;

// global state variables for the overlays
int _currentStepIndex = 0;
bool _showStepOverlay = false;

// state for confirmation and favorites
bool _isConfirmed = false;
bool _isFavoriteTo = false;

// color constants
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kHeaderColor = Color(0xFFFFFFFF);
const Color kLocationButtonColor =
    Color(0xFF007AFF); // A nice blue for location

class PreSetDestination {
  final String name;
  final double latitude;
  final double longitude;

  PreSetDestination(
      {required this.name, required this.latitude, required this.longitude});

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

// disclaimer constant
const String kRouteDisclaimer =
    "Disclaimer: Routes prioritize the shortest mathematical cost (time/distance). This may suggest a path with transfers over a direct single-jeep route if the overall calculated cost is lower. Always confirm routes locally, as direct options may exist that are not shown here.";

class MapScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final double initialZoom;

  final PreSetDestination? toPlace;

  const MapScreen({
    super.key,
    this.initialLatitude = 15.1466,
    this.initialLongitude = 120.5960,
    this.initialZoom = 13.5,
    this.toPlace,
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
  bool _isLocating = false; // loading state for geolocator

  // map boundary constraints
  static final LatLngBounds _cameraBounds = LatLngBounds(
    southwest: const LatLng(15.05, 120.50),
    northeast: const LatLng(15.25, 120.70),
  );
  static const double _minZoomLevel = 13.5;
  static const double _maxZoomLevel = 20.0;

  // --- COMPUTED PROPERTIES ---
  double get _totalTime =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.durationMin);
  double get _totalDistance =>
      _currentRoute.fold(0.0, (sum, item) => sum + item.distanceKm);

  @override
  void initState() {
    super.initState();
    _loadNetworkVisualization();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.toPlace != null && widget.toPlace != oldWidget.toPlace) {
      _setPreSetDestination(widget.toPlace!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.toPlace != null && _endPoint == null) {
      _setPreSetDestination(widget.toPlace!);
    }
  }

  //MODIFIED FUNCTION: Now sets the fixed green marker at current location
  Future<void> _setStartToCurrentLocation() async {
    // 1. Set initial loading state and enter selection mode
    setState(() {
      _isLocating = true;
      _isSelectingPoints = true; // Automatically enable selection mode
      _currentRoute.clear(); // Clear any previous route attempts
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _isConfirmed = false;
      _isFavoriteTo = false;
    });

    try {
      // Check for necessary permissions and services (same as before)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in settings.');
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final LatLng currentLocation =
          LatLng(position.latitude, position.longitude);

      setState(() {
        // 2. SET THE FIXED START POINT MARKER
        _startPoint = currentLocation;
        _updateMarkers(); // Update markers to show the new start point

        // 3. Move camera to the new location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
              currentLocation, 17.0), // Center and zoom in
        );

        // 4. Provide explicit user feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Start Location set to your current GPS position. Now tap map for Destination.')),
        );
      });
    } catch (e) {
      // Handle various exceptions from geolocator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Could not get location: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    } finally {
      // 5. Turn off loading state
      setState(() {
        _isLocating = false;
      });
    }
  }

  void setExternalDestination(PreSetDestination destination) {
    _clearRoute();
    _setPreSetDestination(destination);
  }

  void _enablePointSelection() {
    setState(() {
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

    // Mock markers from network data
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

    // Mock polylines from network data
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
    // Remove existing user markers (Green Pin and Red Pin)
    _markers.removeWhere((m) => m.markerId.value.startsWith('USER_'));

    if (_startPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('USER_START'),
          position: _startPoint!,
          infoWindow: const InfoWindow(title: 'Start Location'),
          // This is the Green Pin marker
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

  Future<void> _saveRouteHistory() async {
    final String? userId = supabase.auth.currentUser?.id;
    if (userId == null ||
        _currentRoute.isEmpty ||
        _startPoint == null ||
        _endPoint == null) {
      debugPrint(
          'HISTORY SAVE FAILED: User not authenticated or data incomplete.');
      return;
    }

    final List<Map<String, dynamic>> routeJsonList =
        _currentRoute.map((segment) => segment.toJson()).toList();

    final String startString =
        'Lat: ${_startPoint!.latitude.toStringAsFixed(4)}, Lng: ${_startPoint!.longitude.toStringAsFixed(4)}';
    final String endString =
        'Lat: ${_endPoint!.latitude.toStringAsFixed(4)}, Lng: ${_endPoint!.longitude.toStringAsFixed(4)}';

    try {
      // NOTE: This is mock Supabase logic as the actual table structure is unknown
      await supabase.from('route_history').insert({
        'user_id': userId,
        'start_point': startString,
        'end_point': endString,
        'route_data': routeJsonList,
      });

      debugPrint('Route history saved successfully for user $userId.');
    } on PostgrestException catch (e) {
      debugPrint('SUPABASE ERROR saving history: ${e.message}');
    } catch (e) {
      debugPrint('GENERAL EXCEPTION saving route history: $e');
    }
  }

  Future<void> _findRoute() async {
    if (_startPoint == null || _endPoint == null) return;

    debugPrint(
        'START POINT: Lat: ${_startPoint!.latitude}, Lng: ${_startPoint!.longitude}');
    debugPrint(
        'END POINT:   Lat: ${_endPoint!.latitude}, Lng: ${_endPoint!.longitude}');
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

  void _setPreSetDestination(PreSetDestination toPlace) {
    final LatLng newPosition = LatLng(toPlace.latitude, toPlace.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newPosition, 16.0),
    );

    setState(() {
      _endPoint = newPosition;
      if (_startPoint == newPosition) {
        _startPoint = null;
      }
      _currentRoute.clear();
      _polylines.removeWhere((p) => p.polylineId.value.startsWith('result_'));
      _updateMarkers();

      _isSelectingPoints = true;
      _isConfirmed = false;
      _isFavoriteTo = false;
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Destination set to: "${toPlace.name}". Now, set your Start Location (tap map or use the My Location button).'),
          duration: const Duration(milliseconds: 3000),
        ),
      );
    });
  }

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

    _setPreSetDestination(PreSetDestination(
      name: matchingNode.name,
      latitude: matchingNode.position.latitude,
      longitude: matchingNode.position.longitude,
    ));
  }

  void _showInstructionsSheet() {
    showRouteDetailsSheet(
      context: context,
      currentRoute: _currentRoute,
      endPoint: _endPoint,
      totalTime: _totalTime,
      totalDistance: _totalDistance,
      isFavoriteTo: _isFavoriteTo,
      disclaimerText: kRouteDisclaimer,
      onFavoriteToggle: (isFavorite) {
        setState(() {
          _isFavoriteTo = isFavorite;
        });
      },
      onGoNowPressed: () {
        setState(() {
          _showStepOverlay = true;
          _currentStepIndex = 0;
          _saveRouteHistory();
        });
      },
    );
  }

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
            onTap: _onMapTapped,
            myLocationEnabled: true, // This enables the dynamic blue dot
            myLocationButtonEnabled: false, // We use a custom button
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
                child: MapSearchHeader(
                  primaryColor: primaryColor,
                  nodeNames: uniqueNodeNames,
                  onSearch: onSearchCallback,
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
              child: RouteInfoBubble(
                totalTime: _totalTime,
                totalDistance: _totalDistance,
              ),
            ),

          // --- ACTION BUTTON (Select/Clear) ---
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

          // "My Location" Button (Sets the Start Point marker and fills "From:")
          Positioned(
            bottom: 30, // Positioned above the Route Details FAB
            right: 20,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              onPressed: _isLocating
                  ? null
                  : _setStartToCurrentLocation, // CALLS NEW FUNCTION
              backgroundColor: _isLocating ? Colors.grey : kLocationButtonColor,
              foregroundColor: Colors.white,
              child: _isLocating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(FontAwesomeIcons.locationDot),
            ),
          ),

          // Button to bring back the full instructions sheet
          if (_isConfirmed && _currentRoute.isNotEmpty && !_showStepOverlay)
            Positioned(
              bottom: 30,
              left:
                  20, // Move this button to the left to avoid overlap with My Location FAB
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
              right: 90, // Adjusted to make space for the My Location FAB
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
