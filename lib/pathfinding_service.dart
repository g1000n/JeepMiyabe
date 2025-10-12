// File: pathfinding_service.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart'; 

// Import all necessary utilities and config
import 'graph_models.dart'; 
import 'pathfinding_algorithm.dart'; 
import 'geo_utils.dart'; // Imports calculateHaversineDistance, findNearestNode, calculateWalkWeight, calculateBounds
import 'pathfinding_config.dart'; // Imports MAX_SNAP_DISTANCE_KM, WALK_TIME_PER_KM_MINUTES

// Define the hardcoded color for temporary walk edges
const Color _walkEdgeColor = Colors.grey;
const String _walkEdgeColorName = 'grey';


class PathfindingService {

  late JeepneyGraph _currentGraph; 
  
  // 🎯 NEW: State properties for map visualization
  Set<Polyline> _networkPolylines = {};
  Set<Marker> _networkMarkers = {};

  // 🎯 NEW: Public Getters for the RouteController
  Set<Polyline> get networkPolylines => _networkPolylines;
  Set<Marker> get networkMarkers => _networkMarkers;
  bool get isGraphLoaded => _currentGraph != null;


  Future<void> loadGraph() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/optimized_network_graph.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      _currentGraph = JeepneyGraph.fromJson(jsonMap); 
      print('Optimized Graph loaded successfully: ${_currentGraph.nodes.length} nodes.');
    } catch (e) {
      throw Exception('Failed to load assets/optimized_network_graph.json: $e');
    }
  }
  
  // 🎯 NEW: Core function to generate map objects (called after loadGraph)
  void generateNetworkVisualization() {
    if (_currentGraph == null) return;

    final markers = <Marker>{};
    final polylines = <Polyline>{};
    
    // 1. Generate Markers for all Nodes (Stops)
    for (var node in _currentGraph.nodes.values) {
      markers.add(
        Marker(
          markerId: MarkerId(node.id),
          position: node.position,
          infoWindow: InfoWindow(title: node.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
    
    // 2. Generate Polylines for all Edges (Jeepney Routes)
    // We group by route ID to ensure all segments of one route have the same color and ID.
    final Map<String, List<Edge>> edgesByRoute = {};
    _currentGraph.adjacencyList.values
        .expand((list) => list)
        .where((edge) => edge.type == EdgeType.JEEPNEY)
        .forEach((edge) => edgesByRoute.putIfAbsent(edge.routeId, () => []).add(edge));

    int polylineIndex = 0;
    edgesByRoute.forEach((routeId, edges) {
      // Use the color of the first edge in the route
      final Color routeColor = edges.first.routeColor;
      
      for (var edge in edges) {
        // Use the staggering utility for visibility if routes overlap
        final List<LatLng> staggeredPoints = edge.polylinePoints.length > 2
            ? edge.polylinePoints // Use full polyline if detailed
            : calculateStaggeredPoints(edge.polylinePoints, polylineIndex, edges.length);
        
        polylines.add(
          Polyline(
            polylineId: PolylineId('${routeId}_$polylineIndex'),
            points: staggeredPoints,
            color: routeColor,
            width: 4,
          ),
        );
        polylineIndex++;
      }
    });

    _networkMarkers = markers;
    _networkPolylines = polylines;
    print('Generated ${_networkPolylines.length} polylines and ${_networkMarkers.length} markers for map display.');
  }


  /// Finds the closest permanent node and dynamically connects the user's location to it.
  void _connectUserLocationToGraph({
    required String tempNodeId, 
    required double userLat, 
    required double userLon
  }) {
    // ... (The rest of _connectUserLocationToGraph remains the same as previously defined) ...
    final userPosition = LatLng(userLat, userLon);
    final closestNodeData = findNearestNode(_currentGraph, userPosition);

    if (closestNodeData == null) {
      throw Exception('Route finding error: User location is too far from any network node (>${MAX_SNAP_DISTANCE_KM.toStringAsFixed(2)}km).');
    }

    final closestPermanentNodeId = closestNodeData.id;
    final closestNodePosition = closestNodeData.position;
    
    final shortestDistance = calculateHaversineDistance(
      userLat, userLon, closestNodePosition.latitude, closestNodePosition.longitude
    );
    final timeMin = calculateWalkWeight(shortestDistance);

    final tempNode = Node(
      id: tempNodeId,
      name: (tempNodeId == 'USER_START') ? 'Start Point' : 'End Point',
      position: userPosition,
    );

    final edgeOut = Edge(
      id: 'T-${tempNodeId}-${closestPermanentNodeId}',
      startNodeId: tempNodeId,
      endNodeId: closestPermanentNodeId,
      startNodeName: tempNode.name, 
      endNodeName: closestNodeData.name, 
      type: EdgeType.WALK, 
      distance: shortestDistance, 
      time: timeMin, 
      routeId: 'WALK_TEMP', 
      routeName: (tempNodeId == 'USER_START') ? 'Start Walk' : 'End Walk', 
      routeColor: _walkEdgeColor, 
      routeColorName: _walkEdgeColorName, 
      polylinePoints: [tempNode.position, closestNodeData.position], 
    );
    
    final edgeIn = Edge(
      id: 'T-${closestPermanentNodeId}-${tempNodeId}',
      startNodeId: closestPermanentNodeId,
      endNodeId: tempNodeId,
      startNodeName: closestNodeData.name,
      endNodeName: tempNode.name,
      type: EdgeType.WALK, 
      distance: shortestDistance, 
      time: timeMin, 
      routeId: 'WALK_TEMP', 
      routeName: (tempNodeId == 'USER_START') ? 'Walk In' : 'Walk Out', 
      routeColor: _walkEdgeColor, 
      routeColorName: _walkEdgeColorName, 
      polylinePoints: [closestNodeData.position, tempNode.position], 
    );

    _currentGraph.nodes[tempNodeId] = tempNode;
    _currentGraph.adjacencyList[tempNodeId] = [edgeOut]; 

    _currentGraph.adjacencyList[closestPermanentNodeId] ??= [];
    _currentGraph.adjacencyList[closestPermanentNodeId]!.add(edgeIn);

    print('Connected $tempNodeId to graph at $closestPermanentNodeId (Dist: ${shortestDistance.toStringAsFixed(3)}km, Time: ${timeMin.toStringAsFixed(1)}min)');
  }

  /// Main method to find a route between two user coordinates.
  Future<JeepneyPath?> findRoute(double startLat, double startLon, double endLat, double endLon) async {
    if (!isGraphLoaded) throw Exception("Pathfinding service is not initialized.");
    
    const String startNodeId = 'USER_START';
    const String endNodeId = 'USER_END';
    JeepneyPath? path;

    try {
      _connectUserLocationToGraph(
        tempNodeId: startNodeId, userLat: startLat, userLon: startLon,
      );
      _connectUserLocationToGraph(
        tempNodeId: endNodeId, userLat: endLat, userLon: endLon,
      );
      
      path = findShortestPath(_currentGraph, startNodeId, endNodeId); 

    } catch (e) {
      rethrow; 
    } finally {
      _cleanupTemporaryNodes(startNodeId, endNodeId);
    }

    return path;
  }

  void _cleanupTemporaryNodes(String startNodeId, String endNodeId) {
    // ... (Cleanup logic is correct and remains the same) ...
    _currentGraph.nodes.remove(startNodeId);
    _currentGraph.nodes.remove(endNodeId);
    
    _currentGraph.adjacencyList.remove(startNodeId);
    _currentGraph.adjacencyList.remove(endNodeId);

    for (final nodeId in _currentGraph.adjacencyList.keys) {
      _currentGraph.adjacencyList[nodeId]!.removeWhere((edge) => 
        edge.endNodeId == startNodeId || edge.endNodeId == endNodeId
      );
    }
    print('Temporary nodes cleaned up.');
  }
}
