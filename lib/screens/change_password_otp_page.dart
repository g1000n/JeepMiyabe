import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart'; // Ensure this is imported

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);

class ChangePasswordOTPPage extends StatefulWidget {
  final String newPassword;
  const ChangePasswordOTPPage({super.key, required this.newPassword});

  @override
  State<ChangePasswordOTPPage> createState() => _ChangePasswordOTPState();
}

class _ChangePasswordOTPState extends State<ChangePasswordOTPPage> {
  final _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verifyOTPAndUpdate() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;  // Ensure 6-digit OTP
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: Supabase.instance.client.auth.currentUser!.email!,
        token: otp,
        type: OtpType.email,
      );
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: widget.newPassword),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));  // Or your dashboard route
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,  // Match MFA page background
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: kPrimaryColor,  // Themed app bar
      ),
      body: SafeArea(  // SafeArea for edge-to-edge compatibility
        child: Padding(
          padding: const EdgeInsets.all(24),  // Consistent padding like MFA
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instructional Text (like MFA page)
              const Text(
                "Enter the 6-digit code sent to your email",
                style: TextStyle(
                  fontSize: 18,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // PinCodeTextField (matches MFA page)
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  fieldWidth: 45,
                  inactiveColor: kPrimaryColor.withOpacity(0.5),
                  activeColor: kPrimaryColor,
                  selectedColor: kPrimaryColor,
                ),
                onChanged: (_) {},  // Can add logic if needed
                onCompleted: (otp) => _verifyOTPAndUpdate(),  // Auto-verify on complete
              ),
              const SizedBox(height: 20),

              // Verify Button (styled like MFA)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : _verifyOTPAndUpdate,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify Code",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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