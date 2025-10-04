import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


//TODO: FIX SIZING
class _LoginPageState extends State<LoginPage> {
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    String? _errorMessage;
    bool _loading = false;
    bool _obscurePassword = true; 
 
    Future<void> _login() async {
        setState(() {
        _loading = true;
        _errorMessage = null;
        });

        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        try {
            //STEP 1: Check email and pass
            final response = await Supabase.instance.client.auth.signInWithPassword(
                email: email,
                password: password,
            );

            if (response.user == null) {
                setState(() => _errorMessage = "Email or password is incorrect.");
            } else if (response.user!.emailConfirmedAt == null){
                setState(() => _errorMessage = "Please verify your email before logging in.");
            } else {
                //STEP 2: Trigger MFA (email OTP)
                await Supabase.instance.client.auth.signInWithOtp(email: email);

                // Step 3: Navigate to MFA screen
                Navigator.pushNamed(context, '/mfa', arguments: email);
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
    
    InputDecoration _inputDecoration(String hint, {Widget? suffix}){
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
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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

                            //Jeepney Image
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
                            const Text("Welcome back!", style: TextStyle(color: Colors.orange)),
                            const SizedBox(height: 30),

                            //Email
                            TextField(
                                controller: _emailController,
                                decoration: _inputDecoration("Email"),
                            ),
                            const SizedBox(height: 15),

                            //Password w/ toggle
                            TextField(
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

                            //Sign up link
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Text("Don’t have an account? ",
                                        style: TextStyle(color: Colors.orange)
                                    ),
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
        );
    }
}
