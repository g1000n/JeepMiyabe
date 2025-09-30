import 'dart:math' show cos, sqrt, asin, pi;
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calculates the distance between two LatLng points using the Haversine formula.
/// 
/// The Haversine formula determines the shortest distance between two points on a 
/// sphere (the Earth), given their latitudes and longitudes.
/// 
/// Returns the distance in **kilometers (km)**.
double calculateDistance(LatLng p1, LatLng p2) {
  const double earthRadiusKm = 6371.0; // Mean Earth radius in kilometers

  double lat1Rad = _degreesToRadians(p1.latitude);
  double lon1Rad = _degreesToRadians(p2.latitude);
  double lat2Rad = _degreesToRadians(p2.latitude);
  double lon2Rad = _degreesToRadians(p2.longitude);

  // Difference in coordinates
  double dLat = _degreesToRadians(p2.latitude - p1.latitude);
  double dLon = _degreesToRadians(p2.longitude - p1.longitude);

  // Haversine formula components
  double a = cos(lat1Rad) * cos(lat2Rad) * _haversine(dLon) + _haversine(dLat);
  double c = 2 * asin(sqrt(a));

  // Distance in kilometers
  double distance = earthRadiusKm * c;
  
  // Return distance rounded to 3 decimal places
  return double.parse(distance.toStringAsFixed(3));
}

/// Helper function to convert degrees to radians
double _degreesToRadians(double degrees) {
  return degrees * (pi / 180.0);
}

/// Helper function for the Haversine calculation (sin^2(theta/2))
double _haversine(double theta) {
  return (1 - cos(theta)) / 2;
}
