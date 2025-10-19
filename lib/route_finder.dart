import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'graph_models.dart';
import 'jeepney_network_data.dart';
import 'pathfinding_config.dart';
import 'geo_utils.dart';
import 'route_segment.dart';

class PathResult {
  final List<Edge> pathEdges;
  final double totalWeight;

  PathResult({
    required this.pathEdges,
    required this.totalWeight,
  });
}

class RouteFinder {
  Node? _findNearestNode(LatLng point) {
    double minDistance = double.infinity;
    Node? nearestNode;

    allNodes.forEach((id, node) {
      final distance = calculateDistance(point, node.position);

      if (distance < 0.5 && distance < minDistance) {
        minDistance = distance;
        nearestNode = node;
      }
    });
    return nearestNode;
  }

  PathResult _runDijkstra(Node start, Node end) {
    final graph = jeepneyNetwork;
    final distances = <String, double>{};
    final previousEdges = <String, Edge>{};

    final priorityQueue =
        PriorityQueue<MapEntry<String, double>>((a, b) => a.value.compareTo(b.value));

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

      for (final edge in graph.adjacencyList[uId] ?? []) {
        final vId = edge.endNodeId;

        final travelDistanceKm = edge.weight;
        final travelTimeMinutes = travelDistanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN;
        double cost = travelTimeMinutes;

        final previousEdge = previousEdges[uId];
        if (previousEdge != null && previousEdge.routeName != edge.routeName) {
          cost += TRANSFER_WAIT_PENALTY_MINUTES;
        }

        final newDistance = currentDistance + cost;

        if (newDistance < (distances[vId] ?? double.infinity)) {
          distances[vId] = newDistance;
          previousEdges[vId] = edge;
          priorityQueue.add(MapEntry(vId, newDistance));
        }
      }
    }

    if (distances[end.id] == double.infinity) {
      return PathResult(pathEdges: [], totalWeight: -1.0);
    }

    final pathEdges = <Edge>[];
    String? currentId = end.id;

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

  Future<List<RouteSegment>> findPathWithGPS(
      LatLng startGps, LatLng endGps) async {
    Node? nearestStartNode = _findNearestNode(startGps);
    if (nearestStartNode == null) {
      throw Exception("Start: No jeepney stop found nearby (must be within 500m).");
    }

    Node? nearestEndNode = _findNearestNode(endGps);
    if (nearestEndNode == null) {
      throw Exception("End: No jeepney stop found nearby (must be within 500m).");
    }

    final networkRouteResult = _runDijkstra(nearestStartNode, nearestEndNode);
    if (networkRouteResult.totalWeight < 0 ||
        networkRouteResult.pathEdges.isEmpty) {
      return [];
    }

    final List<Edge> allPathEdges = networkRouteResult.pathEdges;
    final List<RouteSegment> finalSegments = [];

    // 1. Add the First Mile (walk) segment
    final firstMileDistanceKm = calculateDistance(startGps, nearestStartNode.position);
    final firstMileTime = firstMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (firstMileDistanceKm > 0.05) {
      finalSegments.add(
        RouteSegment(
          type: SegmentType.WALK,
          description: 'Walk to ${nearestStartNode.name} (Stop)',
          path: [startGps, nearestStartNode.position],
          color: Colors.grey.shade500,
          distanceKm: firstMileDistanceKm,
          durationMin: firstMileTime,
        ),
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

        // 💡 NEW LOGIC: Calculate the straight-line distance for the current network edge
        final Node edgeStartNode = allNodes[nextEdge.startNodeId]!;
        final Node edgeEndNode = allNodes[nextEdge.endNodeId]!;
        final double edgeDistanceKm = calculateDistance(
          edgeStartNode.position, 
          edgeEndNode.position
        );


        if (isTransfer) {
          // A. Finalize the previous JEEPNEY segment
          finalSegments.add(
            RouteSegment(
              type: SegmentType.JEEPNEY,
              description:
                  'Take ${currentEdge.routeName} from $currentStartNodeName to ${allNodes[nextEdge.startNodeId]?.name ?? 'Stop'}',
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
          currentPath.addAll(nextEdge.polylinePoints);
        } else {
          currentPath.addAll(nextEdge.polylinePoints.sublist(1));
        }

        //FIX 1: Accumulate Distance using the calculated/stored distance in km.
        currentDistanceKm += edgeDistanceKm; 
        
        // FIX 2: Accumulate Duration using the edge's weight (time in minutes).
        currentDurationMin += nextEdge.weight; 

        // Final Segment: If this is the last edge, finalize the JEEPNEY segment
        if (isLast) {
          finalSegments.add(
            RouteSegment(
              type: SegmentType.JEEPNEY,
              description:
                  'Take ${currentEdge.routeName} from $currentStartNodeName to ${allNodes[nextEdge.endNodeId]?.name ?? 'Destination Stop'}',
              path: currentPath,
              color: currentEdge.routeColor,
              distanceKm: currentDistanceKm,
              durationMin: currentDurationMin,
            ),
          );
        }

        if (!isTransfer) {
          currentEdge = nextEdge;
        }
      }
    }

    // 3. Add the Last Mile (WALK) segment
    final lastMileDistanceKm = calculateDistance(nearestEndNode.position, endGps);
    final lastMileTime = lastMileDistanceKm * WALK_TIME_PER_KM_MINUTES;

    if (lastMileDistanceKm > 0.05) {
      finalSegments.add(
        RouteSegment(
          type: SegmentType.WALK,
          description: 'Walk from ${nearestEndNode.name} to your Destination',
          path: [nearestEndNode.position, endGps],
          color: Colors.grey.shade500,
          distanceKm: lastMileDistanceKm,
          durationMin: lastMileTime,
        ),
      );
    }

    return finalSegments;
}
}
