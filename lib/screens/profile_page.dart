import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback? onLogout;  // Callback for logout (passed from Dashboard)
  const ProfilePage({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFE4572E);  // App's primary color
    final backgroundColor = const Color(0xFFFDF8E2);  // App's background

    return Container(
      color: backgroundColor,  // Match app background
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  // Back arrow (matches app primary color)
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
                    onPressed: () {
                      // Simulate back to previous tab (Dashboard handles nav)
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // --- PROFILE AVATAR + NAME SECTION ---
            Column(
              children: [
                // Circle avatar (responsive size)
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width * 0.12,  // ~45 on phone, scales up
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.person, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 10),

                // Name and edit icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Gion Lobo',  // TODO: Fetch from Supabase profiles
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE4572E),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(Icons.edit, size: 16, color: Color(0xFFE4572E)),  // Matched primary
                  ],
                ),

                const SizedBox(height: 4),
                const Text(
                  '@gyawnnnnn',  // TODO: Fetch from Supabase
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- WHITE CONTAINER FOR OPTIONS ---
            Expanded(
              child: Semantics(  // Accessibility for the menu section
                label: 'Profile options',
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

                  // List of options
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildMenuItem(
                        icon: Icons.person_outline,
                        label: "Account Information",
                        onTap: () {
                          // Placeholder: Navigate or open dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Account Information tapped")),
                          );
                        },
                        primaryColor: primaryColor,
                      ),
                      buildMenuItem(
                        icon: Icons.history,
                        label: "History",
                        onTap: () {
                          // Placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("History tapped")),
                          );
                        },
                        primaryColor: primaryColor,
                      ),
                      buildMenuItem(
                        icon: Icons.info_outline,
                        label: "Help Center",
                        onTap: () {
                          // Placeholder
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Help Center tapped")),
                          );
                        },
                        primaryColor: primaryColor,
                      ),
                      buildMenuItem(
                        icon: Icons.logout,
                        label: "Log Out",
                        onTap: onLogout ?? () {},  // Use passed callback
                        primaryColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE MENU ITEM WIDGET (Improved with ripple and semantics) ---
  Widget buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Semantics(  // Accessibility label
        label: label,
        child: Material(  // For ripple effect
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),  // Rounded ripple
            onTap: onTap,
            child: Row(
              children: [
                Icon(icon, color: primaryColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}