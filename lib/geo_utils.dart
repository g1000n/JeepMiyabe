import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'pathfinding_config.dart'; // Import constant JEEPNEY_AVG_SPEED_KM_PER_MIN

/// Calculates the distance between two LatLng points using the Haversine formula (km).
double calculateDistance(LatLng point1, LatLng point2) {
  const double earthRadiusKm = 6371.0;

  final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
  final double dLon = _degreesToRadians(point2.longitude - point1.longitude);

  final double lat1Rad = _degreesToRadians(point1.latitude);
  final double lat2Rad = _degreesToRadians(point2.latitude);

  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1Rad) * math.cos(lat2Rad);
  
  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c; // Distance in kilometers
}

/// Helper function to convert degrees to radians.
double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180;
}

// --- MISSING FUNCTION ADDED HERE ---

/// Calculates the time (in minutes) required to travel between two points.
/// This is used as the 'weight' for the graph edges.
/// Time (min) = Distance (km) / Speed (km/min)
double calculateJeepneyWeight(LatLng point1, LatLng point2) {
  final distanceKm = calculateDistance(point1, point2);
  // Use the constant defined in pathfinding_config.dart
  return distanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN; 
}

// --- END OF MISSING FUNCTION ---

/// --- POLYLINE STAGGERING LOGIC ---
///
/// Calculates points for a polyline that are slightly offset from the main line.
/// This is used to display multiple overlapping jeepney routes clearly on the map.
///
/// [points]: The original LatLng points of the segment (usually just start and end node).
/// [index]: The 0-based index of the current route sharing this segment.
/// [totalSegments]: The total number of routes that share this segment.
List<LatLng> calculateStaggeredPoints(
    List<LatLng> points, int index, int totalSegments) {
  if (points.length < 2) return points;

  final LatLng start = points.first;
  final LatLng end = points.last;

  // Determine the offset amount. We use 5 meters (0.005 km) as the base offset.
  const double baseOffsetKm = 0.005; 
  
  // Calculate the total required offset based on its position in the stack (index)
  // Example: Center line (index=0) is offset 0. Index=1 is offset 5m, Index=2 is offset -5m, Index=3 is offset 10m, etc.
  final double signedOffsetKm = 
      (index == 0) ? 0.0 : baseOffsetKm * (index.isOdd ? (index + 1) ~/ 2 : -index ~/ 2);

  // Convert km offset to degrees (approximation for LatLng adjustment)
  // 1 degree of latitude is roughly 111 km. 1 degree of longitude varies.
  // We'll use a simplified degree approximation for staggering effect.
  final double offsetDegrees = signedOffsetKm / 111.0; 

  // Calculate the angle (bearing) of the line segment
  final double lat1 = _degreesToRadians(start.latitude);
  final double lon1 = _degreesToRadians(start.longitude);
  final double lat2 = _degreesToRadians(end.latitude);
  final double lon2 = _degreesToRadians(end.longitude);

  final double dLon = lon2 - lon1;
  final double bearingRad = math.atan2(
    math.sin(dLon) * math.cos(lat2),
    math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon),
  );

  // Perpendicular angle for offset
  final double perpendicularRad = bearingRad + math.pi / 2.0;

  // Apply the offset to the start point
  final LatLng staggeredStart = LatLng(
    start.latitude + offsetDegrees * math.sin(perpendicularRad),
    start.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  // Apply the offset to the end point
  final LatLng staggeredEnd = LatLng(
    end.latitude + offsetDegrees * math.sin(perpendicularRad),
    end.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  return [staggeredStart, staggeredEnd];
}
