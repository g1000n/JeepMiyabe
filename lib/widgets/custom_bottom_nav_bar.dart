import 'package:flutter/material.dart';
import 'action_pin_button.dart'; // Import the central button

/// Internal widget for a single navigation item.
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;

  const _NavBarItem(this.icon, this.label, this.color, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        debugPrint('Tapped $label');
        // Implement navigation logic here
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.white70),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// The main custom curved bottom navigation bar with a floating central button.
class CustomBottomNavBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onPinPressed;

  const CustomBottomNavBar({
    super.key,
    required this.primaryColor,
    required this.onPinPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Floating Direction Pin/Pointer (UTB)
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: FloatingActionPin(onPressed: onPinPressed),
        ),

        // The main Orange Bottom Bar
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: primaryColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBarItem(Icons.home, 'Home', primaryColor, isSelected: true),
              _NavBarItem(Icons.list_alt, 'About Us', primaryColor),
              // The central item slot is empty for the floating button
              const SizedBox(width: 60),
              _NavBarItem(Icons.bookmark, 'Favorites', primaryColor),
              _NavBarItem(Icons.person, 'Profile', primaryColor),
            ],
          ),
        ),
      ],
    );
  }
}
