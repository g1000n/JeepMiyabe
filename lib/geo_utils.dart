// File: geo_utils.dart

import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Assuming these files exist and define necessary models/constants
import 'graph_models.dart'; 
import 'pathfinding_config.dart'; // Imports JEEPNEY_AVG_SPEED_KM_PER_MIN, MAX_SNAP_DISTANCE_KM, WALK_TIME_PER_KM_MINUTES

// --------------------------------------------------------------------------
// --- CORE HAVERSINE DISTANCE CALCULATION (Required Function) ---
// --------------------------------------------------------------------------

/// Helper function to convert degrees to radians.
double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180;
}

/// Calculates the distance between two LatLng points using the Haversine formula.
///
/// **Returns:** Distance in **kilometers (km)**.
double calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);

  final double lat1Rad = _degreesToRadians(lat1);
  final double lat2Rad = _degreesToRadians(lat2);

  // Haversine formula calculation
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1Rad) * math.cos(lat2Rad);
  
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c; // Distance in kilometers
}


// --------------------------------------------------------------------------
// --- WEIGHT/COST UTILITIES FOR PATHFINDING SERVICE ---
// --------------------------------------------------------------------------

/// Calculates the total physical distance (in km) along a polyline path.
double calculatePolylineDistance(List<LatLng> points) {
  double totalDistanceKm = 0.0;
  
  if (points.length < 2) {
    return 0.0;
  }

  // Sum the distance between every sequential point in the list
  for (int i = 0; i < points.length - 1; i++) {
    totalDistanceKm += calculateHaversineDistance(
      points[i].latitude, points[i].longitude, 
      points[i + 1].latitude, points[i + 1].longitude
    ); 
  }
  
  return totalDistanceKm; 
}

/// Calculates the time (in minutes) required to travel the distance (km) of a polyline.
/// This is used as the time cost (weight) for the graph edges.
/// Time (min) = Distance (km) / Speed (km/min)
double calculateJeepneyWeight(List<LatLng> polylinePoints) {
  final distanceKm = calculatePolylineDistance(polylinePoints); 
  
  // Assumes JEEPNEY_AVG_SPEED_KM_PER_MIN is available via import
  return distanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN; 
}

/// Calculates the time (in minutes) required for walking the distance (km).
/// Time (min) = Distance (km) * TimePerKm (min/km)
double calculateWalkWeight(double distanceKm) {
  // Correctly use WALK_TIME_PER_KM_MINUTES from the config
  return distanceKm * WALK_TIME_PER_KM_MINUTES;
}


// --------------------------------------------------------------------------
// --- NEAREST NODE SEARCH (CRITICAL FOR ROUTE FINDER) ---
// --------------------------------------------------------------------------

/// Finds the nearest graph node (stop) to a GPS point within the max connection radius.
Node? findNearestNode(JeepneyGraph graph, LatLng point) {
  Node? nearest;
  double minDistance = double.infinity;
  
  // Use the constant MAX_SNAP_DISTANCE_KM from pathfinding_config.dart
  const maxSearchRadiusKm = MAX_SNAP_DISTANCE_KM; 

  for (var node in graph.nodes.values) {
    // Calculate Haversine distance
    final dist = calculateHaversineDistance(
      point.latitude, point.longitude, 
      node.position.latitude, node.position.longitude
    ); 
    
    if (dist < minDistance) {
      minDistance = dist;
      nearest = node;
    }
  }

  // Only return the nearest node if it's within the maximum snapping radius
  if (nearest != null && minDistance > maxSearchRadiusKm) {
    return null; // Point is too far from any stop
  }

  return nearest;
}


// --------------------------------------------------------------------------
// --- CAMERA AND MAP UTILITIES 🗺️ ---
// --------------------------------------------------------------------------

/// Calculates the LatLngBounds that encompasses all given points.
/// This is used by the RouteController to frame the map camera onto the final route.
LatLngBounds calculateBounds(List<LatLng> points) {
  if (points.isEmpty) {
    // Return a default bound centered near Angeles City if no points are provided
    const LatLng defaultCenter = LatLng(15.1466, 120.5750); 
    return LatLngBounds(northeast: defaultCenter, southwest: defaultCenter);
  }
  
  // Initialize min/max with the first point
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLon = points.first.longitude;
  double maxLon = points.first.longitude;

  // Iterate over all points to find the true min/max
  for (var point in points) {
    minLat = math.min(minLat, point.latitude);
    maxLat = math.max(maxLat, point.latitude);
    minLon = math.min(minLon, point.longitude);
    maxLon = math.max(maxLon, point.longitude);
  }

  return LatLngBounds(
    southwest: LatLng(minLat, minLon), 
    northeast: LatLng(maxLat, maxLon)
  );
}


// --------------------------------------------------------------------------
// --- POLYLINE STAGGERING LOGIC (Simplified/Cleaned) ---
// --------------------------------------------------------------------------

/// Calculates offset points for polylines to prevent overlapping visually on the map.
List<LatLng> calculateStaggeredPoints(
    List<LatLng> points, int index, int totalSegments) {
  
  if (points.length < 2) return points;

  final LatLng start = points.first;
  final LatLng end = points.last;

  const double baseOffsetKm = 0.005; 
  
  // Determine the signed offset distance (alternating positive/negative)
  final double signedOffsetKm = 
      (index == 0) ? 0.0 : baseOffsetKm * (index.isOdd ? (index + 1) ~/ 2 : -index ~/ 2);

  // Convert kilometer offset to degrees (approximate)
  final double offsetDegrees = signedOffsetKm / 111.0; 

  // Convert start/end points to radians for bearing calculation
  final double lat1 = _degreesToRadians(start.latitude);
  final double lon1 = _degreesToRadians(start.longitude);
  final double lat2 = _degreesToRadians(end.latitude);
  final double lon2 = _degreesToRadians(end.longitude);

  final double dLon = lon2 - lon1;
  
  // Calculate the bearing (direction) of the line segment
  final double bearingRad = math.atan2(
    math.sin(dLon) * math.cos(lat2),
    math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon),
  );

  // Calculate the perpendicular bearing (90 degrees to the line segment)
  final double perpendicularRad = bearingRad + math.pi / 2.0;

  // Apply the offset in the perpendicular direction
  final LatLng staggeredStart = LatLng(
    start.latitude + offsetDegrees * math.sin(perpendicularRad),
    start.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  final LatLng staggeredEnd = LatLng(
    end.latitude + offsetDegrees * math.sin(perpendicularRad),
    end.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  // Note: For a true staggered polyline, the full list of points should be offset, 
  // but this implementation focuses on offsetting just the start/end for simplicity.
  return [staggeredStart, staggeredEnd];
}
