import 'dart:collection';
import 'package:flutter/material.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'graph_models.dart'; 
import 'route_segment_model.dart'; 
// The utility function is imported here.
import 'geo_utils.dart'; // Contains calculateHaversineDistance
import 'pathfinding_config.dart';

// --- COLOR CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E); 

// --- DATA STRUCTURES FOR DIJKSTRA'S ---

/// Data structure used to hold the state during the Dijkstra search.
/// The state is uniquely identified by combining nodeId and currentRouteId.
class SearchState {
  final double cost;
  final String nodeId;
  final String currentRouteId; // The route ID used to arrive at this node
  
  SearchState({
    required this.cost,
    required this.nodeId,
    required this.currentRouteId,
  });
  
  String get key => '$nodeId-$currentRouteId';
}

/// Helper class to store the necessary info to reconstruct the path
class PathHistory {
  final SearchState predecessor;
  final Edge edge;
  
  PathHistory({required this.predecessor, required this.edge});
}


// Custom Priority Queue for SearchState (Min-Heap based on cost)
class PriorityQueue<E> {
  final List<E> _heap = [];
  final Comparator<E> _comparator;

  PriorityQueue(this._comparator);

  bool get isEmpty => _heap.isEmpty; 

  void add(E element) {
    _heap.add(element);
    _bubbleUp(_heap.length - 1);
  }

  E removeFirst() {
    if (_heap.isEmpty) throw StateError("Cannot remove from empty queue");
    _swap(0, _heap.length - 1);
    final E result = _heap.removeLast();
    _bubbleDown(0);
    return result;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (_comparator(_heap[index], _heap[parentIndex]) < 0) {
        _swap(index, parentIndex);
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      final leftChildIndex = 2 * index + 1;
      final rightChildIndex = 2 * index + 2;
      int smallest = index;

      if (leftChildIndex < _heap.length && _comparator(_heap[leftChildIndex], _heap[smallest]) < 0) {
        smallest = leftChildIndex;
      }
      if (rightChildIndex < _heap.length && _comparator(_heap[rightChildIndex], _heap[smallest]) < 0) {
        smallest = rightChildIndex;
      }

      if (smallest != index) {
        _swap(index, smallest);
        index = smallest;
      } else {
        break;
      }
    }
  }

  void _swap(int i, int j) {
    final temp = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = temp;
  }
}
// --- END DATA STRUCTURES ---


// --- ROUTE FINDER CLASS ---
class RouteFinder {
  final JeepneyGraph _graph;
  
  RouteFinder(this._graph);

  /// Finds the shortest path (by time, penalizing transfers) between two GPS coordinates.
  Future<List<RouteSegment>> findPathWithGPS(LatLng start, LatLng end) async {
    // 1. Find the nearest graph nodes for start and end points
    final nearestStartNode = findNearestNode(_graph, start);
    final nearestEndNode = findNearestNode(_graph, end);

    if (nearestStartNode == null || nearestEndNode == null) {
      throw Exception("Could not find nearby stops for both start and end locations (max ${MAX_SNAP_DISTANCE_KM * 1000}m walk).");
    }
    
    // 2. Calculate initial and final walk segments
    // 🎯 FIX: Destructure LatLng objects to pass individual lat/lon arguments
    final initialWalkDistance = calculateHaversineDistance(
        start.latitude, start.longitude, 
        nearestStartNode.position.latitude, nearestStartNode.position.longitude
    );
    final initialWalkDuration = initialWalkDistance * WALK_TIME_PER_KM_MINUTES; 

    final initialWalk = RouteSegment(
      type: SegmentType.WALK,
      description: 'Walk from start to ${nearestStartNode.name}',
      distanceKm: initialWalkDistance,
      durationMin: initialWalkDuration, 
      path: [start, nearestStartNode.position],
      color: Colors.grey,
      routeId: 'WALK_START', // Use a unique ID for initial/final walks
    );
    
    // 🎯 FIX: Destructure LatLng objects to pass individual lat/lon arguments
    final finalWalkDistance = calculateHaversineDistance(
        nearestEndNode.position.latitude, nearestEndNode.position.longitude, 
        end.latitude, end.longitude
    );
    final finalWalkDuration = finalWalkDistance * WALK_TIME_PER_KM_MINUTES;

    // 3. Run the transfer-penalized Dijkstra's algorithm
    final List<RouteSegment> jeepSegments = _runTransferPenalizedDijkstra(
      nearestStartNode.id,
      nearestEndNode.id,
    );

    // 4. If no route is found, check if a direct walk is feasible
    if (jeepSegments.isEmpty) {
        // 🎯 FIX: Destructure LatLng objects to pass individual lat/lon arguments
      final directDistance = calculateHaversineDistance(
            start.latitude, start.longitude, 
            end.latitude, end.longitude
        );
      // NOTE: This fallback logic ensures a walk is shown if no efficient route is found.
      if (directDistance < 1.0) { 
        return [
          RouteSegment(
            type: SegmentType.WALK,
            description: 'Walk directly to destination (No efficient jeep route found)',
            distanceKm: directDistance,
            durationMin: directDistance * WALK_TIME_PER_KM_MINUTES,
            path: [start, end],
            color: Colors.grey,
            routeId: 'WALK_DIRECT',
          )
        ];
      }
      return []; 
    }

    // 5. Build the final route with walk segments
    final finalRoute = <RouteSegment>[];
    finalRoute.add(initialWalk);
    finalRoute.addAll(jeepSegments);
    
    final finalWalk = RouteSegment(
      type: SegmentType.WALK,
      description: 'Walk from ${nearestEndNode.name} to destination',
      distanceKm: finalWalkDistance,
      durationMin: finalWalkDuration,
      path: [nearestEndNode.position, end],
      color: Colors.grey,
      routeId: 'WALK_END',
    );
    finalRoute.add(finalWalk);

    return finalRoute;
  }

