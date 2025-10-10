import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Displays the summarized travel time and distance for the calculated route.
class RouteInfoBubble extends StatelessWidget {
  final double totalTime;
  final double totalDistance;

  const RouteInfoBubble({
    super.key,
    required this.totalTime,
    required this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    if (totalTime == 0) return const SizedBox.shrink(); // Hide if no route is found

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FontAwesomeIcons.car, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            '${totalTime.toStringAsFixed(0)} min',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 16,
            width: 1,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            '${totalDistance.toStringAsFixed(1)} km',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
