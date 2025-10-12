// data_preprocessor.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart' show Color; 
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Import all necessary local files (assuming they are in lib/)
import 'lib/graph_models.dart';
import 'lib/geo_utils.dart'; // Required for calculatePolylineDistance used during graph construction

// --- GLOBAL NETWORK STATE (Initialized directly to avoid 'late' and global function call issues) ---
Map<String, Node> allNodes = {};
JeepneyGraph jeepneyNetwork = JeepneyGraph(nodes: allNodes, adjacencyList: {});

/// Resets the global network state by clearing the nodes and creating a new graph instance.
void _resetGlobals() {
  allNodes.clear();
  jeepneyNetwork = JeepneyGraph(nodes: allNodes, adjacencyList: {}); 
}

// --- GRAPH CONSTRUCTION LOGIC ---

/// Performs the heavy computation: reading raw data, building nodes, edges, 
/// and calculating walking/transfer connections.
Future<void> buildJeepneyNetworkFromRaw(
  Map<String, dynamic> rawNodesData, 
  List<dynamic> rawRoutesData,
) async {
  _resetGlobals();
  final Map<String, List<Edge>> adjacencyList = {};
  
  // 1. Build all permanent nodes
  for (var entry in rawNodesData.entries) {
    final id = entry.key;
    final data = entry.value;
    allNodes[id] = Node(
      id: id,
      name: data['name'] ?? id,
      position: LatLng(data['lat'] as double, data['lng'] as double),
    );
    // Initialize adjacency list entry for every node
    adjacencyList[id] = [];
  }

  // 2. Build all jeepney edges
  for (var routeData in rawRoutesData) {
    // Convert color hex string to a Flutter Color object
    final Color routeColor = Color(int.parse('FF${routeData['color']}', radix: 16));
    
    // Iterate over segments of the route
    final List<dynamic> segments = routeData['segments'] ?? [];
    for (var segment in segments) {
      final startId = segment['start_node_id'] as String;
      final endId = segment['end_node_id'] as String;
      
      // 🎯 FIX 1: Look up the Node objects to get their names
      final startNode = allNodes[startId];
      final endNode = allNodes[endId];

      if (startNode == null || endNode == null) {
        print('Warning: Skipping segment for unknown node ID: $startId or $endId');
        continue;
      }

      // This is a local helper needed to deserialize the flat polyline points
      List<LatLng> toLatLngList(List<double> flatList) {
          List<LatLng> points = [];
          for (int i = 0; i < flatList.length; i += 2) {
            points.add(LatLng(flatList[i], flatList[i+1]));
          }
          return points;
      }
      final polylineCoords = toLatLngList(List<double>.from(segment['polyline'] as List));

      // Calculate distance and duration from polyline length
      final distanceKm = calculatePolylineDistance(polylineCoords); 
      
      // Assuming average jeepney speed of 20 km/h (3 min/km)
      const double JEEPNEY_SPEED_KPH = 20.0;
      final durationMin = (distanceKm / JEEPNEY_SPEED_KPH) * 60;
      
      final edge = Edge(
        id: '${routeData['id']}_${startId}_$endId',
        startNodeId: startId,
        endNodeId: endId,
        
        // 🎯 FIX 2: Pass the required Node names from the lookup
        startNodeName: startNode.name,
        endNodeName: endNode.name,

        type: EdgeType.JEEPNEY, 
        distance: distanceKm, 
        time: durationMin, 
        
        routeId: routeData['id'] as String,
        routeName: routeData['name'] as String,
        routeColor: routeColor,
        routeColorName: routeData['color'] as String,
        polylinePoints: polylineCoords,
      );

      // Add edge to the adjacency list
      adjacencyList.putIfAbsent(startId, () => []).add(edge);
    }
  }

  // 3. Add walking/transfer edges (If needed, the logic would go here)

  jeepneyNetwork = JeepneyGraph(nodes: allNodes, adjacencyList: adjacencyList);
}


// --- UTILITY SCRIPT MAIN FUNCTION ---

/// The file path for the final, optimized network data.
const String OUTPUT_FILE_PATH = 'assets/data/optimized_network_graph.json';

// Simple function to mock the AssetBundle functionality for standalone script
Future<String> _loadAsset(String path) async {
  try {
    return await File(path).readAsString();
  } catch (e) {
    print('ERROR: Could not find or read file at $path. Ensure path is correct relative to the script.');
    rethrow;
  }
}

// Mock of the raw data loader from RouteDataLoader (needed only to run the builder)
Future<Map<String, dynamic>> _loadRawJeepneyData(bool useLocal) async {
  if (!useLocal) {
    throw UnimplementedError("Remote loading not implemented in preprocessor.");
  }
  
  // NOTE: Assuming your raw data files are in 'assets/data/'
  final String rawNodesJson = await _loadAsset('assets/data/raw_nodes.json');
  final String rawRoutesJson = await _loadAsset('assets/data/raw_routes.json');
  
  // NOTE: The rawRoutesJson should be a List, not a Map
  return {
    'nodes': jsonDecode(rawNodesJson),
    'routes': jsonDecode(rawRoutesJson),
  };
}

/// Main function to execute the pre-processing logic.
void main() async {
  print('--- Starting JeepMiyabe Network Pre-processor ---');
  
  try {
    // 1. Load the raw data and build the full graph (the slow process)
    print('1. Loading raw data and building the full graph in memory...');
    final startTime = DateTime.now();
    
    final rawData = await _loadRawJeepneyData(true);
    await buildJeepneyNetworkFromRaw(
      rawData['nodes'], 
      rawData['routes'],
    );
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print('   -> Graph built successfully in ${duration.inSeconds} seconds.');
    print('   -> Total nodes: ${allNodes.length}');
    print('   -> Total unique edges in adjacency list: ${jeepneyNetwork.adjacencyList.values.fold(0, (sum, list) => sum + list.length)}');


    // 2. Prepare the data structure for serialization using the `toJson` extensions
    print('2. Serializing the optimized graph structure to JSON...');
    
    final Map<String, dynamic> serializedData = {
      // Serialize all nodes
      'allNodes': allNodes.map((id, node) => MapEntry(id, node.toJson())),
      // Serialize the graph's adjacency list (The core data for pathfinding)
      'adjacencyList': jeepneyNetwork.adjacencyList.map((nodeId, edges) {
        // Use the EdgeJson extension's toJson() method
        return MapEntry(nodeId, edges.map((edge) => (edge as Edge).toJson()).toList());
      }),
      'metadata': {
        'timestamp': DateTime.now().toIso8601String(),
        'source': 'data_preprocessor.dart',
      },
    };

    // Use jsonEncode to convert the Map to a string
    final String jsonString = jsonEncode(serializedData);

    // 3. Write the JSON string to the output file
    final outputFile = File(OUTPUT_FILE_PATH);
    if (!await outputFile.parent.exists()) {
      await outputFile.parent.create(recursive: true);
    }
    await outputFile.writeAsString(jsonString);

    print('3. Success! Optimized graph saved to: $OUTPUT_FILE_PATH');
    print('   -> File size: ${outputFile.lengthSync() / 1024} KB');

  } catch (e) {
    print('\n--- ERROR During Pre-processing ---');
    print('Ensure you run this script from the root of your project and that assets/data/raw_nodes.json and assets/data/raw_routes.json exist.');
    print('Error type: ${e.runtimeType}, Details: $e');
  }
  
  print('-----------------------------------------');
}