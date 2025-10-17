// lib/widgets/route_details_sheet.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:jeepmiyabe/favorite_place.dart'; // Ensure this import path is correct
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../auth_service.dart'; // Ensure this import path is correct
import '../route_segment.dart'; // Ensure this import path is correct
import '../geo_utils.dart'; // Assume getApproximateLocationName is here
import 'instruction_tile.dart'; // Import the extracted tile widget

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kBackgroundColor = Color(0xFFFDF8E2);
final Uuid _uuid = const Uuid();

/// Displays the detailed route instructions sheet with 'Go Now' and 'Favorite' functionality.
Future<void> showRouteDetailsSheet({
  required BuildContext context,
  required List<RouteSegment> currentRoute,
  required LatLng? endPoint,
  required double totalTime,
  required double totalDistance,
  required bool isFavoriteTo,
  required Function(bool) onFavoriteToggle,
  required VoidCallback onGoNowPressed,
}) async {
  final userId = getCurrentUserId();
  
  // Use a temporary local variable initialized with the parent's state
  bool currentFavoriteState = isFavoriteTo;

  // Before showing the sheet, check/sync the actual favorite status if the endpoint is set
  if (userId != null && endPoint != null) {
    try {
      // NOTE: Assumes 'isFavoriteInBackend' is defined in auth_service.dart
      currentFavoriteState = await isFavoriteInBackend(
        endPoint.latitude,
        endPoint.longitude,
        userId,
      );
      // Immediately update parent state for the initial build of the MapScreen later
      onFavoriteToggle(currentFavoriteState);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      currentFavoriteState = false;
    }
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: kBackgroundColor,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            color: kBackgroundColor,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Time: ${totalTime.toStringAsFixed(0)} mins',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Distance: ${totalDistance.toStringAsFixed(1)} km',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: currentRoute.length,
                    itemBuilder: (context, index) {
                      // Uses the InstructionTile widget
                      return InstructionTile(segment: currentRoute[index]);
                    },
                  ),
                ),
                // CRITICAL: StatefulBuilder to manage the favorite button state
                StatefulBuilder(
                  builder: (BuildContext context, StateSetter modalSetState) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.directions_run),
                              label: const Text('Go Now'),
                              onPressed: () {
                                Navigator.pop(context);
                                onGoNowPressed();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentFavoriteState
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(currentFavoriteState
                                ? Icons.star
                                : Icons.star_border),
                            label: const Text('Favorite To:'),
                            onPressed: () async {
                              final shouldFavorite = !currentFavoriteState;

                              if (userId == null || endPoint == null) {
                                if (userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Error: You must be logged in to save favorites.')),
                                  );
                                }
                                return;
                              }

                              try {
                                if (shouldFavorite) {
                                  final favorite = FavoritePlace(
                                    id: _uuid.v4(),
                                    // NOTE: Assumes 'getApproximateLocationName' is defined in geo_utils.dart
                                    name: getApproximateLocationName(endPoint),
                                    latitude: endPoint.latitude,
                                    longitude: endPoint.longitude,
                                    description: 'Saved from route',
                                  );
                                  // NOTE: Assumes 'saveFavoriteToBackend' is defined in auth_service.dart
                                  await saveFavoriteToBackend(favorite, userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Added to favorites!')),
                                  );
                                } else {
                                  // NOTE: Assumes 'deleteFavoriteByCoordinates' is defined in auth_service.dart
                                  await deleteFavoriteByCoordinates(
                                      endPoint.latitude,
                                      endPoint.longitude,
                                      userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Removed from favorites!')),
                                  );
                                }

                                // Update both modal's state and parent's state
                                modalSetState(() {
                                  currentFavoriteState = shouldFavorite;
                                });
                                onFavoriteToggle(shouldFavorite);

                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to process favorite: ${e.toString().split(':').last.trim()}'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}