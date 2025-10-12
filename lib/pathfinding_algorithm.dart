import 'dart:collection';
import 'graph_models.dart';
// NOTE: Assuming pathfinding_config.dart contains the correct penalty constant
// For demonstration, we define the constant here, but keep the import reference.
// import 'pathfinding_config.dart'; 

// 🚨 TEMPORARY CONSTANT (REPLACE WITH import 'pathfinding_config.dart';)
const double TRANSFER_WAIT_PENALTY_MINUTES = 10.0; 

// ----------------------------------------------------------------------
// --- Priority Queue Implementation (Necessary for Efficiency) ---
// ----------------------------------------------------------------------

class PriorityQueue<E extends Comparable<E>> {
  final List<E> _list = [];

  void add(E element) {
    _list.add(element);
    _siftUp(_list.length - 1);
  }

  E removeMin() {
    if (_list.isEmpty) throw StateError('PriorityQueue is empty');
    if (_list.length == 1) return _list.removeLast();
    
    final min = _list[0];
    _list[0] = _list.removeLast();
    _siftDown(0);
    return min;
  }

  bool get isEmpty => _list.isEmpty;

  void _siftUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) ~/ 2;
      if (_list[index].compareTo(_list[parentIndex]) < 0) {
        // Swap if child is smaller (lower cost)
        final temp = _list[index];
        _list[index] = _list[parentIndex];
        _list[parentIndex] = temp;
        index = parentIndex;
      } else {
        break;
      }
    }
  }

  void _siftDown(int index) {
    var parentIndex = index;
    while (true) {
      final leftChildIndex = 2 * parentIndex + 1;
      final rightChildIndex = 2 * parentIndex + 2;
      var smallestIndex = parentIndex;

      if (leftChildIndex < _list.length && 
          _list[leftChildIndex].compareTo(_list[smallestIndex]) < 0) {
        smallestIndex = leftChildIndex;
      }
      if (rightChildIndex < _list.length && 
          _list[rightChildIndex].compareTo(_list[smallestIndex]) < 0) {
        smallestIndex = rightChildIndex;
      }

      if (smallestIndex != parentIndex) {
        // Swap
        final temp = _list[parentIndex];
        _list[parentIndex] = _list[smallestIndex];
        _list[smallestIndex] = temp;
        parentIndex = smallestIndex;
      } else {
        break;
      }
    }
  }
}

// ----------------------------------------------------------------------
// --- PathNode and JeepneyPath (Kept and Used) ---
// ----------------------------------------------------------------------

/// A custom class used for the Priority Queue in Dijkstra's algorithm.
class PathNode implements Comparable<PathNode> {
  final String nodeId;
  final double currentCost; // The total cost (time) from the start node to this node
  final String? incomingRouteId; 

  PathNode(this.nodeId, this.currentCost, this.incomingRouteId);

  @override
  int compareTo(PathNode other) {
    return currentCost.compareTo(other.currentCost);
  }
}

/// The result structure returned by the pathfinding algorithm.
class JeepneyPath {
  final List<Edge> edges; 
  final double totalTime; 
  final int transfers; 

  JeepneyPath({
    required this.edges,
    required this.totalTime,
    required this.transfers,
  });
}

// ----------------------------------------------------------------------
// --- findShortestPath Function (The Core Fix) ---
// ----------------------------------------------------------------------

