// File: route_segment_converter.dart

// ... (other imports) ...
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'route_segment_model.dart' as model; 
import 'graph_models.dart';
// ... (graph_models.dart, etc.) ...

// --------------------------------------------------------------------------
// --- CORE CONVERSION LOGIC ---
// --------------------------------------------------------------------------


// 🎯 NOTE: Assuming you have the import fixed: List<model.RouteSegment>
List<model.RouteSegment> convertEdgesToSegments(List<Edge> pathEdges) {
  final List<model.RouteSegment> segments = [];
  
  // Check 1: If the list is empty, return the empty list immediately.
  if (pathEdges.isEmpty) return segments;

  // --- Consolidation Logic ---
  Edge currentEdge = pathEdges.first;
  List<LatLng> currentPolyline = [...currentEdge.polylinePoints];
  double currentDistance = currentEdge.distance;
  double currentTime = currentEdge.time;

  for (int i = 1; i < pathEdges.length; i++) {
    final nextEdge = pathEdges[i];

    final bool isMergeable = 
      (nextEdge.type == currentEdge.type) && 
      (nextEdge.routeId == currentEdge.routeId);

    if (isMergeable) {
      // Merge logic: accumulate time, distance, and polyline points
      currentDistance += nextEdge.distance;
      currentTime += nextEdge.time;
      currentPolyline.addAll(nextEdge.polylinePoints.sublist(1));

    } else {
      // Finalize the current segment and start a new one
      segments.add(_createSegment(currentEdge, currentDistance, currentTime, currentPolyline));

      // Reset state for the next segment
      currentEdge = nextEdge;
      currentPolyline = [...currentEdge.polylinePoints];
      currentDistance = currentEdge.distance;
      currentTime = currentEdge.time;
    }
  }

  // 🎯 FIX: The final return statement. This ensures the function always returns a value.
  // Add the very last consolidated segment.
  segments.add(_createSegment(currentEdge, currentDistance, currentTime, currentPolyline));
  
  return segments;
}

// 🎯 NOTE: Ensure _createSegment returns model.RouteSegment
// Part of the file: route_segment_converter.dart

// 🎯 NOTE: Ensure _createSegment returns model.RouteSegment
model.RouteSegment _createSegment(
 Edge edge, 
 double totalDistanceKm, 
 double totalDurationMin, 
 List<LatLng> polyline
) {
    String instruction;
    model.SegmentType segmentType;
    
    // Format time and distance for instructions
    final timeStr = totalDurationMin.toStringAsFixed(0);
    final distStr = totalDistanceKm.toStringAsFixed(2);
    
    if (edge.type == EdgeType.WALK) {
        // This is a Walk segment (first mile, last mile, or transfer walk)
        segmentType = model.SegmentType.WALK;
        // Instruction indicates movement from the start of the walk to the end node
        instruction = 'Walk $distStr km (${timeStr} min) towards ${edge.endNodeName}.';

    } else if (edge.type == EdgeType.JEEPNEY) {
        // This is a Jeepney ride segment
        segmentType = model.SegmentType.JEEPNEY;
        // Instruction specifies the route name and ID
        instruction = 'Take Jeepney ${edge.routeName} (Route ${edge.routeId}) for $distStr km (approx. ${timeStr} min), from ${edge.startNodeName} to ${edge.endNodeName}.';

    } else {
        // Default or Transfer (should be minimal in a fully processed path)
        segmentType = model.SegmentType.TRANSFER; 
        instruction = 'Transfer or Unidentified action (Total Time: ${timeStr} min).';
    }

    // Must return the prefixed model type and fill all required parameters:
    return model.RouteSegment(
        type: segmentType,
        description: instruction, // Corresponds to the instruction string created above
        path: polyline,
        color: edge.routeColor,
        distanceKm: totalDistanceKm,
        durationMin: totalDurationMin,
        routeId: edge.routeId, // Null for WALK segments, set for JEEPNEY
    );
}
