import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

// --- COLOR CONSTANTS (The Recommended Fix) ---
// Define a map of common Route IDs to fixed Colors for debugging
const Map<String, Color> kDebugRouteColors = {
  // Use distinct colors for your actual routes, replacing 'ROUTE_01', etc.
  'ROUTE_01': Color(0xFFF9DC5C), // Yellow
  'ROUTE_02': Color(0xFF1B998B), // Teal
  'ROUTE_03': Color(0xFFE4572E), // Orange-Red
  'W_DEFAULT': Color(0xFF9E9E9E), // Grey for walk segments (Must match routeId for walk edges)
};

const Color kDefaultJeepneyColor = Color(0xFF1976D2); // Dark Blue Fallback
// ---------------------------------------------


/// Defines the type of connection between two nodes.
enum EdgeType {
  JEEPNEY,
  WALK,
}

/// Represents a jeepney stop or a major intersection.
class Node {
  final String id;
  final String name;
  final LatLng position;

  Node({required this.id, required this.name, required this.position});

  // Utility to convert Node position back to Map<String, dynamic> for temporary use
  Map<String, double> toLatLngMap() =>
      {'lat': position.latitude, 'lon': position.longitude};

  // REQUIRED FOR DATALOADER: Factory constructor for deserialization (fromJson)
  factory Node.fromJson(Map<String, dynamic> json) {
    final double lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final double lon = (json['lon'] as num?)?.toDouble() ?? 0.0;

    return Node(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? 'Unnamed Node',
      position: LatLng(lat, lon),
    );
  }
}

/// Represents a directed connection (edge) between two nodes.
class Edge {
  final String id;
  final String startNodeId;
  final String endNodeId;
  final String startNodeName; 
  final String endNodeName;  
  final EdgeType type;
  final double distance; // in km
  final double time; // in minutes (calculated weight)
  final String routeId;
  final Color routeColor;
  final String routeColorName; // Retained, but will be set to the determined color's hex
  final List<LatLng> polylinePoints; // Points for drawing the edge path
  final String routeName; // Display name for the user

  // New getter for backward compatibility with older files expecting 'weight'.
  double get weight => time;

  Edge({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
    required this.startNodeName, 
    required this.endNodeName, 
    required this.type,
    required this.distance,
    required this.time,
    required this.routeId,
    required this.routeColor,
    required this.routeColorName,
    required this.polylinePoints,
    required this.routeName,
  });

  // REQUIRED FOR DATALOADER: Factory constructor for deserialization (fromJson)
  factory Edge.fromJson(Map<String, dynamic> json) {
    final String routeId = (json['routeId'] as String?) ?? 'W_DEFAULT';

    // 🎯 CRITICAL FIX: Determine color via lookup instead of fragile JSON parsing
    final Color determinedColor = kDebugRouteColors[routeId] ?? kDefaultJeepneyColor;
    
    // We'll set the routeColorName to the determined color's hex for compatibility
    final String determinedColorHex = determinedColor.value.toRadixString(16).toUpperCase();

    // 2. Reconstruct polyline points from the list of {lat, lon} maps
    final List<LatLng> polylinePoints = (json['polylinePoints'] as List?)
        ?.map((p) => LatLng(
                (p['lat'] as num).toDouble(), (p['lon'] as num).toDouble()))
        .toList() ??
      [];

    final String rawType = (json['type'] as String?) ?? 'WALK';
    final EdgeType edgeType =
        rawType.toUpperCase() == 'JEEPNEY' ? EdgeType.JEEPNEY : EdgeType.WALK;

    return Edge(
      id: (json['id'] as String?) ?? '',
      startNodeId: (json['startNodeId'] as String?) ?? '',
      endNodeId: (json['endNodeId'] as String?) ?? '',
      // 🎯 These are likely not in the JSON yet, using Node IDs as safe fallback:
      startNodeName: (json['startNodeName'] as String?) ?? (json['startNodeId'] as String? ?? 'Unknown Start'),
      endNodeName: (json['endNodeName'] as String?) ?? (json['endNodeId'] as String? ?? 'Unknown End'),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      time: (json['weight'] as num?)?.toDouble() ?? 0.0, // Assumes JSON uses 'weight'
      routeId: routeId,
      routeName: (json['routeName'] as String?) ?? 'Unknown Route',
      
      // 🎯 USE THE DETERMINED COLOR and HEX STRING
      routeColor: determinedColor,
      routeColorName: determinedColorHex,
      
      polylinePoints: polylinePoints,
      type: edgeType,
    );
  }
}

/// The entire graph structure (nodes and adjacency list).
class JeepneyGraph {
  final Map<String, Node> nodes;
  final Map<String, List<Edge>> adjacencyList;
  final Map<String, String> routeNames;

  JeepneyGraph({
    required this.nodes,
    required this.adjacencyList,
    this.routeNames = const {},
  });

  /// Utility function to get the descriptive name for a route ID.
  String getRouteName(String routeId) {
    return routeNames[routeId] ?? routeId;
  }

  // Factory constructor to deserialize the entire graph JSON.
  factory JeepneyGraph.fromJson(Map<String, dynamic> json) {
    // 1. Parse Nodes from "allNodes"
    final Map<String, Node> allNodes = {};
    if (json['allNodes'] is Map) {
      (json['allNodes'] as Map<String, dynamic>).forEach((nodeId, nodeJson) {
        allNodes[nodeId] = Node.fromJson(nodeJson as Map<String, dynamic>);
      });
    }

    // 2. Parse Adjacency List from "adjacencyList"
    final Map<String, List<Edge>> adjList = {};
    if (json['adjacencyList'] is Map) {
      (json['adjacencyList'] as Map<String, dynamic>)
          .forEach((startNodeId, edgesList) {
        adjList[startNodeId] = (edgesList as List)
            .map((e) => Edge.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }

    return JeepneyGraph(
      nodes: allNodes,
      adjacencyList: adjList,
    );
  }
}

// --- EXTENSIONS FOR JSON SERIALIZATION (used by the preprocessor) ---

/// Adds a toJson method to the Node class for serialization.
extension NodeJson on Node {
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': position.latitude,
        'lon': position.longitude,
      };
}

/// Adds a toJson method to the Edge class for serialization.
extension EdgeJson on Edge {
  Map<String, dynamic> toJson() => {
        'id': id,
        'startNodeId': startNodeId,
        'endNodeId': endNodeId,
        'weight': time, // 'time' is serialized as 'weight' for the algorithm
        'distance': distance,
        'type': type == EdgeType.JEEPNEY ? 'JEEPNEY' : 'WALK',
        'routeId': routeId,
        'routeName': routeName,
        'routeColorName':
            routeColorName, // This will now hold the determined hex string
        'polylinePoints': polylinePoints
            .map((p) => {'lat': p.latitude, 'lon': p.longitude})
            .toList(), // List of {lat, lon} maps
      };
}