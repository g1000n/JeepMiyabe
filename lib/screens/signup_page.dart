import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _passwordHidden = true; // password visibility toggle
  bool _confirmPasswordHidden = true; // confirm password visibility toggle
  bool _loading = false; // loading state

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.flutterdemo://login-callback/',
      );

      if (response.user != null) {
        // Insert into profile table
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
          //TODO: add password field if needed
        });

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/verify');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _loading = false);
  }

  //Style
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFFE4572E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),

                // Jeepney image
                Image.asset(
                  "assets/jeepney.png",
                  height: 120,
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Umpisan ta ne!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE4572E),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  "Create your JeepMiyabe account today.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 30),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email"),
                  validator: (value) => (value == null || value.isEmpty) ? "Enter your email" : null,
                ),
                const SizedBox(height: 15),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration("Username"),
                  validator: (value) => (value == null || value.isEmpty) ? "Enter your username" : null,
                ),
                const SizedBox(height: 15),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _passwordHidden,
                  decoration: _inputDecoration(
                    "Password",
                    suffix: IconButton(
                      icon: Icon(
                        _passwordHidden ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFE4572E),
                      ),
                      onPressed: () => setState(() => _passwordHidden = !_passwordHidden),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? "Enter your password" : null,
                ),
                const SizedBox(height: 15),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _confirmPasswordHidden,
                  decoration: _inputDecoration(
                    "Confirm Password",
                    suffix: IconButton(
                      icon: Icon(
                        _confirmPasswordHidden ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFFE4572E),
                      ),
                      onPressed: () => setState(() => _confirmPasswordHidden = !_confirmPasswordHidden),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Confirm your password";
                    if (value != _passwordController.text) return "Passwords do not match";
                    return null;
                  },
                ),
                  const SizedBox(height: 30),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE4572E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Sign Up", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),

                // Already have account? Log In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.orange)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: Color(0xFFE4572E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
