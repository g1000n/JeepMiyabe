import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Represents a single geographical point (Latitude and Longitude) in a route.
class RoutePoint {
  final double lat;
  final double lon;

  RoutePoint({required this.lat, required this.lon});

  // Factory constructor to create a RoutePoint from a JSON map
  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }

  // Helper method to convert to LatLng object for Google Maps
  LatLng toLatLng() {
    return LatLng(lat, lon);
  }
}

/// Represents a complete jeepney route, including its name, display color, and polyline points.
class RouteData {
  final String name;
  final Color color;
  final List<RoutePoint> points;

  RouteData({
    required this.name,
    required this.color,
    required this.points,
  });

  // Factory constructor to create a RouteData object from a JSON map
  factory RouteData.fromJson(Map<String, dynamic> json) {
    // 1. Parse the color string (e.g., "0xFFFF0000") into a Flutter Color object
    // The Python script formatted the color string correctly for this conversion.
    final String colorString = json['color'] as String;
    // int.parse(..., radix: 16) is used because the string is a hexadecimal value, 
    // but since the string is formatted as "0xFF...", we can use a simpler parse.
    final Color routeColor = Color(int.parse(colorString));

    // 2. Parse the list of points
    final List<dynamic> pointsJson = json['points'] as List<dynamic>;
    final List<RoutePoint> routePoints = pointsJson
        .map((point) => RoutePoint.fromJson(point as Map<String, dynamic>))
        .toList();

    return RouteData(
      name: json['name'] as String,
      color: routeColor,
      points: routePoints,
    );
  }
}
