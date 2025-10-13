import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'graph_models.dart'; // Contains Node, Edge, JeepneyGraph
import 'geo_utils.dart'; // Contains calculateDistance AND calculateJeepneyWeight
import 'pathfinding_config.dart'; // Contains configuration constants like JEEPNEY_AVG_SPEED_KM_PER_MIN

// --- GLOBAL GRAPH VARIABLES (Needed by RouteFinder) ---
// Note: We use late final because these are initialized by the static maps below.
late final Map<String, Node> allNodes = _defineAllNodes();
late final JeepneyGraph jeepneyNetwork = _buildJeepneyGraph();


// --- STEP 1: YOUR NODE DATA DEFINITION (UPDATED WITH FINALIZED COORDINATES) ---
// Function to define all your fixed locations (N01-N40).
Map<String, Node> _defineAllNodes() {
  return {
    // 1. Bayanihan area
    'N01': Node(id: 'N01', position: const LatLng(15.16815179, 120.5845928), name: 'Bayanihan Jeepney Terminal'),
    'N02': Node(id: 'N02', position: const LatLng(15.17811297, 120.5872786), name: 'Dau Access Road'),
    // 2. Clark/Sapang Bato area
    'N03': Node(id: 'N03', position: const LatLng(15.16300139, 120.5547576), name: 'Fil-Am Friendship Highway'),
    'N04': Node(id: 'N04', position: const LatLng(15.17094798, 120.5150144), name: 'Sapang Bato Barangay Hall'),
    // 3. Center/Marquee area
    'N05': Node(id: 'N05', position: const LatLng(15.16948836, 120.5893172), name: 'Balibago (Road to Dau)'),
    'N06': Node(id: 'N06', position: const LatLng(15.1625894, 120.5911397), name: 'Marlim Avenue'),
    'N07': Node(id: 'N07', position: const LatLng(15.16264112, 120.6098998), name: 'Marquee Mall by Ayala Malls'),
    'N08': Node(id: 'N08', position: const LatLng(15.15371241, 120.6048537), name: 'Pandan-Tabun Road'),
    'N09': Node(id: 'N09', position: const LatLng(15.14662662, 120.6140651), name: 'San Vicente Street, Capaya'),
    'N10': Node(id: 'N10', position: const LatLng(15.14591234, 120.6166641), name: 'Nepomuceno & Lazatin, Capaya'),
    'N11': Node(id: 'N11', position: const LatLng(15.1574636, 120.5918808), name: 'Robinsons Angeles'),
    'N12': Node(id: 'N12', position: const LatLng(15.152878, 120.592022), name: 'Marisol Roundabout'),
    // 4. Inner City/Pampang
    'N13': Node(id: 'N13', position: const LatLng(15.15213532, 120.5917486), name: 'Marisol-Pampang Jeepney Terminal'),
    'N14': Node(id: 'N14', position: const LatLng(15.14992202, 120.5842488), name: 'Arayat Blvd.'),
    'N15': Node(id: 'N15', position: const LatLng(15.14662969, 120.58514), name: 'Pampang Market'),
    'N16': Node(id: 'N16', position: const LatLng(15.14500737, 120.5887147), name: 'Henson'),
    'N17': Node(id: 'N17', position: const LatLng(15.14526038, 120.5947032), name: 'Angeles University Foundation'),
    'N18': Node(id: 'N18', position: const LatLng(15.14275954, 120.5965427), name: 'Angeles Intersection/Roundabout'),
    'N19': Node(id: 'N19', position: const LatLng(15.1388856, 120.5937331), name: '100a Santo Entiero St'),
    'N20': Node(id: 'N20', position: const LatLng(15.13869647, 120.5897663), name: 'Plaridel-Jesus Street Intersection'),
    'N21': Node(id: 'N21', position: const LatLng(15.13938125, 120.586597), name: 'Newstar Shopping Mart'),
    'N22': Node(id: 'N22', position: const LatLng(15.13695709, 120.5864965), name: '248-102 Rizal Street Ext'),
    'N23': Node(id: 'N23', position: const LatLng(15.13638498, 120.5877395), name: '304 Santo Rosario St, Angeles, Pampanga'),
    'N24': Node(id: 'N24', position: const LatLng(15.13468955, 120.5903199), name: 'Holy Rosary Parish Church'),
    'N25': Node(id: 'N25', position: const LatLng(15.13498136, 120.5928773), name: 'Lakandula Street'),
    'N26': Node(id: 'N26', position: const LatLng(15.13364388, 120.5843272), name: 'Rizal Street Ext (Edit)'),
    'N27': Node(id: 'N27', position: const LatLng(15.13440605, 120.56695), name: 'Sunset Estates'),
    'N28': Node(id: 'N28', position: const LatLng(15.12185283, 120.6007274), name: 'SM Telabastagan Terminal'),
    'N29': Node(id: 'N29', position: const LatLng(15.13414427, 120.5912911), name: 'Holy Angel University'),

    // 5. SM Telabastagan / Southern Extensions
    'N30': Node(id: 'N30', position: const LatLng(15.12701772, 120.5969441), name: 'Super 8 (San Fernando-Villa Pampang Terminal)'),
    'N31': Node(id: 'N31', position: const LatLng(15.1253262, 120.598171), name: 'Sacred Heart Medical Center'),
    'N32': Node(id: 'N32', position: const LatLng(15.12368404, 120.5990172), name: 'Chevalier School'),
    'N33': Node(id: 'N33', position: const LatLng(15.13784893, 120.5875483), name: 'Jollibee Rotonda, San Nicolas Market'),
    'N34': Node(id: 'N34', position: const LatLng(15.16821842, 120.5780195), name: 'Public Transport Terminal (SM City Clark)'),
    'N35': Node(id: 'N35', position: const LatLng(15.16649369, 120.5828515), name: 'Henson Ville Terminal'),
    'N37': Node(id: 'N37', position: const LatLng(15.15262, 120.583322), name: 'Our Lady of Fatima Parish Church'),
    'N38': Node(id: 'N38', position: const LatLng(15.15917492, 120.581245), name: 'Scots Restaurant & Cafe'),
    'N39': Node(id: 'N39', position: const LatLng(15.161209, 120.581741), name: 'Cuz Cuz Laundry and Water station'),
    'N40': Node(id: 'N40', position: const LatLng(15.129598, 120.575283), name: 'Overpass Intersection'),
    
  };
}

