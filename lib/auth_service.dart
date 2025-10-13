import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns the current user's ID from Supabase authentication, or null if not logged in.
String? getCurrentUserId() {
  final user = Supabase.instance.client.auth.currentUser;
  return user?.id;
}
