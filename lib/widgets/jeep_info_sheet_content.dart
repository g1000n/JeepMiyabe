import 'package:flutter/material.dart';
import 'fare_matrix_sheet.dart'; // Import the extracted sheet content

// --- CONSTANTS (Define or import from a central file) ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);

// ---------------------------------------------------------------------------
// JEEP INFO MODAL SHEET CONTENT
// ---------------------------------------------------------------------------
class JeepInfoSheetContent extends StatelessWidget {
  final String routeName;
  final String colorName;

  const JeepInfoSheetContent({
    super.key,
    required this.routeName,
    required this.colorName,
  });

  // Color-to-Jeep Icon Map (Used in JeepRouteCard, included here for completeness/if you decide to use it)
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


  // Route-Image Map
  String _getRouteImage(String routeName) {
    final Map<String, String> routeImages = {
      'Main Gate - Friendship': 'assets/main_gate_friendship.png',
      'C-Point - Balibago - H\'way': 'assets/cpoint_balibago.png',
      'SM City - Main Gate - Dau': 'assets/sm_main_dau.png',
      'Checkpoint - Hensonville - Holy': 'assets/checkpoint_holy_highway.png',
      'Sapang Bato - Angles': 'assets/sapang_bato.png',
      'Checkpoint - Holy - Highway': 'assets/checkpoint_holy_highway.png',
      'Marisol - Pampang': 'assets/marisol_pampang.png',
      'Pandan - Pampang': 'assets/pandan_pampang.png',
      'Sunset - Nepo': 'assets/sunset_nepo.png',
      'Villa - Pampang - SM Telebastagan': 'assets/villa_pampang_sm.png',
      'Capaya - Angeles': 'assets/capaya_angeles.png',
    };

    return routeImages[routeName] ?? 'assets/jeepney_route_map_default.png'; // Default image if not found
  }

  @override
  Widget build(BuildContext context) {
    // Determine the max height, taking up most of the screen
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: kPrimaryColor, // Primary background color
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header (Back Button and Title)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Row(
              children: [
                // Back Button (Pops the sheet off the stack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                // Title
                const Text(
                  'Main Page - Jeep Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content Scrollable Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Map Route Image Card
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: kCardColor, // Lighter card color
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AspectRatio(
                          aspectRatio: 16 / 9, // Adjust ratio as needed
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              _getRouteImage(routeName),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Text("No Image Available", style: TextStyle(color: Colors.black54)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Jeep Image and Details Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jeep Image (Centered)
                        Center(
                          child: Image.asset(
                            _getJeepIcon(colorName), // Use color-specific icon or generic
                            // If using the generic icon, switch to: 'assets/jeepney.png',
                            width: 150,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Route Name (Row)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                routeName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Color
                        Text(
                          'Color: $colorName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3. Route Description (Placeholder text)
                        const Text(
                          'The Main Gate - Friendship jeepney runs along a key route, providing essential transportation between the Clark Main Gate and Friendship Highway. This route passes through commercial areas and is frequently used by commuters and visitors. This is the detailed description of the route.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 20),

                        // Button for Viewing Fare Matrix
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const FareMatrixSheet(),
                            );
                          },
                          child: const Text(
                            'View Fare',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              decoration: TextDecoration.underline, // Added underline for clarity
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}