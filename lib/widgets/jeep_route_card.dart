// lib/widgets/jeep_route_card.dart

import 'package:flutter/material.dart';
import 'jeep_info_sheet_content.dart'; // Import the detailed sheet content

// --- CONSTANTS (Define or import from a central file) ---
const Color kCardColor = Color(0xFFFC775C);

class JeepRouteCard extends StatelessWidget {
  final String routeName;
  final String colorName;

  const JeepRouteCard({
    super.key,
    required this.routeName,
    required this.colorName,
  });

  // Color-to-Jeep Icon Map
  String _getJeepIcon(String colorName) {
    final Map<String, String> jeepIcons = {
      'Sand': 'assets/color_sand.png',
      'Grey': 'assets/color_grey.png',
      'Various': 'assets/color_various.png',
      'White': 'assets/color_white.png',
      'Maroon': 'assets/color_maroon.png',
      'Lavander': 'assets/color_lavender.png',
      'Green': 'assets/color_green.png',
      'Blue': 'assets/color_blue.png',
      'Orange': 'assets/color_orange.png',
      'Yellow': 'assets/color_yellow.png',
      'Pink': 'assets/color_pink.png',
    };
    return jeepIcons[colorName] ?? 'assets/jeepney.png';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          // Use showModalBottomSheet to display the detailed info screen
          showModalBottomSheet(
            context: context,
            isScrollControlled:
                true, // Allows the sheet to take up most of the screen
            backgroundColor:
                Colors.transparent, // Important for rounded corners
            builder: (context) {
              return JeepInfoSheetContent(
                routeName: routeName,
                colorName: colorName,
              );
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Image.asset(
                _getJeepIcon(colorName),
                width: 50,
                height: 35,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      routeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Color: $colorName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'More Info',
                      style: TextStyle(fontSize: 9, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}