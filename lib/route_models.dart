import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Defines the type of transport or activity for a segment of the calculated route.
enum SegmentType {
  WALK,
  JEEPNEY,
  TRANSFER,
}

/// Represents a single, consolidated step in the final user-facing route.
/// This structure allows MapScreen to easily display the path, color, and description
/// for each distinct part of the journey.
class RouteSegment {
  /// What kind of movement this segment represents.
  final SegmentType type;

  /// Human-readable instruction (e.g., "Take Complex Loop from Terminal 1 to Intersection Z").
  final String description;

  /// The LatLng points that define the path for this segment.
  final List<LatLng> path;

  /// The color used to draw the polyline for this segment on the map.
  final Color color;

  /// The estimated distance of this segment in kilometers.
  final double distanceKm;

  /// The estimated duration of this segment in minutes.
  final double durationMin;

  RouteSegment({
    required this.type,
    required this.description,
    required this.path,
    required this.color,
    required this.distanceKm,
    required this.durationMin,
  });

  /// A helper to display summary information about the segment.
  String get summary {
    String typeLabel;
    switch (type) {
      case SegmentType.WALK:
        typeLabel = 'Walk';
        break;
      case SegmentType.JEEPNEY:
        typeLabel = 'Jeepney';
        break;
      case SegmentType.TRANSFER:
        typeLabel = 'Transfer';
        break;
    }

    final durationText = '${durationMin.round()} min';
    final distanceText = '${distanceKm.toStringAsFixed(2)} km';

    return '$typeLabel ($durationText, $distanceText)';
  }
}
