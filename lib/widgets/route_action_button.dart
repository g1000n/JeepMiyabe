import 'package:flutter/material.dart';

/// The contextual floating button ('Tap to Set Start Point', 'Clear Route', etc.)
class RouteActionButton extends StatelessWidget {
  final Color primaryColor;
  final bool isSearching;
  final bool startPointSet;
  final bool endPointSet;
  final VoidCallback clearRoute;

  const RouteActionButton({
    super.key,
    required this.primaryColor,
    required this.isSearching,
    required this.startPointSet,
    required this.endPointSet,
    required this.clearRoute,
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
      action = () {};
    } else if (!startPointSet) {
      text = 'Tap to Set Start Point';
      icon = Icons.location_on;
      color = primaryColor;
      action = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap the map to set your starting location.')),
        );
      };
    } else if (!endPointSet) {
      text = 'Tap to Set Destination';
      icon = Icons.location_on;
      color = primaryColor;
      action = () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tap the map to set your destination.')),
        );
      };
    } else {
      text = 'Clear Route';
      icon = Icons.clear;
      color = Colors.red.shade700;
      action = clearRoute;
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