// --- STEP 2: JEEPNEY ROUTE EDGE DEFINITIONS (UNCHANGED) ---
final List<Map<String, dynamic>> rawEdgeDefinitions = [
  // 1. MAIN GATE - FRIENDSHIP (Sand) (Simple Route: Outbound/Inbound)
  {'route': 'MAIN GATE - FRIENDSHIP (Sand) Outbound', 'color': const Color(0xFFC2B280), 'nodes': ['N03', 'N35']},
  {'route': 'MAIN GATE - FRIENDSHIP (Sand) Inbound', 'color': const Color(0xFFC2B280), 'nodes': ['N35', 'N03']},

  // 2. C’POINT - BALIBAGO - H’WAY (Grey) (Loop Route: Single Entry)
  {'route': 'C\’POINT - BALIBAGO - H\’WAY (Grey) Loop', 'color': const Color(0xFF808080), 'nodes': ['N34', 'N01','N35','N05', 'N06', 'N11', 'N12', 'N14', 'N15', 'N16', 'N33', 'N22', 'N26', 'N23', 'N33', 'N16', 'N15', 'N14', 'N12', 'N11', 'N06', 'N05','N35','N01']},

  // 3. SM CITY - MAIN GATE – DAU (Various) (Simple Route: Outbound/Inbound)
  {'route': 'SM CITY - MAIN GATE – DAU (Various) Outbound', 'color': const Color.fromARGB(255, 63, 63, 63), 'nodes': ['N34', 'N01','N05','N02']},
  {'route': 'SM CITY - MAIN GATE – DAU (Various) Inbound', 'color': const Color.fromARGB(255, 63, 63, 63), 'nodes': ['N02', 'N05','N01','N34']},

// 4. CHECKPOINT - HENSONVILLE - HOLY (White) (Loop Route: Single Entry)
  {'route': 'CHECKPOINT - HENSONVILLE - HOLY (White) Loop', 'color': Colors.white, 'nodes': ['N35','N14','N15','N16','N33','N22','N23','N24','N29','N25','N33','N16','N15','N14']},

// 5. SAPANG BATO – ANGLES (Maroon) (Simple Route: Outbound/Inbound)
  {'route': 'SAPANG BATO – ANGLES (Maroon) Outbound', 'color': const Color(0xFF800000), 'nodes': ['N15', 'N14', 'N41','N03','N04']},
  {'route': 'SAPANG BATO – ANGLES (Maroon) Inbound', 'color': const Color(0xFF800000), 'nodes': ['N04', 'N03', 'N41', 'N14', 'N15']
},

// 6. CHECKPOINT - HOLY - HIGHWAY (Lavander) (Loop Route: Single Entry) - UPDATED
  {'route': 'CHECKPOINT - HOLY - HIGHWAY (Lavander) Loop', 'color': Colors.indigo, 'nodes': ['N01', 'N05','N06','N11','N12','N13','N16','N33','N22','N23','N24','N29','N25','N19','N18','N17','N13','N12','N11','N06','N05']},

// 7. MARISOL - PAMPANG (Green)
  {'route': 'MARISOL - PAMPANG (Green) Outbound', 'color': Colors.green, 'nodes': ['N15', 'N16','N33','N22','N23','N24','N29','N25','N19','N18','N17','N13']},
  {'route': 'MARISOL - PAMPANG (Green) Inbound', 'color': Colors.green, 'nodes': ['N13', 'N17', 'N18', 'N19','N25','N29', 'N24', 'N23', 'N22', 'N33', 'N16', 'N15']},

// 8. PANDANG - PAMPANG (Blue)
  {'route': 'PANDANG - PAMPANG (Blue) Outbound', 'color': Colors.blue, 'nodes': ['N07', 'N08','N18','N19','N33','N22','N23','N24','N29','N25','N19','N18','N08']},
  {'route': 'PANDANG - PAMPANG (Blue) Inbound', 'color': Colors.blue, 'nodes': ['N07', 'N08']},

// 9. SUNSET - NEPO (Orange)
  {'route': 'SUNSET - NEPO (Orange) Loop', 'color': Colors.deepOrange, 'nodes': ['N27', 'N40','N26','N22','N23','N26','N40']},

// 10. VILLA - PAMPANG SM TELEBESTAGEN (Yellow)
  {'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Outbound', 'color': Colors.yellow, 'nodes': ['N15', 'N16','N19','N24','N29','N30','N31','N32','N28']},
  {'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Inbound', 'color': Colors.yellow, 'nodes': ['N28', 'N32', 'N31', 'N30', 'N29', 'N24', 'N19', 'N16', 'N15']},

// 11. CAPAYA - ANGELES (Pink) - CONVERTED TO A LOOP
  {'route': 'CAPAYA - ANGELES (Pink) Loop', 'color': Colors.pink, 'nodes': ['N10', 'N09', 'N08', 'N18', 'N19','N44','N20','N33','N22','N23','N24','N29','N44','N19', 'N18', 'N08', 'N09']},
];


