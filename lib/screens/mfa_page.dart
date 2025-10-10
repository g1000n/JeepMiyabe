import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/auth_storage.dart';  // Adjust path to your AuthStorage file (from MFA cooldown solution)

class MFAPage extends StatefulWidget {
  final String email;
  const MFAPage({super.key, required this.email});

  @override
  State<MFAPage> createState() => _MFAPageState();
}

class _MFAPageState extends State<MFAPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  bool _canResend = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // Start resend countdown
  void _startCountdown() {
    setState(() {
      _canResend = false;
      _secondsLeft = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // Resend OTP via Supabase
  Future<void> _resendOTP() async {
    setState(() {
      _loading = true;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(email: widget.email);
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A new OTP has been sent to your email."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to resend OTP. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // Verify OTP
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) return;

    setState(() {
      _loading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      if (response.user != null && mounted) {
        // Save MFA success for 7-day cooldown
        await AuthStorage.saveMFASuccess();

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid or expired code."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "OTP verification failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP verification failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Enter the 6-digit verification code sent to ${widget.email}',
                child: const Text(
                  "Enter the 6-digit code sent to your email",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFFE4572E),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // 6 separate OTP boxes with auto-verify on complete
              Semantics(
                label: 'OTP input fields',
                child: PinCodeTextField(
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
                    inactiveColor: const Color(0xFFE4572E).withOpacity(0.5),
                    activeColor: const Color(0xFFE4572E),
                    selectedColor: const Color(0xFFE4572E),
                  ),
                  onChanged: (_) {}, // Optional: Could add real-time validation here if needed
                  onCompleted: (otp) => _verifyOTP(), // Auto-verify when 6 digits are entered
                ),
              ),
              const SizedBox(height: 20),

              // Themed Verify button
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
                  onPressed: _loading ? null : _verifyOTP,
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
              const SizedBox(height: 16),

              // Resend OTP countdown
              TextButton(
                onPressed: _canResend && !_loading ? _resendOTP : null,
                child: Text(
                  _canResend
                      ? "Resend OTP"
                      : "Resend in $_secondsLeft s",
                  style: TextStyle(
                    color:
                        _canResend ? const Color(0xFFE4572E) : Colors.grey[600],
                    fontWeight: FontWeight.bold,
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
