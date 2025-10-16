import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart'; // Adjust path to your AuthStorage file
import 'profile_page.dart'; // Import the new ProfilePage (adjust path)
import 'map_screen.dart'; // Import your MapScreen
import 'favorites_page.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../routes.dart';

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E); // App's primary orange-red
const Color kBackgroundColor = Color(0xFFFDF8E2);
const Color kCardColor =
    Color(0xFFFC775C); // A lighter orange for the background of the sheet/cards
const Color kHeaderColor =
    Color(0xFFE4572E); // Color used for the 'ABOUT JEEP...' text in the image

// ---------------------------------------------------------------------------
// 🛑 NEW WIDGET: ABOUT US PAGE
// Created to match the provided image for the 'About Us' tab.
// ---------------------------------------------------------------------------
class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Top Section (Back Arrow and Jeepney Image)
          // The back arrow on the 'About Us' tab typically navigates back from a detail view.
          // Since the whole AboutUsPage is a tab content, the arrow is removed
          // as it doesn't fit the tab structure, but the spacing is kept.
          Padding(
            padding: const EdgeInsets.only(
                top: 10.0, left: 10.0, right: 10.0, bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Back arrow is removed as this is a primary tab destination
                // but can be added back if this page is a standalone route.
              ],
            ),
          ),

          // 2. Jeepney Image
          // Placeholder for the colorful jeepney image from the prompt.
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

          // 4. Description Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
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
          // Note: The BottomAppBar is part of the parent Scaffold, so no need to add it here.
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 🛑 NEW WIDGET: JEEP INFO MODAL SHEET CONTENT
// This widget displays the detailed route information when a card is tapped.
// ---------------------------------------------------------------------------
class JeepInfoSheetContent extends StatelessWidget {
  final String routeName;
  final String colorName;

