import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Local Project Files
import 'graph_models.dart';
import 'jeepney_network_data.dart';
import 'pathfinding_config.dart';
import 'geo_utils.dart';
import 'route_segment.dart'; // Correctly importing the required data model

// --- 1. INTERNAL DATA STRUCTURES ---

/// Holds the raw result of the Dijkstra's search within the jeepney network.
/// This structure is strictly for the internal graph algorithm result.
class PathResult {
  final List<Edge> pathEdges; // The sequence of edges representing the network path
  final double totalWeight; // Total time in minutes for the network path

  PathResult({
    required this.pathEdges,
    required this.totalWeight,
  });
}

// --- 2. ROUTING ALGORITHM CLASS ---

class RouteFinder {
  
  /// Helper to find the nearest network Node to a given LatLng point (used for GPS snap).
  Node? _findNearestNode(LatLng point) {
    double minDistance = double.infinity;
    Node? nearestNode;
    
    // Check all established nodes in the network
    allNodes.forEach((id, node) {
      // Calculate distance in KM
      final distance = calculateDistance(point, node.position); 
      
      // Only consider nodes within 500 meters (0.5 km) for snapping
      if (distance < 0.5 && distance < minDistance) { 
        minDistance = distance;
        nearestNode = node;
      }
    });
    return nearestNode;
  }

  /// Core Dijkstra's implementation to find the shortest path between two network nodes.
  /// The cost function includes transfer penalties.
  PathResult _runDijkstra(Node start, Node end) {
    final graph = jeepneyNetwork; 
    final distances = <String, double>{};
    final previousEdges = <String, Edge>{}; // Stores the edge used to reach the key node
    
    final priorityQueue = PriorityQueue<MapEntry<String, double>>((a, b) => a.value.compareTo(b.value));
    
    // Initialization
    graph.nodes.keys.forEach((nodeId) {
      distances[nodeId] = double.infinity;
    });
    
    distances[start.id] = 0.0;
    priorityQueue.add(MapEntry(start.id, 0.0));
    
    while (priorityQueue.isNotEmpty) {
      final currentEntry = priorityQueue.removeFirst();
      final uId = currentEntry.key;
      final currentDistance = currentEntry.value;
      
      if (uId == end.id) break; 
      if (currentDistance > (distances[uId] ?? double.infinity)) continue; 

      // Explore neighbors
      for (final edge in graph.adjacencyList[uId] ?? []) {
        final vId = edge.endNodeId;
        
        // --- COST CALCULATION (TIME) ---
        final travelDistanceKm = edge.weight; 
        final travelTimeMinutes = travelDistanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN;
        double cost = travelTimeMinutes;
        
        // Transfer Penalty: Check if the routeName changes from the previous edge
        final previousEdge = previousEdges[uId];
        if (previousEdge != null && previousEdge.routeName != edge.routeName) {
          cost += TRANSFER_WAIT_PENALTY_MINUTES;
        }

        final newDistance = currentDistance + cost;
        
        // Relaxation
        if (newDistance < (distances[vId] ?? double.infinity)) {
          distances[vId] = newDistance;
          previousEdges[vId] = edge; 
          priorityQueue.add(MapEntry(vId, newDistance));
        }
      }
    }
    
    // --- RECONSTRUCT PATH EDGES ---
    
    if (distances[end.id] == double.infinity) {
      return PathResult(pathEdges: [], totalWeight: -1.0);
    }
    
    final pathEdges = <Edge>[];
    String? currentId = end.id;

    // Trace the path backwards
    while (currentId != null && currentId != start.id) {
      final edge = previousEdges[currentId];
      if (edge == null) break;
      pathEdges.insert(0, edge); 
      currentId = edge.startNodeId;
    }
    
    return PathResult(
      pathEdges: pathEdges,
      totalWeight: distances[end.id] ?? 0.0,
    );
  }