  /// Dijkstra's algorithm modified to heavily penalize transfers.
  List<RouteSegment> _runTransferPenalizedDijkstra(String startId, String endId) {
    
    final priorityQueue = PriorityQueue<SearchState>(
      (a, b) => a.cost.compareTo(b.cost),
    );

    // key: SearchState.key (nodeId-routeId), value: min cost to reach this state
    final Map<String, double> minCost = {};
    // key: SearchState.key, value: PathHistory (predecessor state + edge used)
    final Map<String, PathHistory> history = {}; 

    // Initial state: cost 0, start node, 'WALK_INITIAL' route ID
    const initialRouteId = 'WALK_INITIAL'; 
    final initialState = SearchState(cost: 0.0, nodeId: startId, currentRouteId: initialRouteId);
    
    priorityQueue.add(initialState);
    minCost[initialState.key] = 0.0;

    SearchState? finalState;

    while (!priorityQueue.isEmpty) { 
      final currentState = priorityQueue.removeFirst();
      final currentTime = currentState.cost;
      final currentNodeId = currentState.nodeId;
      final currentRouteId = currentState.currentRouteId;
      
      if (currentTime > minCost[currentState.key]!) continue;

      if (currentNodeId == endId) {
        finalState = currentState; 
        break; 
      }

      final edges = _graph.adjacencyList[currentNodeId] ?? [];
      
      for (var edge in edges) {
        double travelTime = edge.time;
        String nextRouteId;
        
        // --- CORRECTED TRANSFER PENALTY LOGIC ---
        if (edge.type == EdgeType.JEEPNEY) { 
          if (currentRouteId != 'WALK_INITIAL' && currentRouteId != edge.routeId) {
            travelTime += EFFECTIVE_TRANSFER_PENALTY_MINUTES; 
          }
          nextRouteId = edge.routeId;
        } else { 
          nextRouteId = currentRouteId; 
        }
        // --- END TRANSFER PENALTY LOGIC ---

        final double newTime = currentTime + travelTime;
        final nextState = SearchState(
            cost: newTime,
            nodeId: edge.endNodeId,
            currentRouteId: nextRouteId,
        );
        final nextStateKey = nextState.key;

        if (newTime < (minCost[nextStateKey] ?? double.infinity)) {
          minCost[nextStateKey] = newTime;
          history[nextStateKey] = PathHistory(predecessor: currentState, edge: edge); 
          priorityQueue.add(nextState);
        }
      }
    }

    if (finalState == null) {
      return []; 
    }

    return _reconstructPath(finalState, history);
  }

