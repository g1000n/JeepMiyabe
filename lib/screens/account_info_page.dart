import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_password_otp_page.dart'; // Import the OTP page

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();
  String? _currentUsername;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', user.id)
          .single();
      setState(() {
        _currentUsername = response['username'] as String?;
        _usernameController.text = _currentUsername ?? '';
      });
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'username': newUsername})
          .eq('id', user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    }
  }

  Future<void> _changePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: Supabase.instance.client.auth.currentUser!.email!,
        password: oldPassword,
      );
      await Supabase.instance.client.auth.signInWithOtp(
        email: Supabase.instance.client.auth.currentUser!.email!,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChangePasswordOTPPage(newPassword: newPassword),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Account Information'),
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Current Username: $_currentUsername',
              style: const TextStyle(fontSize: 16, color: kPrimaryColor),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'New Username',
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updateUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Username'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, color: kPrimaryColor, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              controller: _oldPasswordController,
              decoration: InputDecoration(
                labelText: 'Old Password',
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newPasswordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmNewPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}