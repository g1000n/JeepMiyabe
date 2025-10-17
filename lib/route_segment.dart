import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines the type of transportation/action for a segment of the route.
enum SegmentType { 
  WALK,     // First mile, last mile, or walk transfers
  JEEPNEY,  // Riding a jeepney on a specific route
  TRANSFER  // Indicates a stop solely for transferring between routes
}

// 1. 🛠️ Utility function to convert String back to SegmentType
SegmentType _segmentTypeFromString(String type) {
  // Finds the SegmentType enum value that matches the string (e.g., 'WALK')
  return SegmentType.values.firstWhere(
    (e) => e.toString().split('.').last == type,
    orElse: () => SegmentType.WALK, // Fallback
  );
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

  // 2. 💾 METHOD FOR SAVING (Serialization)
  Map<String, dynamic> toJson() {
    return {
      // Convert Enum to String (e.g., 'SegmentType.JEEPNEY' to 'JEEPNEY')
      'type': type.toString().split('.').last, 
      'description': description,
      'distanceKm': distanceKm,
      'durationMin': durationMin,
      // Convert LatLng objects into a list of simpler maps for saving
      'path': path.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      // NOTE: Saving Color is complex. It's often better to re-derive it (see fromJson)
    };
  }

  // 3. 📖 FACTORY FOR READING (Deserialization)
  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    // Determine the Color based on the saved type for consistency
    Color segmentColor;
    final String typeString = json['type'] as String;
    if (typeString == 'JEEPNEY') {
      segmentColor = Colors.blue.shade700;
    } else if (typeString == 'TRANSFER') {
      segmentColor = Colors.orange.shade700;
    } else {
      segmentColor = Colors.green.shade700; // WALK
    }
    
    return RouteSegment(
      type: _segmentTypeFromString(typeString),
      description: json['description'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      durationMin: (json['durationMin'] as num).toDouble(),
      color: segmentColor, // Re-derive color
      // Convert the list of maps back into LatLng objects
      path: (json['path'] as List<dynamic>)
          .map((p) => LatLng((p as Map)['lat'] as double, p['lng'] as double))
          .toList(),
    );
  }
}