import 'package:flutter/material.dart';

// --- CONSTANTS (Define or import from a central file) ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);

// ---------------------------------------------------------------------------
// Fare Matrix Sheet (Same color scheme as Jeep Info)
// ---------------------------------------------------------------------------

class FareMatrixSheet extends StatelessWidget {
  const FareMatrixSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    // Table data
    final List<Map<String, String>> fareData = [
      {"Distance": "1", "Regular": "₱13.00", "Discounted": "₱10.50"},
      {"Distance": "2", "Regular": "₱13.00", "Discounted": "₱10.50"},
      {"Distance": "3", "Regular": "₱13.00", "Discounted": "₱10.50"},
      {"Distance": "4", "Regular": "₱13.00", "Discounted": "₱10.50"},
      {"Distance": "5", "Regular": "₱14.75", "Discounted": "₱11.75"},
      {"Distance": "6", "Regular": "₱16.50", "Discounted": "₱13.25"},
      {"Distance": "7", "Regular": "₱18.50", "Discounted": "₱14.75"},
      {"Distance": "8", "Regular": "₱20.25", "Discounted": "₱16.25"},
      {"Distance": "9", "Regular": "₱22.00", "Discounted": "₱17.50"},
      {"Distance": "10", "Regular": "₱23.75", "Discounted": "₱19.00"},
      {"Distance": "11", "Regular": "₱25.50", "Discounted": "₱20.50"},
      {"Distance": "12", "Regular": "₱27.50", "Discounted": "₱22.00"},
      {"Distance": "13", "Regular": "₱29.25", "Discounted": "₱23.25"},
      {"Distance": "14", "Regular": "₱31.00", "Discounted": "₱24.75"},
      {"Distance": "15", "Regular": "₱32.75", "Discounted": "₱26.25"},
      {"Distance": "16", "Regular": "₱34.50", "Discounted": "₱27.75"},
      {"Distance": "17", "Regular": "₱36.50", "Discounted": "₱29.00"},
      {"Distance": "18", "Regular": "₱38.25", "Discounted": "₱30.50"},
      {"Distance": "19", "Regular": "₱40.00", "Discounted": "₱32.00"},
      {"Distance": "20", "Regular": "₱41.75", "Discounted": "₱33.50"},
    ];

    return Container(
      height: maxHeight,
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header (Back Button + Title)
          Padding(
            padding: const EdgeInsets.only(top: 10.0, right: 10.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Fare Matrix',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: kCardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Jeepney Fare Rates',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Distance (km)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Regular', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Discounted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Table Rows
                      ...fareData.map((fare) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(fare["Distance"]!, style: const TextStyle(color: Colors.white)),
                              Text(fare["Regular"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text(fare["Discounted"]!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      const Text(
                        '*Discounted fares apply to Students, Seniors, and PWD.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}