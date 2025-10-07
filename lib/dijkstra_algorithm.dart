import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'graph_models.dart';
import 'jeepney_network_data.dart';
import 'pathfinding_config.dart';
import 'geo_utils.dart';
import 'route_finder.dart';

// this is not needed anymore

// --- 1. PATH RESULT DATA STRUCTURE ---

/// The final computed path returned to the UI.
class PathResult {
  /// The actual path drawn on the map (Polyline-level segments).
  final List<Edge> pathEdges; 
  
  /// Simplified, step-by-step instructions for the user.
  final List<PathStep> instructions; 
  
  /// Total cost of the trip (in minutes).
  final double totalWeight;

  PathResult({
    required this.pathEdges,
    required this.instructions,
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
      final distance = calculateDistance(point, node.position); // distance in KM
      
      // Only consider nodes within 500 meters (0.5 km) for snapping
      if (distance < 0.5 && distance < minDistance) { 
        minDistance = distance;
        nearestNode = node;
      }
    });
    return nearestNode;
  }

  /// Core Dijkstra's implementation to find the shortest path between two network nodes.
  PathResult _runDijkstra(Node start, Node end) {
    // This assumes jeepneyNetwork is an instance of JeepneyGraph (from graph_models.dart)
    final graph = jeepneyNetwork; 
    final distances = <String, double>{};
    final previousEdges = <String, Edge>{}; // Stores the optimal incoming edge for path reconstruction
    
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
        
        // --- COST CALCULATION ---
        
        // Edge weight is distance in km
        final travelDistanceKm = edge.weight; 
        final travelTimeMinutes = travelDistanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN;
        double cost = travelTimeMinutes;
        
        // Transfer Penalty: Check if the route name changes from the edge leading into uId
        final previousEdge = previousEdges[uId];
        if (previousEdge != null && previousEdge.routeName != edge.routeName) {
          cost += TRANSFER_WAIT_PENALTY_MINUTES;
        }

        final newDistance = currentDistance + cost;
        
        // Relaxation
        if (newDistance < (distances[vId] ?? double.infinity)) {
          distances[vId] = newDistance;
          previousEdges[vId] = edge; // Store the edge that leads to vId
          priorityQueue.add(MapEntry(vId, newDistance));
        }
      }
    }
    
    // --- RECONSTRUCT PATH AND INSTRUCTIONS ---
    
    if (distances[end.id] == double.infinity) {
      return PathResult(
        pathEdges: [],
        instructions: [
          PathStep(
            mode: 'ERROR', 
            routeName: 'No Route Found', 
            startNodeName: 'N/A', 
            endNodeName: 'N/A', 
            distance: 0.0, 
            time: 0.0, 
            routeColor: Colors.red
          )
        ],
        totalWeight: -1.0, // Use -1.0 to signal failure
      );
    }
    
    final pathEdges = <Edge>[];
    final pathSteps = <PathStep>[];
    String? currentId = end.id;

    // Trace the path backwards
    while (currentId != null && currentId != start.id) {
      final edge = previousEdges[currentId];
      if (edge == null) break;
      pathEdges.insert(0, edge); 
      currentId = edge.startNodeId;
    }
    
    // Convert Edges to Instructions (PathSteps) by merging sequential edges on the same route
    if (pathEdges.isNotEmpty) {
      // Start with the properties of the first edge
      Edge? currentSegmentEdge = pathEdges.first;
      String currentStartId = currentSegmentEdge.startNodeId;
      double segmentDistance = 0.0;
      double segmentTime = 0.0;
      int i = 0;

      // Reconstruct instructions by consolidating edges with the same routeName
      while (i < pathEdges.length) {
        final edge = pathEdges[i];
        final edgeTime = edge.weight / JEEPNEY_AVG_SPEED_KM_PER_MIN;
        
        // Check for transfer by comparing the current edge's routeName to the stored segment's routeName
        final isTransfer = currentSegmentEdge != null && edge.routeName != currentSegmentEdge.routeName;
        final isLast = i == pathEdges.length - 1;
        
        // If this is a transfer, or the end of the path
        if (isTransfer || isLast) {
          
          // If it's the last edge and not a transfer, accumulate it first
          if (isLast && !isTransfer) {
            segmentDistance += edge.weight;
            segmentTime += edgeTime;
          }
          
          // --- 1. Finalize the PREVIOUS Segment (Jeepney Ride) ---
          if (currentSegmentEdge != null && segmentDistance > 0) {
            // The segment ended at the start of the current edge (if transfer) or the end of the current edge (if last)
            final String segmentEndId = isTransfer ? edge.startNodeId : edge.endNodeId;
            
            pathSteps.add(
              PathStep(
                mode: 'JEEPNEY',
                routeName: currentSegmentEdge.routeName,
                startNodeName: graph.nodes[currentStartId]!.name,
                endNodeName: graph.nodes[segmentEndId]!.name,
                distance: segmentDistance,
                time: segmentTime, 
                routeColor: currentSegmentEdge.routeColor,
              ),
            );
          }
          
          // --- 2. Add TRANSFER Step (if applicable) ---
          if (isTransfer) {
            // We only add a transfer if we are not at the beginning of the path (i > 0)
            if (i > 0) {
              pathSteps.add(
                PathStep(
                  mode: 'TRANSFER',
                  routeName: 'Transfer to ${edge.routeName}',
                  startNodeName: graph.nodes[edge.startNodeId]!.name,
                  endNodeName: graph.nodes[edge.startNodeId]!.name,
                  distance: 0.0,
                  time: TRANSFER_WAIT_PENALTY_MINUTES,
                  routeColor: Colors.deepOrange, // Use distinct color for transfer
                  isTransfer: true,
                ),
              );
            }

            // --- 3. Start the NEW Segment from the current edge ---
            currentSegmentEdge = edge;
            currentStartId = edge.startNodeId;
            // Since this edge belongs to the NEW segment, we initialize distance/time
            segmentDistance = edge.weight; // Start new segment accumulation
            segmentTime = edgeTime; 
          }

        } else {
          // No transfer, not the last edge: continue accumulating
          segmentDistance += edge.weight;
          segmentTime += edgeTime;
          // Track the latest edge for segment color/name tracking
          currentSegmentEdge = edge; 
        }
        
        i++;
      }
    }

    return PathResult(
      pathEdges: pathEdges,
      instructions: pathSteps,
      totalWeight: distances[end.id] ?? 0.0,
    );
  }

  /// The main public function called by MapScreen to handle GPS-to-Network routing.
  Future<PathResult> findPathWithGPS(LatLng startGps, LatLng endGps) async { 
    
    Node? nearestStartNode = _findNearestNode(startGps);
    if (nearestStartNode == null) {
      throw Exception("Start: No jeepney stop found nearby. Try tapping closer to a main road.");
    }

    Node? nearestEndNode = _findNearestNode(endGps);
    if (nearestEndNode == null) {
      throw Exception("End: No jeepney stop found nearby. Try tapping closer to your destination.");
    }
    
    final routeResult = _runDijkstra(nearestStartNode, nearestEndNode);
    // If the path failed, return the error result from Dijkstra.
    if (routeResult.totalWeight < 0) return routeResult;
    
    final List<PathStep> finalInstructions = List.from(routeResult.instructions);
    // Calculate total weight to be updated
    double finalTotalWeight = routeResult.totalWeight;
    
    // Step 4: Add the First Mile (WALK) segment
    final firstMileDistanceKm = calculateDistance(startGps, nearestStartNode.position);
    final firstMileTime = firstMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (firstMileDistanceKm > 0.05) { // Only add if distance > 50 meters
      finalTotalWeight += firstMileTime; // Add walk time to total weight
      
      // Add Walk Edge to pathEdges (at the beginning)
      routeResult.pathEdges.insert(
        0, 
        Edge(
          startNodeId: 'GPS_START', 
          endNodeId: nearestStartNode.id, 
          weight: firstMileDistanceKm, 
          routeName: 'WALK', 
          routeColor: Colors.grey.shade500,
          routeColorName: 'Walk', // FIX: Added missing required parameter
          polylinePoints: [startGps, nearestStartNode.position],
        )
      );
      // Add Walk Instruction to finalInstructions (at the beginning)
      finalInstructions.insert(
        0, 
        PathStep(
          mode: 'WALK',
          routeName: 'WALK',
          startNodeName: 'Your Starting Point',
          endNodeName: nearestStartNode.name,
          distance: firstMileDistanceKm,
          time: firstMileTime,
          routeColor: Colors.grey,
        )
      );
    }

    // Step 5: Add the Last Mile (WALK) segment
    final lastMileDistanceKm = calculateDistance(nearestEndNode.position, endGps);
    final lastMileTime = lastMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (lastMileDistanceKm > 0.05) { // Only add if distance > 50 meters
      finalTotalWeight += lastMileTime; // Add walk time to total weight

      // Add Walk Edge to pathEdges (at the end)
      routeResult.pathEdges.add(
        Edge(
          startNodeId: nearestEndNode.id, 
          endNodeId: 'GPS_END', 
          weight: lastMileDistanceKm, 
          routeName: 'WALK', 
          routeColor: Colors.grey.shade500,
          routeColorName: 'Walk', // FIX: Added missing required parameter
          polylinePoints: [nearestEndNode.position, endGps],
        )
      );
      // Add Walk Instruction to finalInstructions (at the end)
      finalInstructions.add(
        PathStep(
          mode: 'WALK',
          routeName: 'WALK',
          startNodeName: nearestEndNode.name,
          endNodeName: 'Your Destination',
          distance: lastMileDistanceKm,
          time: lastMileTime,
          routeColor: Colors.grey,
        )
      );
    }
    
    // Return a new PathResult with the combined instructions and weight
    return PathResult(
        pathEdges: routeResult.pathEdges, 
        instructions: finalInstructions, 
        totalWeight: finalTotalWeight,
    );
  }
}
