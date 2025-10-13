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
// Function to define all your fixed locations (N01-N44, including skipped numbers).
Map<String, Node> _defineAllNodes() {
  return {
    // 1. Bayanihan area
    'N01': Node(id: 'N01', position: const LatLng(15.168122223153073, 120.58459637453271), name: 'Bayanihan Jeepney Terminal'),
    'N02': Node(id: 'N02', position: const LatLng(15.178132414995723, 120.58728291382715), name: 'Dau Access Road'),
    
    // 2. Clark/Sapang Bato area
    'N03': Node(id: 'N03', position: const LatLng(15.16305204732774, 120.55473730830217), name: 'Fil-Am Friendship Highway'),
    'N04': Node(id: 'N04', position: const LatLng(15.170933172394623, 120.51501727223763), name: 'Sapang Bato Barangay Hall'),
    
    // 3. Balibago/Marquee area
    'N05': Node(id: 'N05', position: const LatLng(15.16946765414794, 120.58930685405767), name: 'Balibago (Road to Dau)'),
    'N06': Node(id: 'N06', position: const LatLng(15.162560370889945, 120.59107576216996), name: 'Marlim Avenue'),
    'N07': Node(id: 'N07', position: const LatLng(15.162476539579057, 120.60835134728958), name: 'Marquee Mall by Ayala Malls'),
    'N08': Node(id: 'N08', position: const LatLng(15.153719303730984, 120.6048240781205), name: 'Pandan-Tabun Road'),
    'N09': Node(id: 'N09', position: const LatLng(15.146305899131237, 120.61414748914245), name: 'San Vicente Street, Capaya'),
    'N10': Node(id: 'N10', position: const LatLng(15.14566785692904, 120.61719106223454), name: 'Nepomuceno & Lazatin, Capaya'),
    'N11': Node(id: 'N11', position: const LatLng(15.157385727790757, 120.59225013133326), name: 'Robinsons Angeles'),
    'N12': Node(id: 'N12', position: const LatLng(15.15307225795962, 120.59192571795558), name: 'Marisol Roundabout'),
    
    // 4. Inner City/Pampang
    'N13': Node(id: 'N13', position: const LatLng(15.150806937623226, 120.59264629206302), name: 'Marisol-Pampang Jeepney Terminal'),
    'N14': Node(id: 'N14', position: const LatLng(15.149946558933049, 120.5842657630103), name: 'Arayat Blvd.-Arayat Road'),
    'N15': Node(id: 'N15', position: const LatLng(15.147178515304587, 120.58615084430178), name: '136 San Francisco St., Angeles, Pampanga'),
    'N16': Node(id: 'N16', position: const LatLng(15.143470904682285, 120.588363928338), name: 'Henson Ville Terminal'),
    'N17': Node(id: 'N17', position: const LatLng(15.145477507981582, 120.59523398671675), name: 'Angeles University Foundation'),
    'N18': Node(id: 'N18', position: const LatLng(15.142692807000863, 120.59652645730344), name: 'Angeles Intersection/Roundabout'),
    'N19': Node(id: 'N19', position: const LatLng(15.138839458618483, 120.59371441157968), name: '100a Santo Entiero St'),
    'N20': Node(id: 'N20', position: const LatLng(15.137831061596211, 120.58886265671481), name: 'Miranda-Plaridel Street Intersection'),
    'N21': Node(id: 'N21', position: const LatLng(15.13937751108868, 120.58659662391537), name: 'Newstar Shopping Mart'),
    'N22': Node(id: 'N22', position: const LatLng(15.136961541120508, 120.58649797187472), name: '248-102 Rizal Street Ext'),
    'N23': Node(id: 'N23', position: const LatLng(15.136375922908924, 120.58773799302463), name: '304 Santo Rosario St, Angeles, Pampanga'),
    'N24': Node(id: 'N24', position: const LatLng(15.134825927046702, 120.59063095384975), name: 'Holy Rosary Parish Church'),
    'N25': Node(id: 'N25', position: const LatLng(15.135588453717585, 120.59330024080815), name: 'Lakandula Street'),
    'N26': Node(id: 'N26', position: const LatLng(15.133639713699715, 120.58430415229193), name: 'Rizal Street Ext'),
    'N27': Node(id: 'N27', position: const LatLng(15.13460213899443, 120.567100472649), name: 'Sunset Estates'),
    
    // 5. SM Telabastagan / Southern Extensions
    'N28': Node(id: 'N28', position: const LatLng(15.12168324431814, 120.60046354507185), name: 'SM Telabastagan Terminal'),
    'N29': Node(id: 'N29', position: const LatLng(15.134251048500333, 120.59120807974612), name: 'Holy Angel University'),
    'N30': Node(id: 'N30', position: const LatLng(15.127062195834817, 120.59689172979789), name: 'Super 8 (San Fernando-Villa Pampang Terminal)'),
    'N31': Node(id: 'N31', position: const LatLng(15.125346577935126, 120.59816782088681), name: 'Sacred Heart Medical Center'),
    'N32': Node(id: 'N32', position: const LatLng(15.123673715007401, 120.5990014935524), name: 'Chevalier School'),
    'N33': Node(id: 'N33', position: const LatLng(15.13882801470678, 120.58755922236452), name: 'Jollibee Rotonda, San Nicolas Market'),
    'N34': Node(id: 'N34', position: const LatLng(15.166489559701413, 120.5771989295957), name: 'Public Transport Terminal (SM City Clark)'),
    'N35': Node(id: 'N35', position: const LatLng(15.166491757108336, 120.58282696723248), name: 'Henson Ville Terminal'),
    'N36': Node(id: 'N36', position: const LatLng(15.158228767911242, 120.5921409581609), name: 'Systems Plus Balibago'),
    
    // Nodes from the old list that were not in your new list (N37-N39) have been removed
    // to strictly adhere to the provided data list, but N40 is kept.
    'N40': Node(id: 'N40', position: const LatLng(15.12968339481647, 120.57538621875474), name: 'Overpass Intersection'),
    
    // 6. New nodes from the extended list (N41, N42, N43, N44)
    'N41': Node(id: 'N41', position: const LatLng(15.144474509315053, 120.55938943379525), name: 'Security Bank, cor Poinsettia Avenue'),
    'N42': Node(id: 'N42', position: const LatLng(15.152794350180983, 120.59216746673009), name: '7-eleven Ninoy Aquino (Marisol)'),
    'N43': Node(id: 'N43', position: const LatLng(15.135748021656429, 120.58702364198633), name: 'Nepo Mart'),
    'N44': Node(id: 'N44', position: const LatLng(15.135941494350044, 120.59146839921544), name: '1225 Miranda-Sto. Entierro St. Intersection'),
    'N48': Node(id: 'N48', position: const LatLng(15.163763689386034, 120.55613180852866), name: 'Mr. Wang Chinese Restaurant'),
    'N49': Node(id: 'N49', position: const LatLng(15.165155111956631, 120.55881787134152), name: 'Little Chinatown'),
    'N50': Node(id: 'N50', position: const LatLng(15.1662477040375, 120.56122979357431), name: 'Oasis Entrance'),
    'N51': Node(id: 'N51', position: const LatLng(15.166656966092535, 120.5647177933902), name: 'Clark Side Entrance'),
    'N53': Node(id: 'N52', position: const LatLng(15.166168930349212, 120.57024324786535), name: 'Don Juico Avenue'),
    'N52': Node(id: 'N53', position: const LatLng(15.166615217878718, 120.56704796317382), name: 'Don Juico Avenue 2'),
    'N54': Node(id: 'N54', position: const LatLng(15.166136729276836, 120.57024235353519), name: 'Red Planet Clark'),
    'N55': Node(id: 'N55', position: const LatLng(15.165387890177486, 120.57471089049888), name: 'Margarita Station'),
    'N56': Node(id: 'N56', position: const LatLng(15.165285476382685, 120.57575793962214), name: '21st Street'),
    'N57': Node(id: 'N57', position: const LatLng(15.165609994874618, 120.57855944351667), name: 'Tratorria Altrove'),
    'N58': Node(id: 'N58', position: const LatLng(15.166484629946067, 120.58290665127366), name: 'Bayad Center'),
    'N59': Node(id: 'N59', position: const LatLng(15.130152748894668, 120.59507946010962), name: 'LBS Bakeshop Angeles'),
    'N60': Node(id: 'N60', position: const LatLng(15.13229392333138, 120.59309621180884), name: 'Eggs N Brekky Angeles'),
  };
}
// --- STEP 2: JEEPNEY ROUTE EDGE DEFINITIONS (UNCHANGED) ---
final List<Map<String, dynamic>> rawEdgeDefinitions = [
  // 1. MAIN GATE - FRIENDSHIP (Sand) (Simple Route: Outbound/Inbound)
  {'route': 'MAIN GATE - FRIENDSHIP (Sand) Outbound', 'color': const Color(0xFFC2B280), 'nodes': ['N03', 'N48', 'N49', 'N50', 'N51', 'N52', 'N53','N54','N55','N56','N57','N58', 'N35']},
  {'route': 'MAIN GATE - FRIENDSHIP (Sand) Inbound', 'color': const Color(0xFFC2B280), 'nodes': ['N35','N58','N57','N56','N55','N54','N53','N52','N51','N50','N49', 'N48','N03']},

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
  {'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Outbound', 'color': Colors.yellow, 'nodes': ['N15', 'N16','N19','N24','N29','N59','N60','N30','N31','N32','N28']},
  {'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Inbound', 'color': Colors.yellow, 'nodes': ['N28', 'N32', 'N31', 'N30','N60','N59', 'N29', 'N24', 'N19', 'N16', 'N15']},

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
