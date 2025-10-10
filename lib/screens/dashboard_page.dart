import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart';  // Adjust path to your AuthStorage file
import 'profile_page.dart';  // Import the new ProfilePage (adjust path)
import 'map_screen.dart';    // Import your MapScreen

const Color kPrimaryColor = Color(0xFFE4572E);  // App's primary orange-red
const Color kBackgroundColor = Color(0xFFFDF8E2);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();  // For sliding effect

  // V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V 
  // FIX 1: MapScreen moved to Index 0 (Home Tab)
  final List<Widget> _pages = [
    const MapScreen(),  // Index 0: MapScreen is the Home view
    const Center(child: Text('About Us Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))), // Index 1
    const Center(child: Text('Center Button Activated', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))), // Index 2: Center FAB
    const Center(child: Text('Favorites Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))), // Index 3
    const ProfilePage(),  // Index 4: ProfilePage
  ];
  // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Function to handle tab changes with slide animation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,  // Smooth sliding curve
    );
    debugPrint('Tapped index: $index');
  }

  // Logout function: Clears session and cooldown, navigates to welcome
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();  
      await AuthStorage.clearMFACooldown();           
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Logged out successfully."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper widget to build the individual navigation items (Home, About Us, Favorites, Profile)
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    // Index 2 is reserved for the FloatingActionButton, so we skip it for the row layout.
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(  // Sliding container for pages
          controller: _pageController,
          // V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V V 
          physics: const NeverScrollableScrollPhysics(), // <--- FIX 2: DISABLE SWIPING
          // ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ ^ 
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);  // Sync index on swipe
          },
          children: _pages.map((page) => page).toList(),
        ),
      ),
      backgroundColor: kBackgroundColor,
      
      // The raised, custom center button (Index 2)
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor, // Orange color
        shape: const CircleBorder(),
        onPressed: () => _onItemTapped(2), // Activates the Center FAB view
        elevation: 4.0, // A slight elevation to make it stand out
        child: const Icon(Icons.arrow_upward, color: Colors.white, size: 30),
      ),
      
      // Position the FloatingActionButton centrally and docked
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // The custom bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        color: kPrimaryColor, // Solid orange background
        shape: const CircularNotchedRectangle(), // Cutout shape for the FAB
        notchMargin: 8.0, // Space between the FAB and the bottom bar
        padding: EdgeInsets.zero, // Remove default padding
        height: 65, // Fixed height for a sleek look
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Left items
            _buildNavItem(index: 0, icon: Icons.home, label: 'Home'),
            _buildNavItem(index: 1, icon: Icons.list, label: 'About Us'),

            // Spacer for the Floating Action Button
            const SizedBox(width: 40), 

            // Right items
            _buildNavItem(index: 3, icon: Icons.bookmark, label: 'Favorites'),
            _buildNavItem(index: 4, icon: Icons.person, label: 'Profile'),  // Now slides to ProfilePage
          ],
        ),
      ),
    );
  }
}
