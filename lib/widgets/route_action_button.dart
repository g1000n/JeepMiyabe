import 'package:flutter/material.dart';

/// The contextual floating button ('Tap to Set Start Point', 'Clear Route', etc.)
class RouteActionButton extends StatelessWidget {
  final Color primaryColor;
  final bool isSearching;
  final bool startPointSet;
  final bool endPointSet;
  final VoidCallback clearRoute;
  // 💡 NEW PROPERTIES
  final bool isSelectingPoints;
  final VoidCallback enableSelection;
  // 💡 END NEW PROPERTIES

  const RouteActionButton({
    super.key,
    required this.primaryColor,
    required this.isSearching,
    required this.startPointSet,
    required this.endPointSet,
    required this.clearRoute,
    // 💡 REQUIRED NEW PROPERTIES
    required this.isSelectingPoints,
    required this.enableSelection,
    // 💡 END REQUIRED NEW PROPERTIES
  });

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    Color color;
    Function() action;

    if (isSearching) {
      text = 'Searching...';
      icon = Icons.hourglass_top;
      color = Colors.grey;
      action = () {}; // No action while searching
    } else if (startPointSet && endPointSet) {
      // Route is set, show Clear button
      text = 'Clear Route';
      icon = Icons.clear;
      color = Colors.red.shade700;
      action = clearRoute;
    } else if (isSelectingPoints) {
      // Selection mode is ON, but route is incomplete (start or end not set yet)
      // The button becomes passive, just showing status. Tapping is done on the map.
      text = !startPointSet ? 'Tap Map for Start' : 'Tap Map for Destination';
      icon = Icons.location_searching;
      color = Colors.blue.shade700;
      action = () {}; // Passive action, tapping happens on the map
    } 
    else {
      // Selection mode is OFF, user must press the button to start
      text = 'Start New Route';
      icon = Icons.map;
      color = primaryColor;
      action = enableSelection; // Calls the function to enable map tapping
    }

    return ElevatedButton.icon(
      onPressed: action,
      icon: Icon(icon, size: 20),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 8,
      ),
    );
  }
}