  /// The main public function called by MapScreen to handle GPS-to-Network routing.
  /// It returns a list of consolidated RouteSegments (Walk, Jeepney, Transfer).
  Future<List<RouteSegment>> findPathWithGPS(LatLng startGps, LatLng endGps) async { 
    
    Node? nearestStartNode = _findNearestNode(startGps);
    if (nearestStartNode == null) {
      throw Exception("Start: No jeepney stop found nearby (must be within 500m).");
    }

    Node? nearestEndNode = _findNearestNode(endGps);
    if (nearestEndNode == null) {
      throw Exception("End: No jeepney stop found nearby (must be within 500m).");
    }
    
    final networkRouteResult = _runDijkstra(nearestStartNode, nearestEndNode);
    // Return empty list if network route failed
    if (networkRouteResult.totalWeight < 0 || networkRouteResult.pathEdges.isEmpty) {
      return [];
    }
    
    final List<Edge> allPathEdges = networkRouteResult.pathEdges;
    final List<RouteSegment> finalSegments = [];
    
    // 1. Add the First Mile (WALK) segment
    final firstMileDistanceKm = calculateDistance(startGps, nearestStartNode.position);
    final firstMileTime = firstMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (firstMileDistanceKm > 0.05) { // Only add if distance > 50 meters
      finalSegments.add(
        RouteSegment(
          type: SegmentType.WALK,
          description: 'Walk to ${nearestStartNode.name} (Stop)',
          path: [startGps, nearestStartNode.position],
          color: Colors.grey.shade500,
          distanceKm: firstMileDistanceKm,
          durationMin: firstMileTime,
        )
      );
    }

    // 2. Group Network Edges into JEEPNEY/TRANSFER Route Segments
    if (allPathEdges.isNotEmpty) {
      
      Edge currentEdge = allPathEdges.first;
      List<LatLng> currentPath = [];
      double currentDistanceKm = 0.0;
      double currentDurationMin = 0.0;
      String currentStartNodeName = allNodes[currentEdge.startNodeId]?.name ?? 'Unknown Stop';
      
      for (int i = 0; i < allPathEdges.length; i++) {
        final nextEdge = allPathEdges[i];
        final isTransfer = nextEdge.routeName != currentEdge.routeName;
        final isLast = i == allPathEdges.length - 1;

        // Check for Transfer or End of Path to finalize the current segment
        if (isTransfer) {
          // A. Finalize the previous JEEPNEY segment
          finalSegments.add(
            RouteSegment(
              type: SegmentType.JEEPNEY,
              description: 'Take ${currentEdge.routeName} from $currentStartNodeName to ${allNodes[nextEdge.startNodeId]?.name ?? 'Stop'}',
              path: currentPath,
              color: currentEdge.routeColor,
              distanceKm: currentDistanceKm,
              durationMin: currentDurationMin,
            ),
          );
          
          // B. Add TRANSFER segment
          final transferNodeName = allNodes[nextEdge.startNodeId]?.name ?? 'Stop';
          finalSegments.add(
            RouteSegment(
              type: SegmentType.TRANSFER,
              description: 'Transfer to ${nextEdge.routeName} at $transferNodeName',
              // Path is just the transfer point (no actual line drawn for transfer wait)
              path: [allNodes[nextEdge.startNodeId]!.position], 
              color: Colors.deepOrange,
              distanceKm: 0.0,
              durationMin: TRANSFER_WAIT_PENALTY_MINUTES,
            ),
          );
          
          // C. Reset for the new JEEPNEY segment
          currentEdge = nextEdge;
          currentStartNodeName = allNodes[nextEdge.startNodeId]?.name ?? 'Stop';
          currentPath = [];
          currentDistanceKm = 0.0;
          currentDurationMin = 0.0;
        }

        // Accumulate the current edge's data
        if (currentPath.isEmpty) {
          // Add all points for the very first edge in the segment
          currentPath.addAll(nextEdge.polylinePoints);
        } else {
          // Only add points from the second index to avoid duplicating the intermediate node
          currentPath.addAll(nextEdge.polylinePoints.sublist(1)); 
        }

        currentDistanceKm += nextEdge.weight;
        currentDurationMin += nextEdge.weight / JEEPNEY_AVG_SPEED_KM_PER_MIN;

        // Final Segment: If this is the last edge, finalize the JEEPNEY segment
        if (isLast) {
          finalSegments.add(
            RouteSegment(
              type: SegmentType.JEEPNEY,
              description: 'Take ${currentEdge.routeName} from $currentStartNodeName to ${allNodes[nextEdge.endNodeId]?.name ?? 'Destination Stop'}',
              path: currentPath,
              color: currentEdge.routeColor,
              distanceKm: currentDistanceKm,
              durationMin: currentDurationMin,
            ),
          );
        }
        
        // Update the current edge for the next loop's transfer check
        if (!isTransfer) {
          currentEdge = nextEdge;
        }
      }
    }


    // 3. Add the Last Mile (WALK) segment
    final lastMileDistanceKm = calculateDistance(nearestEndNode.position, endGps);
    final lastMileTime = lastMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (lastMileDistanceKm > 0.05) { // Only add if distance > 50 meters
      finalSegments.add(
        RouteSegment(
          type: SegmentType.WALK,
          description: 'Walk from ${nearestEndNode.name} to your Destination',
          path: [nearestEndNode.position, endGps],
          color: Colors.grey.shade500,
          distanceKm: lastMileDistanceKm,
          durationMin: lastMileTime,
        )
      );
    }
    
    return finalSegments;
  }
}
