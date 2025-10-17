// favorites_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favorite_place.dart'; // Import the model and functions
// Ensure MapScreen is imported so we can access MapScreen and PreSetDestination
import 'map_screen.dart'; 

// --- CONSTANTS ---
const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);
const Color kBackgroundColor = Color(0xFFFDF8E2);

// ---------------------------------------------------------------------------
// FavoritesPage
// ---------------------------------------------------------------------------
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Use late initialization as it's set in initState
  late Future<List<FavoritePlace>> _favoritesFuture;

  // Get user ID once in the state
  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  initState() {
    super.initState();
    // Start fetching data immediately
    _favoritesFuture = _fetchFavorites();
  }

  // Wrapper function to fetch favorites, checking for a valid user
  Future<List<FavoritePlace>> _fetchFavorites() async {
    if (_userId.isEmpty) {
      // Return an empty list immediately if the user is not logged in
      return Future.value([]);
    }
    // Call the function from favorite_place.dart
    try {
      // This line was previously causing an error if the import or function was missing.
      // NOTE: This assumes 'fetchFavoritesForUser' is defined in favorite_place.dart
      return await fetchFavoritesForUser(_userId);
    } catch (e) {
      // If there is an error during fetch, return empty list and print error
      print('Error fetching favorites: $e');
      // Re-throw the error so FutureBuilder can handle it gracefully.
      throw e;
    }
  }

  // Function to refresh the list of favorites
  void _refreshFavorites() {
    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }

  /// 🌟 UPDATED HANDLER: Passes the favorite location as the destination (`toPlace`).
  void _onFavoriteTapped(FavoritePlace favorite) {
    // Navigate to the MapScreen and pass the favorite's coordinates
    final newMapScreen = MapScreen(
      // Set initial map focus near the favorite location
      initialLatitude: favorite.latitude,
      initialLongitude: favorite.longitude,
      initialZoom: 17.0,
      
      // 🌟 CRITICAL: Pass the favorite as the pre-set destination 🌟
      toPlace: PreSetDestination(
        name: favorite.name,
        latitude: favorite.latitude,
        longitude: favorite.longitude,
      ),
    );
    
    // NOTE on Navigation: 
    // If MapScreen is part of a BottomNavigationBar, 
    // the true fix is to use Navigator.pop() and pass the 'toPlace' back 
    // to the parent widget which then switches the tab and passes data.
    // However, using pushReplacement here is a common way to transition 
    // directly to a full-screen map view.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => newMapScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorite Places',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        // Assuming this is a page that should be navigated back from
        automaticallyImplyLeading: true, 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshFavorites, // Refresh button
            tooltip: 'Refresh Favorites',
          ),
        ],
      ),
      backgroundColor: kBackgroundColor,

      // Use FutureBuilder to handle the asynchronous data fetching
      body: FutureBuilder<List<FavoritePlace>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor));
          }

          // 2. Error State
          if (snapshot.hasError) {
            // Note: Error is handled in _fetchFavorites and re-thrown
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error loading favorites. Please try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
            ));
          }

          // 3. Data Loaded State
          final favorites = snapshot.data ?? [];

          // 3a. Empty State
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_border,
                      size: 80, color: kPrimaryColor),
                  const SizedBox(height: 10),
                  Text(
                    _userId.isEmpty
                        ? 'You must be logged in to view favorites.'
                        : 'You haven\'t saved any favorites yet.',
                    style: const TextStyle(color: kPrimaryColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 3b. List View
          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              return _buildFavoriteCard(context, favorite);
            },
          );
        },
      ),
    );
  }

  // Helper widget to build each favorite card
  Widget _buildFavoriteCard(BuildContext context, FavoritePlace favorite) {
    return Card(
      color: kCardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () => _onFavoriteTapped(favorite),
        leading: const Icon(Icons.location_pin, color: Colors.white, size: 30),
        title: Text(
          favorite.name,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        subtitle: Text(
          favorite.description ??
              'Lat: ${favorite.latitude.toStringAsFixed(4)}, Lon: ${favorite.longitude.toStringAsFixed(4)}',
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.white70),
          onPressed: () =>
              _confirmDelete(context, favorite), // Triggers delete flow
          tooltip: 'Delete Favorite',
        ),
      ),
    );
  }

  // Confirmation dialog for deleting a favorite
  void _confirmDelete(BuildContext context, FavoritePlace favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite?'),
        content: Text(
            'Are you sure you want to remove "${favorite.name}" from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: kPrimaryColor)),
          ),
          TextButton(
            onPressed: () async {
              // 1. Close dialog immediately
              Navigator.of(context).pop();

              // 2. Perform delete operation
              try {
                // NOTE: This assumes 'deleteFavoriteFromBackendById' is defined in favorite_place.dart
                await deleteFavoriteFromBackendById(favorite.id, _userId);

                // 3. Show success message and refresh UI
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${favorite.name} removed.'),
                      backgroundColor: Colors.green));
                }
                // *** CRITICAL LINE: Refresh the list ***
                _refreshFavorites();
              } catch (e) {
                // 4. Show error message on failure
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text('Failed to delete favorite: ${e.toString()}'),
                      backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}