/// Extracts the simple color/route name from the detailed route string.
/// E.g., 'MAIN GATE - FRIENDSHIP (Sand) Outbound' -> 'Sand'
String _extractColorName(String routeName) {
  final regex = RegExp(r'\((.*?)\)');
  final match = regex.firstMatch(routeName);
  if (match != null && match.groupCount >= 1) {
    return match.group(1)!.trim();
  }
  // Fallback if no parentheses are found, though all routes seem to use parentheses.
  return routeName.split(' ').last; 
}


// --- STEP 3: GRAPH BUILDING (Automatic) ---

/// Builds the final JeepneyGraph from the defined nodes and raw edge sequences.
JeepneyGraph _buildJeepneyGraph() {
  final Map<String, List<Edge>> adjacencyList = {};

  // Initialize adjacency list for every node
  for (var nodeId in allNodes.keys) {
    adjacencyList[nodeId] = [];
  }

  // Populate the adjacency list based on raw edge definitions
  for (var routeDef in rawEdgeDefinitions) {
    final routeName = routeDef['route'] as String;
    final routeColor = routeDef['color'] as Color;
    final nodeIds = routeDef['nodes'] as List<String>;
    final routeColorName = _extractColorName(routeName); // Extract the simple name

    // Iterate through the sequential nodes to create directed edges
    for (int i = 0; i < nodeIds.length - 1; i++) {
      final startId = nodeIds[i];
      final endId = nodeIds[i + 1];

      if (allNodes.containsKey(startId) && allNodes.containsKey(endId)) {
        final startPos = allNodes[startId]!.position;
        final endPos = allNodes[endId]!.position;

        // Calculate time cost (weight)
        final weight = calculateJeepneyWeight(startPos, endPos);
        
        // Create the directed edge
        final edge = Edge(
          startNodeId: startId,
          endNodeId: endId,
          weight: weight,
          routeName: routeName,
          routeColorName: routeColorName, // <-- FIX: Passing the required string name
          // PASSING THE ROUTE COLOR AND POLYLINE POINTS
          routeColor: routeColor, 
          polylinePoints: [startPos, endPos], 
        );

        // Add the edge to the starting node's list
        adjacencyList.putIfAbsent(startId, () => []).add(edge);
      } else {
        print('Error: Missing node in route $routeName. Check IDs $startId or $endId.');
      }
    }

    // --- Special Handling for Loop Routes ---
    if (routeName.contains('Loop') && nodeIds.length >= 2) {
      final lastId = nodeIds.last;
      final firstId = nodeIds.first;

      if (allNodes.containsKey(lastId) && allNodes.containsKey(firstId)) {
        final lastPos = allNodes[lastId]!.position;
        final firstPos = allNodes[firstId]!.position;
        final weight = calculateJeepneyWeight(lastPos, firstPos);

        final loopEdge = Edge(
          startNodeId: lastId,
          endNodeId: firstId,
          weight: weight,
          routeName: routeName,
          routeColorName: routeColorName, // <-- FIX: Passing the required string name
          routeColor: routeColor,
          polylinePoints: [lastPos, firstPos],
        );
        adjacencyList.putIfAbsent(lastId, () => []).add(loopEdge);
      }
    }
  }

  // Return the final JeepneyGraph instance
  return JeepneyGraph(
    nodes: allNodes,
    adjacencyList: adjacencyList,
  );
}