  const JeepInfoSheetContent({
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


  // Route-Image Map
  String _getRouteImage(String routeName){
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

    return routeImages[routeName] ?? 'assets/jeepney.png'; // Default image if not found
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
                            //color: Colors.white, // Placeholder for map image
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
                            //_getJeepIcon(colorName), //Use this for the colored icons
                            'assets/jeepney.png',
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
                            Text(
                              routeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
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
                              builder: (context) => FareMatrixSheet(),
                            );
                          },
                          child: const Text (
                            'View Fare',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

// ---------------------------------------------------------------------------
// --- UPDATED JEEPNEY ROUTE CARD WIDGET ---
// ---------------------------------------------------------------------------
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
          // FIX: Use showModalBottomSheet to display the detailed info screen
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
// ---------------------------------------------------------------------------

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // STATE VARIABLES FOR PERSISTENT SHEET AND ANIMATION
  bool _isJeepListSheetOpen = false;
  PersistentBottomSheetController? _bottomSheetController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  late final List<Widget> _pages;
  
  // Dynamic elevations to hide shadows when sheet is open
  double get _fabElevation => _isJeepListSheetOpen ? 0.0 : 4.0;
  double get _appBarElevation => _isJeepListSheetOpen ? 0.0 : 8.0;

  // 🛑 UPDATE: Replaced placeholder for index 1 with the new AboutUsPage()
  
  @override
  void initState() {
    super.initState();
    // Initialize AnimationController for the FAB icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Defines the rotation range (0.0 to 0.5 for 180 degrees)
    _animation = Tween<double>(begin: 0.0, end: 0.5).animate(_animationController);

    _pages = [
      const MapScreen(), // Index 0: Home view (MapScreen)
      const AboutUsPage(),
      const SizedBox.shrink(), // Placeholder for FAB (Index 2)
      const FavoritesPage(),
      ProfilePage(onLogout: () => _logout(context)), // Index 4: ProfilePage
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _bottomSheetController?.close();
    super.dispose();
  }

  // UPDATED: Uses Scaffold.of().showBottomSheet for a PERSISTENT sheet
  void _onFabTapped(BuildContext fabContext) {
    // 1. Get the Scaffold state using the correct context (fabContext)
    final ScaffoldState scaffoldState = Scaffold.of(fabContext);

    if (_isJeepListSheetOpen) {
      // 2. If sheet is open, close it (Dismiss animation)
      _animationController.reverse();
      _bottomSheetController?.close();
    } else {
      // 3. If sheet is closed, open it (Show animation)
      _animationController.forward();

      // Show the persistent bottom sheet and save the controller
      _bottomSheetController = scaffoldState.showBottomSheet(
        (context) => _buildJeepListSheetContent(),
        backgroundColor: Colors.transparent,

        // Max height constraint to leave space for the BottomAppBar (65)
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                65),
      );

      // 4. Handle cleanup when the sheet is dismissed (e.g., by dragging down)
      _bottomSheetController!.closed.then((_) {
        if (mounted) {
          setState(() {
            _isJeepListSheetOpen = false;
            _bottomSheetController = null;
            // Ensure arrow points down when manually dismissed
            _animationController.reverse(from: _animationController.value);
          });
        }
      });

      // 5. Update state and trigger rebuild for elevation change
      setState(() {
        _isJeepListSheetOpen = true;
      });
    }
    debugPrint(
        'Floating Action Button activated: Sheet is now ${_isJeepListSheetOpen ? "OPEN" : "CLOSED"}.');
  }

  // Sheet content for FULL-WIDTH
  Widget _buildJeepListSheetContent() {
    return Container(
      // Ensure full width
      width: double.infinity,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          // Keep the sheet's shadow over the MapScreen
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          // Title
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Main Page - Jeep List',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // List of Jeepney Cards
          SizedBox(
            height: 300,
            child: ListView(
              shrinkWrap: true,
              children: const [
                JeepRouteCard(routeName: 'Main Gate - Friendship', colorName: 'Sand'),
                JeepRouteCard(routeName: 'C-Point - Balibago - H\'way', colorName: 'Grey'),
                JeepRouteCard(routeName: 'SM City - Main Gate - Dau', colorName: 'Various'),
                JeepRouteCard(routeName: 'Checkpoint - Hensonville - Holy', colorName: 'White'),
                JeepRouteCard(routeName: 'Sapang Bato - Angles', colorName: 'Maroon'),
                JeepRouteCard(routeName: 'Checkpoint - Holy - Highway', colorName: 'Lavander'),
                JeepRouteCard(routeName: 'Marisol - Pampang', colorName: 'Green'),
                JeepRouteCard(routeName: 'Pandan - Pampang', colorName: 'Blue'),
                JeepRouteCard(routeName: 'Sunset - Nepo', colorName: 'Orange'),
                JeepRouteCard(routeName: 'Villa - Pampang - SM Telebastagan', colorName: 'Yellow'),
                JeepRouteCard(routeName: 'Capaya - Angeles', colorName: 'Pink')
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);

    // Close the bottom sheet if another tab is selected
    if (_isJeepListSheetOpen) {
      _animationController.reverse();
      _bottomSheetController?.close();
      setState(() {
        _isJeepListSheetOpen = false;
        _bottomSheetController = null;
      });
    }
  }

  Widget _buildNavItem(
      {required int index, required IconData icon, required String label}) {
    if (index == 2) return const SizedBox.shrink();

    final bool isSelected = _selectedIndex == index;
    final Color iconColor = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    color: iconColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Logout function (for completeness)
  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      // AuthStorage.clearMFACooldown() is commented out as the import is an external file
      // await AuthStorage.clearMFACooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Logged out successfully."),
              backgroundColor: Colors.green),
        );
        // Navigator.pushReplacementNamed(context, '/welcome'); 

        //Navigate back to welcome page and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(context, '/welcome', (Route<dynamic> route) => false,);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Logout failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: _pages,
        ),
      ),
      backgroundColor: kBackgroundColor,

      floatingActionButton: Builder(builder: (fabContext) {
        return FloatingActionButton(
          backgroundColor: kPrimaryColor,
          shape: const CircleBorder(),
          onPressed: () => _onFabTapped(fabContext),
          // FIX: Control elevation to remove shadow when open
          elevation: _fabElevation,

          // ANIMATION IMPLEMENTATION
          child: RotationTransition(
            turns: _animation,
            // Default state is Icons.arrow_upward (as requested)
            // Rotates to downward when sheet is open.
            child:
                const Icon(Icons.arrow_upward, color: Colors.white, size: 30),
          ),
        );
      }),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        color: kPrimaryColor,
        // FIX: Control elevation to remove the line/shadow when open
        elevation: _appBarElevation,

        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: EdgeInsets.zero,
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(index: 0, icon: Icons.home, label: 'Home'),
            _buildNavItem(index: 1, icon: Icons.list, label: 'About Us'),
            const SizedBox(width: 40),
            _buildNavItem(index: 3, icon: Icons.bookmark, label: 'Favorites'),
            _buildNavItem(index: 4, icon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fare Matrix Sheet (Same color scheme as Jeep Info)
// ---------------------------------------------------------------------------

class FareMatrixSheet extends StatelessWidget {
  const FareMatrixSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    // Table data
    final List<Map<String,String>> fareData = [
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

                      //Table Header
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

                      //Table Rows
                      ...fareData.map((fare) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Text(fare["Distance"]!, style: const TextStyle(color: Colors.white)),
                              Text(fare["Regular"]!, style: const TextStyle(color: Colors.white)),
                              Text(fare["Discounted"]!, style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        );
                      }).toList(),
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