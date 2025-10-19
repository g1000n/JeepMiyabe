import 'package:flutter/material.dart';
import 'fare_matrix_sheet.dart'; // Import the extracted sheet content

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);

// --- NEW DATA STRUCTURE FOR DESCRIPTIONS ---
const Map<String, String> kRouteDescriptions = {
  'Main Gate - Friendship':
      'The Main Gate - Friendship jeepney runs along a key route, providing essential transportation between the Clark Main Gate and Friendship Highway. This route passes through commercial areas and is frequently used by commuters and visitors. This is the detailed description of the route.',
  'C-Point - Balibago - H\'way':
      'This C-Point - Balibago - H\'way route connects the entertainment district of Balibago with major hubs like C-Point, running along the main highway. It is a vital link for nightlife, shopping, and general transit in the city center.',
  'SM City - Main Gate - Dau':
      'Serving as a major commercial link, the SM City - Main Gate - Dau route connects SM City Clark, the Clark Main Gate, and the Dau common terminal. It is one of the busiest routes, connecting city shoppers and inter-provincial travelers.',
  'Checkpoint - Hensonville - Holy':
      'Connecting Checkpoint to the residential and educational areas of Hensonville and Holy Angel University, this route is popular with students and residents of the inner subdivisions.',
  'Sapang Bato - Angles':
      'The Sapang Bato - Angeles route offers transport from the more distant Sapang Bato barangay into the main Angeles City center. It\'s a longer route that serves suburban and rural commuters.',
  'Checkpoint - Holy - Highway':
      'This specific route services Checkpoint, Holy, and the Highway, primarily facilitating movement along these major thoroughfares and connecting key points of interest and transport hubs.',
  'Marisol - Pampang':
      'This route links the Marisol village area to the Pampang public market and surrounding commercial zones. It\'s primarily a local route focused on residential and market access.',
  'Pandan - Pampang':
      'Connecting the Pandan area to the bustling Pampang public market, this route is essential for residents accessing local goods and services.',
  'Sunset - Nepo':
      'The Sunset - Nepo route connects the residential area of Sunset with the downtown commercial hub around Nepo. It is an important access point for various government and business offices.',
  'Villa - Pampang - SM Telebastagan':
      'A longer route connecting Villa, Pampang, and extending up to SM Telebastagan. This is a crucial link for residents in the northern part of the city to access major malls and markets.',
  'Capaya - Angeles':
      'The Capaya - Angeles route provides service between the Capaya barangay and the city proper, primarily serving residents who commute to the city for work or school.',
  // Ensure all routes in _getRouteImage are here with their unique descriptions.
};
// ---------------------------------------------------------------------------


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

  // Function to retrieve the specific description
  String _getRouteDescription(String routeName) {
    // Look up the description in the map, or provide a default if not found
    return kRouteDescriptions[routeName] ??
        'No detailed description available for this route ($routeName).';
  }

  // Color-to-Jeep Icon Map (Omitted for brevity, assumed unchanged)
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


  // Route-Image Map (Omitted for brevity, assumed unchanged)
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
    return routeImages[routeName] ?? 'assets/jeepney_route_map_default.png';
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the dynamic description here
    final String routeDescription = _getRouteDescription(routeName);

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
          // Header (Omitted for brevity, assumed unchanged)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Row(
              children: [
                // Back Button
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
                  // 1. Map Route Image Card (Omitted for brevity, assumed unchanged)
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

                  // 2. Jeep Image and Details Section (Omitted for brevity, assumed unchanged)
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
                            width: 150,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Route Name
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

                        // 3. Route Description (THE KEY CHANGE IS HERE)
                        Text(
                          routeDescription, // <-- NOW USES THE DYNAMIC VARIABLE
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        const SizedBox(height: 20),

                        // Button for Viewing Fare Matrix (Omitted for brevity, assumed unchanged)
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