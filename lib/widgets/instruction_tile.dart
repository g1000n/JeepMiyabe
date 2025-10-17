import 'package:flutter/material.dart';
import '../route_segment.dart'; // Import the data model

// --- COLOR CONSTANTS (Defined locally for the widget's independence) ---
// You should ensure this matches the kPrimaryColor in your main constants file
const Color kPrimaryColor = Color(0xFFE4572E); 

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
        iconColor = segment.color; // Jeepney color comes from the segment data
        break;
      case SegmentType.TRANSFER:
        icon = Icons.swap_horiz;
        // 🛠️ EDITED: Use the consistent kPrimaryColor for transfers instead of a hardcoded deepOrange
        iconColor = kPrimaryColor; 
        break;
    }

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 30),
      title: Text(
        segment.description,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          // Text color depends on if it's a Jeepney segment
          color: segment.type == SegmentType.JEEPNEY ? Colors.black : Colors.black87,
        ),
      ),
      subtitle: Text(
        // Display duration and distance
        '${segment.durationMin.toStringAsFixed(0)} min / ${segment.distanceKm.toStringAsFixed(2)} km',
        style: TextStyle(color: Colors.grey.shade700),
      ),
    );
  }
}