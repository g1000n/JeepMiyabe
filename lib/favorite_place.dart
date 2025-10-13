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

// 🛑 FIX APPLIED HERE 🛑
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
    
    // If successful, execution continues past this block.

  } on PostgrestException catch (e) {
    // Catch a specific database error (e.g., table not found, RLS policy denied)
    // We re-throw it so the calling function (map_screen.dart) can handle the error.
    throw Exception('Supabase Database Error: ${e.message}');
  } catch (e) {
    // Catch general errors (e.g., network timeout)
    throw Exception('Failed to save favorite due to an unexpected error: $e');
  }
}