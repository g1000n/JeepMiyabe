import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Convert to a StatefulWidget to handle the dynamic connection state
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // State variables for connectivity
  // IMPORTANT: Start as true to ensure the warning shows immediately 
  // if the check fails or is delayed.
  bool _isOffline = true; 
  
  // StreamSubscription to listen for connection changes
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // Start listening immediately on initialization
    _initConnectivityListener();
  }

  @override
  void dispose() {
    // Stop listening when the widget is removed
    _connectivitySubscription.cancel();
    super.dispose();
  }
  
  // Utility function to show the SnackBar for debugging/feedback
  void _showStatusSnackbar(String message, bool isError) {
    // Use an asynchronous call to ensure the context is available after build completes
    Future.delayed(Duration.zero, () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: isError ? Colors.red.shade800 : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  // Set up the connectivity listener and perform initial check
  void _initConnectivityListener() async {
    // --- 1. Aggressive Initial Check (Awaiting the result) ---
    try {
      final initialResult = await Connectivity().checkConnectivity();
      _updateConnectionStatus(initialResult);
    } catch (e) {
      // Log error but maintain offline state if check fails
      print('Error during initial connectivity check: $e');
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
    
    // --- 2. Setup Continuous Listener ---
    // This keeps the state updated whenever the connection status changes.
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionStatus(result);
    });
  }

  // Update the state based on the connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    // Check if the result is 'none'
    final isNone = result == ConnectivityResult.none;
    
    // Log and notify the user about the detected status for debugging
    print('Connectivity Result Detected: $result. Is Offline: $isNone');
    
    if (mounted) {
      // Show a temporary banner/snackbar with the status
      final message = isNone 
          ? "Connection Status: OFFLINE ($result). Buttons Disabled." 
          : "Connection Status: ONLINE ($result). Buttons Enabled.";
      _showStatusSnackbar(message, isNone);
      
      // Only call setState if the status actually changed to avoid unnecessary rebuilds
      if (_isOffline != isNone) {
        setState(() {
          _isOffline = isNone;
        });
      }
    }
  }

  // Navigation functions that check the offline status
  void _navigateToLogin() {
    // Although the button is disabled, this is an extra safety check
    if (_isOffline) {
      _showStatusSnackbar("Cannot navigate. Please connect to the internet.", true);
      return;
    }
    Navigator.pushNamed(context, '/login');
  }

  void _navigateToSignup() {
    // Although the button is disabled, this is an extra safety check
    if (_isOffline) {
      _showStatusSnackbar("Cannot navigate. Please connect to the internet.", true);
      return;
    }
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    // Determine button appearance based on connection status
    final buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: _isOffline ? Colors.grey : const Color(0xFFE4572E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      );
    
    final outlineButtonStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: _isOffline ? Colors.grey : const Color(0xFFE4572E), width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    final outlineButtonTextStyle = TextStyle(
      fontSize: 16, 
      color: _isOffline ? Colors.grey : const Color(0xFFE4572E),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E2),
      body: SafeArea(
        child: Center( 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Jeepney image (kept original style)
              Image.asset(
                "assets/jeepney.png",
                height: 102.36,
                width: 186.74,
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Malaus kayu!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE4572E),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let JeepMiyabe guide your way.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 40),

              // Log In button (DISABLED and GRAYED when offline)
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  style: buttonStyle,
                  // Disable if offline (onPressed: null)
                  onPressed: _isOffline ? null : _navigateToLogin, 
                  child: const Text(
                    "Log In",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Sign Up button (DISABLED and GRAYED when offline)
              SizedBox(
                width: 250,
                child: OutlinedButton(
                  style: outlineButtonStyle,
                  // Disable if offline (onPressed: null)
                  onPressed: _isOffline ? null : _navigateToSignup, 
                  child: Text(
                    "Sign up!",
                    style: outlineButtonTextStyle,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),

              // --- OFFLINE WARNING BANNER ---
              if (_isOffline)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    "❌ No internet connection. Please connect to Wi-Fi or cellular data to continue.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE4572E), // Primary accent color for visibility
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
