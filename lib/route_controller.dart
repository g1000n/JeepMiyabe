// File: route_controller.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Local Imports ---
import 'pathfinding_service.dart';
import 'pathfinding_algorithm.dart'; 
import 'route_segment_converter.dart'; 

// 🎯 FIX: Apply an 'as' prefix to the model file to resolve the ambiguity.
import 'route_segment_model.dart' as model; 
import 'geo_utils.dart'; // Imports calculateBounds

class RouteController extends ChangeNotifier {
 final PathfindingService _pathfindingService = PathfindingService();

 // --- Core State Properties ---
 bool isLoading = false;
 JeepneyPath? currentPath;
 String? errorMessage;
 
 // 🎯 This requires the return type of convertEdgesToSegments to match List<model.RouteSegment>
 List<model.RouteSegment> routeInstructions = []; // User-friendly instructions

  // 🎯 NEW: Property to hold the camera view area for the final route
  LatLngBounds? routeBounds; 

 // --- Map Visualization Getters ---
 Set<Polyline> get networkPolylines => _pathfindingService.networkPolylines;
 Set<Marker> get networkMarkers => _pathfindingService.networkMarkers;
 
 // --- User Input Properties ---
 LatLng? startLocation;
 LatLng? endLocation;


  // --------------------------------------------------------------------------
  // --- Initialization ---
  // --------------------------------------------------------------------------
  
  /// Loads the graph data from assets and prepares the visualization data.
  Future<void> initialize() async {
    if (_pathfindingService.isGraphLoaded) return; 
    
    isLoading = true;
    notifyListeners();
    try {
      await _pathfindingService.loadGraph();
      _pathfindingService.generateNetworkVisualization();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Failed to load graph data: $e';
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners(); 
    }
  }

  // --------------------------------------------------------------------------
  // --- User Interaction ---
  // --------------------------------------------------------------------------

  void setStartLocation(LatLng location) {
    startLocation = location;
    if (endLocation != null) {
      findRoute();
    }
    notifyListeners();
  }

  void setEndLocation(LatLng location) {
    endLocation = location;
    if (startLocation != null) {
      findRoute();
    }
    notifyListeners();
  }

  // --------------------------------------------------------------------------
  // --- The Core Routing Logic ---
  // --------------------------------------------------------------------------

  Future<void> findRoute() async {
    if (startLocation == null || endLocation == null) {
      errorMessage = 'Please select both start and end locations.';
      notifyListeners();
      return;
    }
    if (!_pathfindingService.isGraphLoaded) {
      errorMessage = 'Graph data is still loading or failed to load.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    currentPath = null;
    routeInstructions = []; // Clear old instructions
    routeBounds = null; // Clear old camera bounds
    notifyListeners();

    try {
      final path = await _pathfindingService.findRoute(
        startLocation!.latitude,
        startLocation!.longitude,
        endLocation!.latitude,
        endLocation!.longitude,
      );

      if (path == null) {
        errorMessage = 'No valid route found within the walk limit.';
        currentPath = null;
      } else {
        // 1. Generate the final, merged segments for the UI list.
        routeInstructions = convertEdgesToSegments(path.edges);
        currentPath = path;

        // 2. Calculate and save the bounds of the new path for camera movement
        final allRoutePoints = path.edges.expand((e) => e.polylinePoints).toList();
        routeBounds = calculateBounds(allRoutePoints); 
      }
    } catch (e) {
      errorMessage = 'Routing Error: ${e.toString()}';
      print(e);
      currentPath = null;
      routeInstructions = [];
      routeBounds = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Method to clear the route for a new search
  void clearRoute() {
    startLocation = null;
    endLocation = null;
    currentPath = null;
    routeInstructions = []; // Clear instructions
    routeBounds = null; // Clear camera bounds
    errorMessage = null;
    notifyListeners();
  }
}
