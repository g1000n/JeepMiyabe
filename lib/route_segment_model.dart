import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines the type of transportation/action for a segment of the route.
enum SegmentType { 
  WALK,  // First mile, last mile, or walk transfers
  JEEPNEY, // Riding a jeepney on a specific route
  TRANSFER // Indicates a stop solely for transferring between routes
}

/// Represents a single, distinct step in the calculated route.
class RouteSegment {
  final SegmentType type;
  final String description;
  final List<LatLng> path; // The exact coordinates for drawing the polyline on the map
  final Color color;
  final double distanceKm;
  final double durationMin;
  final String? routeId; // The ID of the jeepney route (null for WALK segments)
  
  RouteSegment({
    required this.type,
    required this.description,
    required this.path,
    required this.color,
    required this.distanceKm,
    required this.durationMin,
    this.routeId, // Optional in the constructor since it can be null
  });

  
  // 🛠️ FIX: Add the copyWith method to allow creating a new instance
  // with updated fields (essential for merging immutable segments).
  RouteSegment copyWith({
    SegmentType? type,
    String? description,
    List<LatLng>? path,
    Color? color,
    double? distanceKm,
    double? durationMin,
    String? routeId,
  }) {
    return RouteSegment(
      type: type ?? this.type,
      description: description ?? this.description,
      path: path ?? this.path,
      color: color ?? this.color,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMin: durationMin ?? this.durationMin,
      routeId: routeId ?? this.routeId,
    );
  }
}
