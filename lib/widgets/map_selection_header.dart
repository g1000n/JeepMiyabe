// lib/widgets/map_selection_header.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../geo_utils.dart'; // Assume getApproximateLocationName is here

// --- CONSTANTS ---
const Color kHeaderColor = Color(0xFFFFFFFF);
// NOTE: These constants are redefined here, ideally imported from a central file.

class MapSelectionHeader extends StatelessWidget {
  final LatLng? startPoint;
  final LatLng? endPoint;
  
  const MapSelectionHeader({
    super.key,
    required this.startPoint,
    required this.endPoint,
  });

  @override
  Widget build(BuildContext context) {
    // NOTE: This uses the getApproximateLocationName function assumed to be in geo_utils.dart
    String fromText = startPoint == null
        ? 'Tap map to set Start Point'
        : 'FROM: ${getApproximateLocationName(startPoint!)}';

    String toText = endPoint == null
        ? (startPoint == null
            ? 'Tap "Start New Route" to begin'
            : 'Tap map to set Destination')
        : 'TO: ${getApproximateLocationName(endPoint!)}';

    TextStyle statusStyle =
        const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: kHeaderColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        minimum: const EdgeInsets.only(top: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trip_origin, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fromText,
                    style: statusStyle.copyWith(
                      color: startPoint != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 10, thickness: 1),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toText,
                    style: statusStyle.copyWith(
                      color: endPoint != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}