  List<RouteSegment> _reconstructPath(
    SearchState finalState,
    Map<String, PathHistory> history,
  ) {
    final List<PathHistory> pathReversed = [];
    String? currentKey = finalState.key;

    while (currentKey != null && history.containsKey(currentKey)) {
        final pathHistory = history[currentKey]!;
        pathReversed.add(pathHistory);
        currentKey = pathHistory.predecessor.key; 
    }
    final List<PathHistory> orderedPath = pathReversed.reversed.toList();

    final List<RouteSegment> mergedSegments = [];
    RouteSegment? currentSegment;

    for (final pathHistory in orderedPath) {
      final edge = pathHistory.edge;
      final startNode = _graph.nodes[edge.startNodeId]!;
      final endNode = _graph.nodes[edge.endNodeId]!; 
      
      final SegmentType segmentType = edge.type == EdgeType.JEEPNEY 
          ? SegmentType.JEEPNEY 
          : SegmentType.WALK; 
      
      final String edgeRouteId = segmentType == SegmentType.JEEPNEY 
          ? edge.routeId 
          : 'WALK_GRAPH';

      if (currentSegment != null && 
          (currentSegment.type != segmentType || 
           currentSegment.routeId != edgeRouteId)) 
      {
        mergedSegments.add(_finalizeSegment(currentSegment, _graph));
        
        if (currentSegment.type == SegmentType.JEEPNEY && 
            segmentType == SegmentType.JEEPNEY) {
            
            mergedSegments.add(
              RouteSegment(
                type: SegmentType.TRANSFER,
                description: 'Transfer to ${edge.routeId} at ${startNode.name}',
                distanceKm: 0.0,
                durationMin: REAL_TRANSFER_WAIT_TIME_MINUTES, 
                path: [startNode.position],
                color: kPrimaryColor, 
                routeId: edge.routeId,
              )
            );
        }
        currentSegment = null;
      }

      if (currentSegment == null) {
        currentSegment = RouteSegment(
          type: segmentType,
          description: 'Starting segment...',
          distanceKm: edge.distance, 
          durationMin: edge.time, 
          path: edge.polylinePoints.toList(),
          color: edge.routeColor,
          routeId: edgeRouteId,
        );
      } else {
        final newDistance = currentSegment.distanceKm + edge.distance;
        final newDuration = currentSegment.durationMin + edge.time;
        
        final updatedPath = List<LatLng>.from(currentSegment.path); 
        final edgePoints = edge.polylinePoints;
        
        if (edgePoints.isNotEmpty && 
            updatedPath.last != edgePoints.last) {
           updatedPath.add(edgePoints.last);
        }
        
        currentSegment = currentSegment.copyWith(
          distanceKm: newDistance,
          durationMin: newDuration,
          path: updatedPath,
        );
      }
    }

    if (currentSegment != null) {
      mergedSegments.add(_finalizeSegment(currentSegment, _graph));
    }

    return mergedSegments;
  }
  
  RouteSegment _finalizeSegment(RouteSegment segment, JeepneyGraph graph) {
    String description;
    
    final endNodePos = segment.path.isNotEmpty ? segment.path.last : segment.path.first;
    
    // Fallback search to find the node name
    final endNode = graph.nodes.values.firstWhere(
        (node) => node.position == endNodePos,
        orElse: () => Node(id: '', name: 'destination', position: endNodePos)
    );
    
    final endNodeName = endNode.name;

    if (segment.type == SegmentType.JEEPNEY) {
      final routeName = graph.getRouteName(segment.routeId!);
      description = 'Ride Jeepney Route ${routeName} until ${endNodeName}';
    } else {
      description = 'Walk for ${segment.durationMin.toStringAsFixed(1)} minutes to ${endNodeName}';
    }
    
    return segment.copyWith(description: description);
  }
}

// Utility function to find the nearest graph node to a GPS point.
Node? findNearestNode(JeepneyGraph graph, LatLng point) {
  Node? nearest;
  double minDistance = double.infinity;

  for (var node in graph.nodes.values) {
    // 🎯 FIX: Destructure LatLng objects to pass individual lat/lon arguments
    final dist = calculateHaversineDistance(
        point.latitude, point.longitude, 
        node.position.latitude, node.position.longitude
    ); 
    if (dist < minDistance) {
      minDistance = dist;
      nearest = node;
    }
  }

  if (minDistance > MAX_SNAP_DISTANCE_KM) {
    return null;
  }

  return nearest;
}
