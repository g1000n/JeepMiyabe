import 'package:flutter/material.dart';

// --- CONSTANTS (Define or import from a central file, here we define for completeness) ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);
const Color kHeaderColor = Color(0xFFE4572E);

// ---------------------------------------------------------------------------
// NEW WIDGET: ABOUT US PAGE
// ---------------------------------------------------------------------------
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: ListView( // Use ListView instead of Column for overflow safety
        children: [
          // 1. Top Spacing (Keeping space where a back button might be)
          const Padding(
            padding: EdgeInsets.only(
                top: 10.0, left: 10.0, right: 10.0, bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [],
            ),
          ),
          
          // Center the following content
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 2. Jeepney Image
                Image.asset(
                  'assets/jeepney.png', // **Ensure this path points to the colorful image in your assets**
                  width: 200,
                  height: 150,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 20),

                // 3. ABOUT JEEP... Header Text
                Text(
                  'ABOUT',
                  style: TextStyle(
                    color: kHeaderColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'JEEPMIYABE',
                  style: TextStyle(
                    color: kHeaderColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.0, // Tighter line height
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
          

          // 4. Description Text
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'JeepMiyabe is a mobile application designed to make commuting around Angeles City, Pampanga more convenient and reliable. The app provides a smart jeepney route system that helps locals, students, and visitors find the best possible routes to reach their destinations. Users can search for jeepney routes and view important details such as fares, jeepney colors, and their starting and ending points. JeepMiyabe also allows users to save favorite places for quick access, check their ride history, and enable push notifications for updates and reminders.',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}