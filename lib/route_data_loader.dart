import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart'; // Needed for Color

/// Represents a single coordinate point extracted from the KML file.
class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: json['lat'] as double,
      longitude: json['lon'] as double,
    );
  }
}

/// Represents a complete jeepney route, including its name, color, and coordinates.
class RouteData {
  final String name;
  final int color;
  final List<RoutePoint> points;
  final Polyline polyline; 

  RouteData({
    required this.name,
    required this.color,
    required this.points,
  }) : polyline = Polyline(
          polylineId: PolylineId(name),
          color: Color(color),
          points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
          width: 5,
        );

  factory RouteData.fromJson(Map<String, dynamic> json) {
    final colorInt = int.parse(json['color'] as String);
    
    final List<RoutePoint> routePoints = (json['points'] as List)
        .map((pointJson) => RoutePoint.fromJson(pointJson as Map<String, dynamic>))
        .toList();

    return RouteData(
      name: json['name'] as String,
      color: colorInt,
      points: routePoints,
    );
  }
}

/// Utility function to load and parse all route data from the assets JSON file.
Future<List<RouteData>> loadRoutes() async {
  try {
    final String jsonString = await rootBundle.loadString('assets/data/routes_data.json');
    final List<dynamic> jsonList = jsonDecode(jsonString);
    
    final List<RouteData> routes = jsonList
        .map((jsonItem) => RouteData.fromJson(jsonItem as Map<String, dynamic>))
        .toList();
    
    print('Successfully loaded and parsed ${routes.length} routes.');
    return routes;

  } catch (e) {
    print('Error loading or parsing routes data: $e');
    return []; 
  }
}