JeepneyPath? findShortestPath(JeepneyGraph graph, String startNodeId, String endNodeId) {
  
  if (!graph.nodes.containsKey(startNodeId) || !graph.nodes.containsKey(endNodeId)) {
    print('Error: Start or end node ID not found in graph.');
    return null;
  }

  final Map<String, double> costs = {};
  final Map<String, Edge> parentEdges = {};
  final Map<String, String?> incomingRoutes = {}; // Now explicitly allows null/String
  
  // Initialize costs and incoming routes
  for (var nodeId in graph.nodes.keys) {
    costs[nodeId] = double.infinity;
    incomingRoutes[nodeId] = null; // Use null for no route yet
  }
  
  costs[startNodeId] = 0.0;
  
  // 🎯 FIX 1: Use the efficient PriorityQueue implementation
  final PriorityQueue<PathNode> priorityQueue = PriorityQueue<PathNode>();
  priorityQueue.add(PathNode(startNodeId, 0.0, null)); // Start node has no incoming route

  while (!priorityQueue.isEmpty) {
    final currentPathNode = priorityQueue.removeMin();

    final uId = currentPathNode.nodeId;
    final uCost = currentPathNode.currentCost;
    final uIncomingRouteId = incomingRoutes[uId]; // Use the route ID stored in the map (more reliable)

    // Optimization: If the cost in the PQ is worse than what we already found, skip.
    if (uCost > costs[uId]!) continue;
    
    if (uId == endNodeId) break;

    // Explore neighbors (outgoing edges)
    final edges = graph.adjacencyList[uId] ?? [];
    
    for (var edge in edges) {
      
      // 1. Get the base travel time (Edge.time is distance, Edge.weight is time)
      // Since the PathfindingService set Edge.weight = timeMin, we should use Edge.weight.
      // If your model uses 'time' directly, use that. Based on your Edge constructor:
      // Edge(..., weight: timeMin, ...) -> We use edge.weight
      double travelCost = edge.weight; 
      double transferPenalty = 0.0;

      // 2. Check for transfer cost
      final isWalkSegment = edge.type == EdgeType.WALK;
      
      // A transfer occurs if:
      // a) We were on a non-WALK route (uIncomingRouteId) AND
      // b) The next segment (edge) is on a different routeId.
      // NOTE: We don't penalize transfers *onto* a WALK segment.
      if (uIncomingRouteId != null && 
          uIncomingRouteId != edge.routeId &&
          !isWalkSegment) 
      {
        // 🎯 FIX 2: Use the corrected constant name
        transferPenalty = TRANSFER_WAIT_PENALTY_MINUTES; 
      }
      
      // The first movement from the USER_START walk segment to a JEEPNEY route
      // should generally be counted as a transfer if we track all route changes.
      // However, Dijkstra's works best if we only penalize *actual* mid-route changes.

      // 3. Calculate the new total cost
      final double newCost = uCost + travelCost + transferPenalty;
      final vId = edge.endNodeId;

      // 4. Relaxation
      if (newCost < costs[vId]!) {
        costs[vId] = newCost;
        parentEdges[vId] = edge;
        // The incoming route for vId is the route of the edge that reached it.
        incomingRoutes[vId] = edge.routeId; 
        
        priorityQueue.add(PathNode(vId, newCost, edge.routeId));
      }
    }
  }

  // --- Reconstruct Path ---
  if (costs[endNodeId] == double.infinity) {
    return null; // No path found
  }

  List<Edge> pathEdges = [];
  String? currentId = endNodeId;
  
  // Backtrack from endNodeId to startNodeId
  while (currentId != null && parentEdges.containsKey(currentId)) {
    final edge = parentEdges[currentId]!;
    pathEdges.add(edge);
    currentId = edge.startNodeId;
  }
  
  // Reverse the list back to start -> end
  pathEdges = pathEdges.reversed.toList();

  // 🎯 FIX 3: Calculate transfers accurately in the final path
  int transferCount = 0;
  String? previousRouteId;

  for (final edge in pathEdges) {
    // A transfer occurs if the current route is different from the previous route.
    // We only count transfers between two non-WALK routes.
    if (edge.type == EdgeType.JEEPNEY && 
        previousRouteId != null && 
        previousRouteId != edge.routeId) {
      transferCount++;
    }
    
    // Update the previous route, but ignore walk segments for transfer counting
    // (A WALK segment can separate two JEEPNEY transfers)
    if (edge.type == EdgeType.JEEPNEY) {
        previousRouteId = edge.routeId;
    }
    // For simplicity in the final path summary, we can just track the route ID
    // that the path is currently on.
    // If the previous edge was a WALK, the current edge's route ID is what matters.
    if (edge.routeId.isNotEmpty) {
      previousRouteId = edge.routeId;
    }
  }

  // Final check: If the path starts with a WALK (which has routeId 'WALK_TEMP'),
  // the first transition to a JEEPNEY route shouldn't be counted as a transfer.
  // The transfer count logic above is robust if we ensure 'WALK_TEMP' is always
  // a distinct routeId that doesn't trigger a transfer when leaving it.
  
  return JeepneyPath(
    edges: pathEdges,
    totalTime: costs[endNodeId]!,
    transfers: transferCount,
  );
}