import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines the type of transportation/action for a segment of the route.
enum SegmentType { 
  WALK,     // First mile, last mile, or walk transfers
  JEEPNEY,  // Riding a jeepney on a specific route
  TRANSFER  // Indicates a stop solely for transferring between routes
}

/// Represents a single, distinct step in the calculated route.
class RouteSegment {
  final SegmentType type;
  final String description;
  final List<LatLng> path; // The exact coordinates for drawing the polyline on the map
  final Color color;
  final double distanceKm;
  final double durationMin;
  
  RouteSegment({
    required this.type,
    required this.description,
    required this.path,
    required this.color,
    required this.distanceKm,
    required this.durationMin,
  });
}
