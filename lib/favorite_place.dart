// lib/favorite_place.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // REQUIRED for generating a unique 'id'
import 'package:flutter/foundation.dart'; // For debugPrint

// Initialize Supabase client
final SupabaseClient supabase = Supabase.instance.client;

// ---------------------------------------------------------------------------
// FAVORITE PLACE MODEL
// ---------------------------------------------------------------------------

class FavoritePlace {
  // id corresponds to the UUID primary key in the 'favorites' table
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final DateTime createdAt;

  FavoritePlace({
    required this.id, // This is the corrected named parameter
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    // Provide a default for createdAt if not passed
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();

  // Factory method to create a FavoritePlace from a Supabase row (Map)
  factory FavoritePlace.fromMap(Map<String, dynamic> data) {
    return FavoritePlace(
      // The database column names are used here:
      id: data['id'] as String,
      name: data['name'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      description: data['description'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String).toLocal(),
    );
  }
}

// ---------------------------------------------------------------------------
// SUPABASE SERVICE FUNCTIONS (Used by favorites_page.dart & map_screen.dart)
// ---------------------------------------------------------------------------

/// Fetches all favorite places for a given user ID.
Future<List<FavoritePlace>> fetchFavoritesForUser(String userId) async {
  if (userId.isEmpty) {
    return [];
  }

  try {
    final List<Map<String, dynamic>> response = await supabase
        .from('favorites') // Assuming the table name is 'favorites'
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map(FavoritePlace.fromMap).toList();
  } on PostgrestException catch (e) {
    debugPrint('Supabase Fetch Error: ${e.message}');
    throw Exception('Failed to load favorites from database.');
  } catch (e) {
    debugPrint('General Fetch Error: $e');
    rethrow;
  }
}

/// Checks if a location (by coordinates) is already favorited by the user.
Future<bool> isFavoriteInBackend(double lat, double lon, String userId) async {
  // Use the helper function to check existence
  final id = await fetchFavoriteIdByCoordinates(lat, lon, userId);
  return id != null;
}

/// Saves a FavoritePlace object to the backend.
Future<void> saveFavoriteToBackend(
    FavoritePlace favorite, String userId) async {
  try {
    final Map<String, dynamic> data = {
      // NOTE: Supabase can auto-generate the ID, but since you are passing
      // the UUID from the app, include it here:
      'id': favorite.id,
      'user_id': userId,
      'name': favorite.name,
      'latitude': favorite.latitude,
      'longitude': favorite.longitude,
      'description': favorite.description,
    };
    await supabase.from('favorites').insert(data);
  } on PostgrestException catch (e) {
    throw Exception('Supabase Error saving favorite: ${e.message}');
  } catch (e) {
    throw Exception('Failed to save favorite: $e');
  }
}

/// Fetches the unique ID of a favorite place based on coordinates and user ID.
/// This is a private helper function used for deletion.
Future<String?> fetchFavoriteIdByCoordinates(
    double lat, double lon, String userId) async {
  // Important: Round coordinates to avoid floating-point errors when searching
  final roundedLat = double.parse(lat.toStringAsFixed(6));
  final roundedLon = double.parse(lon.toStringAsFixed(6));

  try {
    final response = await supabase
        .from('favorites')
        .select('id') // Select the unique ID
        .eq('user_id', userId)
        .eq('latitude', roundedLat)
        .eq('longitude', roundedLon)
        .limit(1);

    if (response.isNotEmpty) {
      return response.first['id'] as String;
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching favorite ID by coordinates: $e');
    return null;
  }
}

/// Deletes a favorite place entry based on its unique ID.
Future<void> deleteFavoriteFromBackendById(
    String favoriteId, String userId) async {
  try {
    await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('id', favoriteId); // <-- Delete by unique ID
  } on PostgrestException catch (e) {
    throw Exception('Supabase Error deleting favorite by ID: ${e.message}');
  } catch (e) {
    throw Exception('Failed to delete favorite by ID: $e');
  }
}

// 🌟 FIX: NEW COORDINATE-BASED DELETE FUNCTION FOR MAPSCREEN 🌟
/// Deletes a favorite place entry based on latitude, longitude, and user ID.
/// This function is intended to be called by MapScreen for un-favoriting.
Future<void> deleteFavoriteByCoordinates(
    double lat, double lon, String userId) async {
  // 1. Find the unique ID based on the coordinates
  final favoriteId = await fetchFavoriteIdByCoordinates(lat, lon, userId);

  if (favoriteId != null) {
    // 2. Use the ID to perform the actual deletion
    await deleteFavoriteFromBackendById(favoriteId, userId);
  }
  // If favoriteId is null, it means the item wasn't found,
  // so there's nothing to delete (it silently succeeds).
}
