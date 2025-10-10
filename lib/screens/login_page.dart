import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart';  // Adjust path to your AuthStorage file (from MFA cooldown solution)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();  // Added for form validation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _errorMessage;
  bool _loading = false;
  bool _obscurePassword = true; 

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;  // Validate form before proceeding

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // STEP 1: Check email and pass
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        setState(() => _errorMessage = "Email or password is incorrect.");
      } else if (response.user!.emailConfirmedAt == null) {
        setState(() => _errorMessage = "Please verify your email before logging in.");
      } else {
        // STEP 2: Check if MFA cooldown is active (skip OTP)
        final mfaCooldownActive = await AuthStorage.isMFACooldownActive();
        if (mfaCooldownActive) {
          // Skip MFA, go directly to dashboard
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Welcome back! Skipping verification for trusted device."),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // STEP 3: Trigger MFA (email OTP) as usual
          await Supabase.instance.client.auth.signInWithOtp(email: email);
          // Navigate to MFA screen
          Navigator.pushNamed(context, '/mfa', arguments: email);
        }
      }
    } on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        setState(() => _errorMessage = "Email or password is incorrect.");
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      setState(() => _errorMessage = "Login failed. Please try again.");
    }

    setState(() => _loading = false);
  }
  
  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE4572E), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFE4572E), width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E2),
      body: SafeArea(
        child: SingleChildScrollView(  // Added for keyboard handling on small screens
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(  // Wrapped Column in Form for validation
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFE4572E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),

                // Jeepney Image
                Image.asset("assets/jeepney.png", height: 120),
                const SizedBox(height: 20),

                const Text(
                  "Masanting akit dakang balik.",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE4572E),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Welcome back!", 
                  style: TextStyle(color: Color(0xFFE4572E)),  // Standardized to primary color
                ),
                const SizedBox(height: 30),

                // Email
                TextFormField(  // Changed from TextField to TextFormField for validation
                  controller: _emailController,
                  decoration: _inputDecoration("Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your email";
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,  // Better UX for email input
                ),
                const SizedBox(height: 15),

                // Password w/ toggle
                TextFormField(  // Changed from TextField to TextFormField
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    "Password",
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFE4572E),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Enter your password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ],

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4572E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Log In",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? ", style: TextStyle(color: Color(0xFFE4572E))),  // Standardized color
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        "Sign up",
                        style: TextStyle(
                          color: Color(0xFFE4572E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}