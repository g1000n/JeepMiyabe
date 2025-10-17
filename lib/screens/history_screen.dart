import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; 
// ⚠️ IMPORTANT: Verify these paths match your project structure!
import '../../route_segment.dart'; // Assumes route_segment.dart is in the parent directory's model folder
import '../../widgets/instruction_tile.dart'; // Assumes instruction_tile.dart is in the parent directory's widgets folder

// Access the Supabase client instance
final supabase = Supabase.instance.client; 

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // --- Data Fetching Logic ---
  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      // User is not authenticated, return empty list
      return []; 
    }

    try {
      final response = await supabase
          .from('route_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false) // Show newest trips first
          .limit(50); // Fetch up to 50 recent trips
      
      return response as List<Map<String, dynamic>>; 
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  // --- UI: Displays the detailed instructions for a single trip ---
  void _showDetails(BuildContext context, Map<String, dynamic> route) {
    // 1. Get the raw JSON list from the 'route_data' column
    final List<dynamic> rawRouteData = route['route_data'] as List<dynamic>;
    
    // 2. Deserialize the raw JSON list into a List<RouteSegment> objects
    final List<RouteSegment> segments = rawRouteData
        .map((json) => RouteSegment.fromJson(json as Map<String, dynamic>))
        .toList();
    
    // Show the details in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                // Header with trip summary
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Route Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('From ${route['start_point']} to ${route['end_point']}',
                           textAlign: TextAlign.center),
                    ],
                  ),
                ),
                // List of route instructions using the custom InstructionTile
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: segments.length,
                    itemBuilder: (context, index) {
                      final segment = segments[index];
                      // 💥 Renders the segment using your custom tile widget 💥
                      return InstructionTile(segment: segment); 
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Main Build Method (Displays List of Trips) ---
  @override
  Widget build(BuildContext context) {
    const kPrimaryColor = Color(0xFFE4572E);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route History'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  snapshot.hasError 
                    ? 'Error loading history: ${snapshot.error}'
                    : 'No route history found yet. Take a trip to save one!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final history = snapshot.data!;
          
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final route = history[index];
              final DateTime timestamp = DateTime.parse(route['created_at']);
              
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    '${route['start_point']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('To: ${route['end_point']}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Trip on: ${DateFormat('MMM d, yyyy - h:mm a').format(timestamp)}', 
                           style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kPrimaryColor),
                  onTap: () => _showDetails(context, route),
                ),
              );
            },
          );
        },
      ),
    );
  }
}