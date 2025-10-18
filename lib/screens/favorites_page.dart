import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../favorite_place.dart';
import 'map_screen.dart';

const Color kPrimaryColor = Color(0xFFE4572E);
const Color kCardColor = Color(0xFFFC775C);
const Color kBackgroundColor = Color(0xFFFDF8E2);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoritePlace>> _favoritesFuture;

  final String _userId = Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  initState() {
    super.initState();
    _favoritesFuture = _fetchFavorites();
  }

  Future<List<FavoritePlace>> _fetchFavorites() async {
    if (_userId.isEmpty) {
      return Future.value([]);
    }
    try {
      return await fetchFavoritesForUser(_userId);
    } catch (e) {
      throw e;
    }
  }

  void _refreshFavorites() {
    setState(() {
      _favoritesFuture = _fetchFavorites();
    });
  }

  void _onFavoriteTapped(FavoritePlace favorite) {
    final destination = PreSetDestination(
      name: favorite.name,
      latitude: favorite.latitude,
      longitude: favorite.longitude,
    );
    
    Navigator.of(context).pop(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Favorite Places',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        automaticallyImplyLeading: true, 
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshFavorites,
            tooltip: 'Refresh Favorites',
          ),
        ],
      ),
      backgroundColor: kBackgroundColor,

      body: FutureBuilder<List<FavoritePlace>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text('Error loading favorites. Please try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16)),
            ));
          }

          final favorites = snapshot.data ?? [];

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
              _confirmDelete(context, favorite),
          tooltip: 'Delete Favorite',
        ),
      ),
    );
  }

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
              Navigator.of(context).pop();

              try {
                await deleteFavoriteFromBackendById(favorite.id, _userId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${favorite.name} removed.'),
                      backgroundColor: Colors.green));
                }
                _refreshFavorites();
              } catch (e) {
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
