import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart';  // Adjust path to your AuthStorage file (from MFA cooldown solution)

const Color kPrimaryColor = Color(0xFFE4572E);  // Standardized to app's primary orange-red
const Color kBackgroundColor = Color(0xFFFDF8E2);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // Placeholder pages for testing the navigation bar state
  final List<Widget> _pages = [
    const Center(child: Text('Home Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('About Us Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Center Button Activated', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Favorites Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
    const Center(child: Text('Profile Tab Selected', style: TextStyle(color: kPrimaryColor, fontSize: 24, fontWeight: FontWeight.bold))),
  ];

  // Function to handle tab changes (no external functionality yet)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // In a real app, you would navigate or update the state here.
    debugPrint('Tapped index: $index');
  }

  // Logout function: Clears session and cooldown, navigates to welcome
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();  // Clear Supabase session
      await AuthStorage.clearMFACooldown();           // Clear local MFA cooldown
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
    // Active icon/text is white, inactive is slightly dimmer white for contrast on the orange background
    final Color iconColor = isSelected ? Colors.white : Colors.white70;

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        // Add a bit of padding for touch target size
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
      appBar: AppBar(  // Added AppBar with logout
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,  // Call logout function
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(  // Wrapped for better edge handling
        child: _pages[_selectedIndex],
      ),
      backgroundColor: kBackgroundColor,
      
      // The raised, custom center button (Index 2)
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimaryColor, // Orange color
        shape: const CircleBorder(),
        onPressed: () => _onItemTapped(2), // Activate center tab
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
            _buildNavItem(index: 4, icon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}