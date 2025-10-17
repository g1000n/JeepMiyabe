import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_info_page.dart'; // Import the updated AccountInfoPage

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLogout; // Callback for logout
  const ProfilePage({super.key, this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _currentUsername; // To store the fetched username
  String _statusMessage = 'Loading...'; // Track status for display

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Initial fetch
  }

  Future<void> _fetchUserData() async {
    print('Fetching user data...'); // Debugging log
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .single();
        setState(() {
          _currentUsername = response['username'] as String?;
          _statusMessage = ''; // Clear loading message if successful
        });
        print('User data fetched: $_currentUsername'); // Debugging log
      } catch (e) {
        print('Error fetching user data: $e'); // Debugging log
        setState(() {
          _statusMessage = 'Error loading username'; // Show error message
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Please log in'; // Handle unauthenticated user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Profile Avatar + Name Section
            Column(
              children: [
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.12,
                  backgroundColor: kPrimaryColor,
                  child: const Icon(Icons.person, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentUsername != null ? _currentUsername! : _statusMessage,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '@gyawnnnnn', // TODO: Fetch from Supabase if needed
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // White Container for Options
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildMenuItem(
                      icon: Icons.person_outline,
                      label: "Account Information",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AccountInfoPage()),
                        ).then((_) => _fetchUserData()); // Refresh data on return
                      },
                      primaryColor: kPrimaryColor,
                    ),
                    buildMenuItem(
                      icon: Icons.history,
                      label: "History",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("History tapped")),
                        );
                      },
                      primaryColor: kPrimaryColor,
                    ),
                    buildMenuItem(
                      icon: Icons.logout,
                      label: "Log Out",
                      onTap: widget.onLogout ?? () {},
                      primaryColor: kPrimaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Semantics(
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 16, color: primaryColor),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}