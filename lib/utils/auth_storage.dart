import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _mfaKey = 'last_mfa_verified_timestamp';
  static const int cooldownDays = 7;

  /// Saves the current timestamp after successful MFA.
  static Future<void> saveMFASuccess() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mfaKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Checks if MFA cooldown is active (within 7 days).
  /// Returns true if cooldown is valid (skip MFA), false otherwise.
  static Future<bool> isMFACooldownActive() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_mfaKey);
    if (timestamp == null) return false;

    final lastVerified = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(lastVerified).inDays;

    return difference < cooldownDays;
  }

  /// Clears MFA cooldown (e.g., on logout).
  static Future<void> clearMFACooldown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mfaKey);
  }

  /// Clears all auth-related storage (optional: full logout).
  static Future<void> clearAll() async {
    await clearMFACooldown();
    // Optionally: Supabase.instance.client.auth.signOut(); // But handle in UI
  }
}