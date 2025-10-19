import 'package:flutter/material.dart';

/// The contextual floating button ('Tap to Set Start Point', 'Clear Route', etc.)
class RouteActionButton extends StatelessWidget {
  final Color primaryColor;
  final bool isSearching;
  final bool startPointSet;
  final bool endPointSet;
  final VoidCallback clearRoute;
  //NEW PROPERTIES
  final bool isSelectingPoints;
  final VoidCallback enableSelection;
  //END NEW PROPERTIES

  const RouteActionButton({
    super.key,
    required this.primaryColor,
    required this.isSearching,
    required this.startPointSet,
    required this.endPointSet,
    required this.clearRoute,
    //REQUIRED NEW PROPERTIES
    required this.isSelectingPoints,
    required this.enableSelection,
    //END REQUIRED NEW PROPERTIES
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
    } 
    //FIX IMPLEMENTED HERE
    else if (startPointSet && endPointSet) {
      // State 2: Route is set (before finding route or after finishing a route)
      text = 'Clear Route';
      icon = Icons.clear;
      color = Colors.red.shade700;
      action = clearRoute;
    } 
    else if (isSelectingPoints) {
      // State 3: Selection mode is ON, show CANCEL button.
      // It doesn't matter if startPointSet is true or false here,
      // the only active choice is to cancel the mode entirely.
      text = 'Cancel Selection'; 
      icon = Icons.cancel; 
      color = Colors.orange.shade800; // Use a distinct color for cancel
      action = clearRoute; // The clearRoute function is perfect for cancelling the selection mode
    } 
    else {
      // State 4: Selection mode is OFF, user must press the button to start
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
