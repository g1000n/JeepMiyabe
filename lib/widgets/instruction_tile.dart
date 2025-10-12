import 'package:flutter/material.dart';
import '../route_segment_model.dart'; // Import the data model

/// A list tile representing a single step (Walk, Jeepney, or Transfer) in the route.
class InstructionTile extends StatelessWidget {
  final RouteSegment segment;
  const InstructionTile({super.key, required this.segment});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (segment.type) {
      case SegmentType.WALK:
        icon = Icons.directions_walk;
        iconColor = Colors.grey.shade600;
        break;
      case SegmentType.JEEPNEY:
        icon = Icons.directions_bus_filled;
        iconColor = segment.color;
        break;
      case SegmentType.TRANSFER:
        icon = Icons.swap_horiz;
        iconColor = Colors.deepOrange;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 30),
      title: Text(
        segment.description,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: segment.type == SegmentType.JEEPNEY ? Colors.black : Colors.black87,
        ),
      ),
      subtitle: Text(
        '${segment.durationMin.toStringAsFixed(0)} min / ${segment.distanceKm.toStringAsFixed(2)} km',
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }
}
