import 'package:flutter/material.dart';
import '../route_segment_model.dart'; // Import the data model
import '../widgets/instruction_tile.dart'; // Import the widget used inside the sheet

/// Displays the route instructions in a persistent, draggable modal bottom sheet.
void showInstructionsSheet(
  BuildContext context,
  List<RouteSegment> segments,
  double totalTime,
  double totalDistance,
) {
  if (segments.isEmpty) {
    // Safety check: Don't show the sheet if there's no route
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No route available to display instructions.')),
    );
    return;
  }
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.1,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Time: ${totalTime.toStringAsFixed(0)} mins',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Distance: ${totalDistance.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    return InstructionTile(segment: segments[index]);
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
