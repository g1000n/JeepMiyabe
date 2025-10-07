import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Removed: import 'route_finder.dart'; as it is no longer needed

/// Represents a geographic point in the jeepney network, typically an intersection or terminal.
class Node {
  final String id;
  final String name;
  final LatLng position;

  Node({
    required this.id,
    required this.name,
    required this.position,
  });
}

/// Represents a direct segment of a jeepney route between two Nodes.
class Edge {
  final String startNodeId;
  final String endNodeId;
  final double weight; // The distance in Kilometers, used for travel time calculation
  final String routeName; // Which jeepney route this segment belongs to
  final Color routeColor; // Visual color for the polyline
  final String routeColorName; // Added for transfer/display logic
  final List<LatLng> polylinePoints; // The actual road shape for drawing

  Edge({
    required this.startNodeId,
    required this.endNodeId,
    required this.weight,
    required this.routeName,
    required this.routeColor,
    required this.routeColorName, 
    required this.polylinePoints,
  });
}

// NOTE: The obsolete PathResult and PathStep references have been removed. 
// The actual pathfinding result is now a List<RouteSegment> defined in route_segment.dart.


/// The entire jeepney network graph structure.
class JeepneyGraph {
  final Map<String, Node> nodes; // Map of NodeId to Node object
  final Map<String, List<Edge>> adjacencyList; // Map of NodeId to its outgoing Edges

  JeepneyGraph({
    required this.nodes,
    required this.adjacencyList,
  });
}
