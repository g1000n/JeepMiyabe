import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class FavoritePlace {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  FavoritePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  LatLng get position => LatLng(latitude, longitude);

  // Serialization for backend/local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
      };

  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        description: json['description'] as String?,
      );
}

// Function to save a new favorite place to Supabase
Future<void> saveFavoriteToBackend(FavoritePlace favorite, String userId) async {
  try {
    // Attempt the insert. On success, it returns or resolves without error.
    await supabase.from('favorites').insert({
      'user_id': userId,
      'name': favorite.name,
      'latitude': favorite.latitude,
      'longitude': favorite.longitude,
      'description': favorite.description,
    });
  } on PostgrestException catch (e) {
    // Catch a specific database error (e.g., table not found, RLS policy denied)
    throw Exception('Supabase Database Error: ${e.message}');
  } catch (e) {
    // Catch general errors (e.g., network timeout)
    throw Exception('Failed to save favorite due to an unexpected error: $e');
  }
}

// Function to delete a favorite place from Supabase
Future<void> deleteFavoriteFromBackend(
    double latitude, double longitude, String userId) async {
  if (userId.isEmpty) {
    throw Exception('User is not authenticated.');
  }

  try {
    // Attempt the delete operation, matching by user_id and coordinates.
    final result = await supabase
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('latitude', latitude)
        .eq('longitude', longitude)
        .select(); // Use .select() to confirm rows were deleted

    if (result.isEmpty) {
      print('Warning: Attempted to delete a non-existent favorite for user $userId.');
    } else {
      print('Successfully deleted ${result.length} favorite place(s).');
    }
  } on PostgrestException catch (e) {
    throw Exception('Supabase Database Error (Delete): ${e.message}');
  } catch (e) {
    throw Exception('Failed to delete favorite due to an unexpected error: $e');
  }
}

// 🚀 NEW FUNCTION: Checks if a place is favorited by the user
Future<bool> isFavoriteInBackend(
    double latitude, double longitude, String userId) async {
  if (userId.isEmpty) {
    return false;
  }

  try {
    // Attempt to fetch one record matching the user ID and coordinates
    final response = await supabase
        .from('favorites')
        .select('id') // Only fetch the ID for efficiency
        .eq('user_id', userId)
        .eq('latitude', latitude)
        .eq('longitude', longitude);

    // If the response list is NOT empty, a matching favorite exists
    return response.isNotEmpty;
  } on PostgrestException catch (e) {
    print('Supabase check favorite error: ${e.message}');
    return false; // Assume not favorite on error
  } catch (e) {
    print('Unexpected error checking favorite: $e');
    return false;
  }
}