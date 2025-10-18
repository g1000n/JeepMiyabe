import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;
import 'pathfinding_config.dart';

/// Calculates the distance between two LatLng points in kilometers (Haversine formula).
double calculateDistance(LatLng point1, LatLng point2) {
  // Mean radius of the Earth in kilometers.
  const double earthRadiusKm = 6371.0088;

  final double dLat = _degreesToRadians(point2.latitude - point1.latitude);
  final double dLon = _degreesToRadians(point2.longitude - point1.longitude);

  final double lat1Rad = _degreesToRadians(point1.latitude);
  final double lat2Rad = _degreesToRadians(point2.latitude);

  // Haversine formula calculation
  final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) *
          math.sin(dLon / 2) *
          math.cos(lat1Rad) *
          math.cos(lat2Rad);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadiusKm * c; // Distance in kilometers
}

/// Helper function to convert degrees to radians.
double _degreesToRadians(double degrees) {
  return degrees * math.pi / 180;
}

/// Placeholder for converting coordinates to a readable name (requires Geocoding API in production).
String getApproximateLocationName(LatLng position) {
  // Returns a simple coordinate string as a placeholder name.
  return 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
}

/// Calculates travel time (in minutes) based on distance and average jeepney speed.
double calculateJeepneyWeight(LatLng point1, LatLng point2) {
  final distanceKm = calculateDistance(point1, point2);
  // Calculates Time = Distance / Speed.
  return distanceKm / JEEPNEY_AVG_SPEED_KM_PER_MIN;
}

/// Calculates points for a polyline that are slightly offset (staggered) 
/// from the original line to display overlapping routes clearly on the map.
List<LatLng> calculateStaggeredPoints(
    List<LatLng> points, int index, int totalSegments) {
  if (points.length < 2) return points;

  final LatLng start = points.first;
  final LatLng end = points.last;

  const double baseOffsetKm = 0.005;

  // Calculates the signed offset distance (e.g., 0, +5m, -5m, +10m, -10m...).
  final double signedOffsetKm = (index == 0)
      ? 0.0
      : baseOffsetKm * (index.isOdd ? (index + 1) ~/ 2 : -index ~/ 2);

  // Approximate degree conversion for the offset.
  final double offsetDegrees = signedOffsetKm / 111.0;

  // Calculate the bearing (angle) of the line segment.
  final double lat1 = _degreesToRadians(start.latitude);
  final double lon1 = _degreesToRadians(start.longitude);
  final double lat2 = _degreesToRadians(end.latitude);
  final double lon2 = _degreesToRadians(end.longitude);

  final double dLon = lon2 - lon1;
  final double bearingRad = math.atan2(
    math.sin(dLon) * math.cos(lat2),
    math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon),
  );

  // Determine the perpendicular angle for offsetting.
  final double perpendicularRad = bearingRad + math.pi / 2.0;

  // Apply the offset to the start point.
  final LatLng staggeredStart = LatLng(
    start.latitude + offsetDegrees * math.sin(perpendicularRad),
    start.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  // Apply the offset to the end point.
  final LatLng staggeredEnd = LatLng(
    end.latitude + offsetDegrees * math.sin(perpendicularRad),
    end.longitude + offsetDegrees * math.cos(perpendicularRad),
  );

  return [staggeredStart, staggeredEnd];
}
