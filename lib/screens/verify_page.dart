import 'package:flutter/material.dart';

class VerifyPage extends StatelessWidget {
    const VerifyPage({super.key});

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            backgroundColor: const Color(0xFFFDF8E2),
            body: SafeArea(
                child: Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                // Jeepney image
                                Image.asset(
                                    "assets/jeepney.png",
                                    height: 120,
                                ),
                                const SizedBox(height: 20),

                                // Title
                                const Text(
                                    "Account Created!",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE4572E),
                                    ),
                                ),
                                const SizedBox(height: 8),

                                const Text(
                                    "Please check your email to verify your account before logging in.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange,
                                    ),
                                ),
                                const SizedBox(height: 40),

                                // Back to welcome page
                                SizedBox(
                                    width: 250,
                                    child: ElevatedButton(
                                        onPressed: () {
                                            Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/welcome',
                                                (route) => false,
                                            );
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE4572E),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                        ),
                                        child: const Text(
                                            "Back to Login/Sign Up Page",
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                        ),
                                    ),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}