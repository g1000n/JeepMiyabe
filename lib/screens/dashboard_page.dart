import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart'; // Adjust path to your AuthStorage file
import 'profile_page.dart';
import 'map_screen.dart';
import 'favorites_page.dart';
// Note: We need PreSetDestination for the state variable
import 'map_screen.dart' show MapScreen, PreSetDestination; 


// --- NEW IMPORTS FOR EXTRACTED WIDGETS ---
import '../widgets/about_us_page.dart';
import '../widgets/jeep_route_card.dart';
// ------------------------------------------

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E); // App's primary orange-red
const Color kBackgroundColor = Color(0xFFFDF8E2);
const Color kCardColor = Color(0xFFFC775C);
const Color kHeaderColor = Color(0xFFE4572E);
// ---------------------------------------------------------------------------


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  
  // 🌟 NEW STATE VARIABLE: Holds the destination selected from FavoritesPage
  PreSetDestination? _favoriteDestination;
  
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // STATE VARIABLES FOR PERSISTENT SHEET AND ANIMATION
  bool _isJeepListSheetOpen = false;
  PersistentBottomSheetController? _bottomSheetController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // This MUST be late final to be populated dynamically in initState
  late final List<Widget> _pages;

  // Dynamic elevations to hide shadows when sheet is open
  double get _fabElevation => _isJeepListSheetOpen ? 0.0 : 4.0;
  double get _appBarElevation => _isJeepListSheetOpen ? 0.0 : 8.0;


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

    // 🛑 The _pages list is now initialized in the build method 
    // or as a getter, as it depends on mutable state (_favoriteDestination).
    // For simplicity, we'll keep the list structure here and update the MapScreen widget later.
    _pages = [
      MapScreen(toPlace: _favoriteDestination), // Index 0: MapScreen - Updated in build
      const AboutUsPage(), // Index 1: About Us (Extracted)
      const SizedBox.shrink(), // Placeholder for FAB (Index 2)
      // The FavoritesPage must be navigated to directly to handle the result
      const Center(child: Text("Favorites Tab Content Placeholder")), // Index 3: Placeholder
      ProfilePage(onLogout: () => _logout(context)), // Index 4: ProfilePage
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    // Ensure the sheet is closed when the widget is disposed
    _bottomSheetController?.close();
    super.dispose();
  }

  // UPDATED: Logic to handle navigation to the FavoritesPage 
  // and process the returned destination.
  void _onItemTapped(int index) async {
    if (index == 2) return; // FAB is index 2

    // Close the bottom sheet if another tab is selected
    if (_isJeepListSheetOpen) {
      _animationController.reverse();
      _bottomSheetController?.close();
      setState(() {
        _isJeepListSheetOpen = false;
        _bottomSheetController = null;
      });
    }

    // 🌟 CRITICAL FIX: Handle navigation to FavoritesPage (Index 3) 🌟
    if (index == 3) {
      // Temporarily switch the selected index to show the tab is active
      setState(() => _selectedIndex = index);
      
      // Push FavoritesPage and wait for a result (the selected PreSetDestination)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          // Pushes the FavoritesPage as a full screen route
          builder: (context) => const FavoritesPage(), 
        ),
      );

      // Check if a favorite destination was returned
      if (result != null && result is PreSetDestination) {
        setState(() {
          // 1. Store the destination
          _favoriteDestination = result;
          // 2. Switch to MapScreen tab (index 0)
          _selectedIndex = 0; 
        });
        // 3. Navigate the PageView to MapScreen
        _pageController.jumpToPage(0);
        
        // Return here to prevent the default page navigation below
        return; 
      } else {
        // If the user backed out without selecting a favorite, 
        // return to the previous page (MapScreen index 0 usually)
        setState(() => _selectedIndex = _pageController.page?.round() ?? 0);
        return;
      }
    }
    
    // Default navigation for other tabs
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  // ... (rest of _onFabTapped and _buildJeepListSheetContent remain unchanged) ...
  // UPDATED: Uses Scaffold.of().showBottomSheet for a PERSISTENT sheet
  void _onFabTapped(BuildContext fabContext) {
    final ScaffoldState scaffoldState = Scaffold.of(fabContext);

    if (_isJeepListSheetOpen) {
      // If sheet is open, close it (Dismiss animation)
      _animationController.reverse();
      _bottomSheetController?.close();
    } else {
      // If sheet is closed, open it (Show animation)
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

      // Handle cleanup when the sheet is dismissed (e.g., by dragging down)
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

      // Update state and trigger rebuild for elevation change
      setState(() {
        _isJeepListSheetOpen = true;
      });
    }
    debugPrint(
        'Floating Action Button activated: Sheet is now ${_isJeepListSheetOpen ? "OPEN" : "CLOSED"}.');
  }

  // Sheet content for FULL-WIDTH - Now uses JeepRouteCard
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
              // Uses the imported JeepRouteCard
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
  // ... (end of unchanged section) ...


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
    // 🌟 RE-CREATE the pages list in build to ensure MapScreen gets the updated state 🌟
    final List<Widget> pages = [
      MapScreen(toPlace: _favoriteDestination), // Index 0: MapScreen
      const AboutUsPage(), // Index 1: About Us 
      const SizedBox.shrink(), // Placeholder for FAB (Index 2)
      // Since FavoritesPage is PUSHED, this can be its static content or a placeholder
      const Center(child: Text('Favorites Tab - Use FAB/Search to navigate.')), // Index 3: Favorites
      ProfilePage(onLogout: () => _logout(context)), // Index 4: ProfilePage
    ];
    
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages, // Use the dynamically created list
        ),
      ),
      backgroundColor: kBackgroundColor,

      floatingActionButton: Builder(builder: (fabContext) {
        return FloatingActionButton(
          backgroundColor: kPrimaryColor,
          shape: const CircleBorder(),
          onPressed: () => _onFabTapped(fabContext),
          // Control elevation to remove shadow when open
          elevation: _fabElevation,

          // ANIMATION IMPLEMENTATION
          child: RotationTransition(
            turns: _animation,
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
        // Control elevation to remove the line/shadow when open
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
