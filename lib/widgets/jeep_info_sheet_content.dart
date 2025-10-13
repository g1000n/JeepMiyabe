import 'package:flutter/material.dart';

// Use the same constants for consistency
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);

class JeepInfoSheetContent extends StatelessWidget {
  final String routeName;
  final String colorName;
  final int fare;

  const JeepInfoSheetContent({
    super.key,
    required this.routeName,
    required this.colorName,
    required this.fare,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the max height, ensuring it doesn't cover the very top status bar
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

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
            padding: const EdgeInsets.only(top: 10.0, left: 10.0),
            child: Row(
              children: [
                // Back Button (Pops the sheet off the stack)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                // Title (Matches your image)
                const SizedBox(width: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: kCardColor, // Lighter card color
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/route_map_placeholder.png', // **Replace with your route map image**
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  // 2. Jeep Image and Details Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Jeep Image (Centered)
                        Center(
                          child: Image.asset(
                            'assets/jeepney_sand.png', // **Replace with the specific jeep image**
                            width: 150,
                            height: 100,
                            fit: BoxFit.contain,
                          ),
                        ),
                        
                        const SizedBox(height: 10),

                        // Route Name and Fare (Row)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              routeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900, // Extra bold
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Fare: PHP $fare',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
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

                        // 3. Route Description
                        const Text(
                          'The Main Gate - Friendship jeepney (sand color) runs along Perimeter Road, also known as Don Juico Avenue. It starts at the Clark Main Gate and goes all the way to Friendship Highway. This route is convenient if you are heading to places along Perimeter Road, where there are many hotels, restaurants, and shops. It is a straightforward ride commonly used by both locals and visitors to travel between Main Gate and the Friendship area.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.justify,
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