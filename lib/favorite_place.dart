import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// ---------------------------------------------------------------------------
// Model: FavoritePlace
// ---------------------------------------------------------------------------
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

  // Serialization for backend/local storage (converting model to JSON for API call)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
  };

  // Deserialization from JSON (creating model from API response)
  factory FavoritePlace.fromJson(Map<String, dynamic> json) => FavoritePlace(
    id: json['id'].toString(), // Ensure ID is always a string
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    description: json['description'] as String?,
  );
}

// ---------------------------------------------------------------------------
// Supabase Functions for Favorites
// ---------------------------------------------------------------------------

/// Saves a new favorite place to the Supabase 'favorites' table.
Future<void> saveFavoriteToBackend(FavoritePlace favorite, String userId) async {
  try {
    await supabase.from('favorites').insert({
      'user_id': userId,
      'name': favorite.name,
      'latitude': favorite.latitude,
      'longitude': favorite.longitude,
      'description': favorite.description,
      // 'created_at' and 'id' should be handled by Supabase database defaults
    });
  } on PostgrestException catch (e) {
    throw Exception('Supabase Database Error (Save): ${e.message}');
  } catch (e) {
    throw Exception('Failed to save favorite due to an unexpected error: $e');
  }
}

/// Deletes a favorite place from Supabase by matching coordinates and user ID.
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
        .select();

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

/// Fetches all saved favorite places for a specific user ID.
Future<List<FavoritePlace>> fetchFavoritesForUser(String userId) async {
  if (userId.isEmpty) {
    return [];
  }

  try {
    // 1. Query the 'favorites' table for records matching the user_id
    final response = await supabase
        .from('favorites')
        .select()
        .eq('user_id', userId)
        .order('id', ascending: false); // Optional: order by ID or creation date

    // 2. Map the list of JSON objects (List<Map<String, dynamic>>) to a list of FavoritePlace objects
    final favorites = (response as List).map((json) {
      return FavoritePlace.fromJson({
        ...json,
        // The factory constructor handles converting the database ID to a String
      });
    }).toList();

    return favorites;
  } on PostgrestException catch (e) {
    print('Supabase fetch favorites error: ${e.message}');
    throw Exception('Failed to load favorites: ${e.message}'); // Throw exception to be caught by FutureBuilder
  } catch (e) {
    print('Unexpected error fetching favorites: $e');
    throw Exception('An unexpected error occurred: $e');
  }
}

/// Checks if a place is favorited by the user based on coordinates.
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
        .eq('longitude', longitude)
        .limit(1); // Stop after finding the first match

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