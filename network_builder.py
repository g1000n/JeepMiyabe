import json
import math
from typing import List, Dict, Any

# --- CONFIGURATION ---
SEGMENTS_JSON_PATH = 'route_segments.json'
POLYLINE_LOOKUP_PATH = 'routes_polyline_lookup.json'
OUTPUT_NETWORK_PATH = 'optimized_network_graph.json'

# --- Speed Constants (CRITICAL FIX: Must match Dart pathfinding_config) ---
JEEPNEY_SPEED_KM_PER_MIN = 0.25
WALK_SPEED_KM_PER_MIN = 0.06667
WALK_THRESHOLD_KM = 0.1
# --- END CONFIGURATION ---

# Haversine formula remains the same
def haversine(lat1, lon1, lat2, lon2):
    """Calculate the distance between two points in kilometers."""
    R = 6371
    dLat = math.radians(lat2 - lat1)
    # >>> FIX 1/3: Corrected dLon calculation (was: lon2 - lon2, should be: lon2 - lon1)
    dLon = math.radians(lon2 - lon1)
    # ---------------------------------------------------------------------------------

    a = math.sin(dLat / 2) * math.sin(dLat / 2) + \
        math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * \
        math.sin(dLon / 2) * math.sin(dLon / 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance = R * c

    return distance


def load_segments_from_json(file_path: str) -> List[Dict[str, Any]]:
    """Loads the pre-calculated list of segments from the JSON file."""
    print(f"Reading segmented route data from {file_path}...")
    try:
        with open(file_path, 'r') as f:
            segments = json.load(f)
        print(f"Successfully loaded {len(segments)} segments.")
        return segments
    except FileNotFoundError:
        print(f"Error: Segment JSON file {file_path} not found.")
        return []
    except json.JSONDecodeError:
        print(f"Error: Failed to parse JSON from {file_path}. Check file format.")
        return []


# --- SIMPLIFICATION LOGIC ---
def simplify_network(all_nodes: Dict[str, Any], adjacency_list: Dict[str, List[Dict[str, Any]]]):
    """Simplifies the network by merging sequential JEEPNEY edges."""
    print("\nStarting network simplification (merging micro-segments)...")

    # Pre-calculate reverse adjacency (for finding incoming edges)
    incoming_edges: Dict[str, List[Dict[str, Any]]] = {}
    for start_node_id, edges in adjacency_list.items():
        for edge in edges:
            end_node_id = edge['endNodeId']
            if end_node_id not in incoming_edges:
                incoming_edges[end_node_id] = []
            incoming_edges[end_node_id].append(edge)

    nodes_to_remove = set()
    total_edges_removed = 0

    while True:
        # Find the next simplifiable node
        simplifiable_node_id = None
        for node_id in list(all_nodes.keys()):
            if node_id in nodes_to_remove:
                continue

            incoming_list = [e for e in incoming_edges.get(node_id, []) if e.get('type') == 'JEEPNEY']
            outgoing_list = [e for e in adjacency_list.get(node_id, []) if e.get('type') == 'JEEPNEY']

            # Must have exactly one JEEPNEY edge in and one JEEPNEY edge out
            if len(incoming_list) == 1 and len(outgoing_list) == 1:
                in_edge = incoming_list[0]
                out_edge = outgoing_list[0]

                # They must belong to the same route
                if in_edge['routeId'] == out_edge['routeId']:
                    simplifiable_node_id = node_id
                    break

        if not simplifiable_node_id:
            break

        P_id = simplifiable_node_id
        in_edge = [e for e in incoming_edges.get(P_id, []) if e['type'] == 'JEEPNEY'][0]
        out_edge = [e for e in adjacency_list.get(P_id, []) if e['type'] == 'JEEPNEY'][0]

        A_id = in_edge['startNodeId']
        B_id = out_edge['endNodeId']

        new_distance = in_edge['distance'] + out_edge['distance']
        new_weight = in_edge['weight'] + out_edge['weight']

        # Skip the duplicate coordinate at the start of the outgoing polyline
        new_polyline = in_edge['polylinePoints'] + out_edge['polylinePoints'][1:]

        # Create a stable, merged edge ID
        new_edge_id = f"{A_id}-{B_id}-{in_edge['routeId']}"

        # <<< FIX 2/3: Use the clean 'routeHexCode' field to reconstruct the color >>>
        # We assume 'routeHexCode' (RRGGBB) is clean from build_optimized_network
        clean_hex = in_edge.get('routeHexCode', 'FF00FF') # Default to a noticeable color if missing
        new_flutter_hex = f"0xFF{clean_hex}"
        # --------------------------------------------------------------------------

        merged_edge = {
            'id': new_edge_id,
            'startNodeId': A_id,
            'endNodeId': B_id,
            'type': 'JEEPNEY',
            'distance': new_distance,
            'weight': new_weight,
            'routeId': in_edge['routeId'],
            'routeName': in_edge['routeName'],
            # 'routeColorName': new_flutter_hex, # Use the reconstructed color
            # 'routeHexCode': clean_hex,        # Keep the clean hex code
            'polylinePoints': new_polyline
        }

        # 1. Update adjacency list from A to B
        if A_id in adjacency_list:
            # Remove the old A->P edge
            adjacency_list[A_id] = [e for e in adjacency_list[A_id] if e['id'] != in_edge['id']]
            # Add the new A->B merged edge
            adjacency_list[A_id].append(merged_edge)

        # 2. Update incoming edges for B
        if B_id in incoming_edges:
            # Remove the old P->B edge
            incoming_edges[B_id] = [e for e in incoming_edges[B_id] if e['id'] != out_edge['id']]
            # Add the new A->B merged edge
            incoming_edges[B_id].append(merged_edge)

        # 3. Remove the intermediate node P and its associated edges
        del all_nodes[P_id]
        if P_id in adjacency_list:
            total_edges_removed += len(adjacency_list[P_id]) # Count outgoing edges (P->B, etc.)
            del adjacency_list[P_id]
        if P_id in incoming_edges:
             total_edges_removed += len(incoming_edges[P_id]) # Count incoming edges (A->P, etc.)
             del incoming_edges[P_id]
        

        nodes_to_remove.add(P_id)

    print(f"Simplification complete. Removed {len(nodes_to_remove)} nodes.")
    return all_nodes, adjacency_list
# --- END SIMPLIFICATION LOGIC ---


def build_optimized_network():
    """Combines the segment list and polyline lookup to create the final optimized graph structure."""
    segments_data = load_segments_from_json(SEGMENTS_JSON_PATH)
    if not segments_data:
        return

    try:
        with open(POLYLINE_LOOKUP_PATH, 'r') as f:
            polyline_lookup = json.load(f)
    except FileNotFoundError:
        print(f"Error: Polyline lookup file {POLYLINE_LOOKUP_PATH} not found.")
        return

    all_nodes: Dict[str, Any] = {}
    adjacency_list: Dict[str, List[Dict[str, Any]]] = {}

    print("\nBuilding initial JEEPNEY edges (high resolution)...")
    for segment in segments_data:
        route_id = segment['routeId']
        route_name = segment['routeName']
        route_info = polyline_lookup.get(route_id)
        if not route_info:
            continue

        full_polyline = route_info['fullPolyline']
        start_index = segment['startIndex']
        end_index = segment['endIndex']

        if start_index >= len(full_polyline) or end_index >= len(full_polyline) or start_index > end_index:
            continue

        segment_points = full_polyline[start_index:end_index + 1]

        is_global_start = (start_index == 0)
        is_global_end = (end_index == len(full_polyline) - 1)

        # --- COLOR FIX ---
        color_hex = segment['colorHex'].replace('0x', '').replace('0X', '')
        full_flutter_hex = f"0xFF{color_hex}"
        # -----------------

        for i in range(len(segment_points) - 1):
            p1 = segment_points[i]
            p2 = segment_points[i + 1]

            p1_id = f"{p1['lat']:.6f},{p1['lon']:.6f}"
            p2_id = f"{p2['lat']:.6f},{p2['lon']:.6f}"

            distance_km = haversine(p1['lat'], p1['lon'], p2['lat'], p2['lon'])
            if distance_km < 0.0001:
                distance_km = 0.0001
            time_min = distance_km / JEEPNEY_SPEED_KM_PER_MIN

            # Ensure nodes exist
            if p1_id not in all_nodes:
                node_name = f"{route_name} START" if i == 0 and is_global_start else f"{route_name} Midpoint"
                all_nodes[p1_id] = {'id': p1_id, 'name': node_name, 'lat': p1['lat'], 'lon': p1['lon']}

            if p2_id not in all_nodes:
                node_name = f"{route_name} END" if i == len(segment_points) - 2 and is_global_end else f"{route_name} Midpoint"
                all_nodes[p2_id] = {'id': p2_id, 'name': node_name, 'lat': p2['lat'], 'lon': p2['lon']}
            
            # <<< FIX 3/3: Corrected logic for adding edge and simplified the adjacency_list check >>>
            
            # FIX 1/2 from original prompt: Add the clean 6-digit hex code to the edge data
            edge = {
                'id': f"{p1_id}-{p2_id}-{route_id}",
                'startNodeId': p1_id,
                'endNodeId': p2_id,
                'type': 'JEEPNEY',
                'distance': distance_km,
                'weight': time_min,
                'routeId': route_id,
                'routeName': route_name,
                # 'routeColorName': full_flutter_hex,
                # 'routeHexCode': color_hex,        # <--- NEW FIELD for clean RRGGBB
                'polylinePoints': [{'lat': p1['lat'], 'lon': p1['lon']}, {'lat': p2['lat'], 'lon': p2['lon']}]
            }
            # -----------------------------------------------------------------------------------------
            
            # Ensure p1_id exists as a key in the adjacency_list
            adjacency_list.setdefault(p1_id, []).append(edge)

    # Move simplification outside the high-resolution loop
    all_nodes, adjacency_list = simplify_network(all_nodes, adjacency_list)

    all_node_list = list(all_nodes.values())
    print(f"\nAdding inter-node WALK edges (max {WALK_THRESHOLD_KM} km) to connect routes...")

    for i in range(len(all_node_list)):
        node_a = all_node_list[i]
        for j in range(i + 1, len(all_node_list)):
            node_b = all_node_list[j]

            dist = haversine(node_a['lat'], node_a['lon'], node_b['lat'], node_b['lon'])

            if dist > 0.0 and dist <= WALK_THRESHOLD_KM:
                time_min = dist / WALK_SPEED_KM_PER_MIN

                walk_edge_ab = {
                    'id': f"W-{node_a['id']}-{node_b['id']}",
                    'startNodeId': node_a['id'],
                    'endNodeId': node_b['id'],
                    'type': 'WALK',
                    'distance': dist,
                    'weight': time_min,
                    'routeId': 'W_DEFAULT',
                    'routeName': 'Walk Segment',
                    'routeColorName': '0xFF9E9E9E',
                    'routeHexCode': '9E9E9E', # Added for completeness
                    'polylinePoints': [{'lat': node_a['lat'], 'lon': node_a['lon']},
                                       {'lat': node_b['lat'], 'lon': node_b['lon']}]
                }

                walk_edge_ba = walk_edge_ab.copy()
                walk_edge_ba['id'] = f"W-{node_b['id']}-{node_a['id']}"
                walk_edge_ba['startNodeId'] = node_b['id']
                walk_edge_ba['endNodeId'] = node_a['id']
                walk_edge_ba['polylinePoints'] = [{'lat': node_b['lat'], 'lon': node_b['lon']},
                                                  {'lat': node_a['lat'], 'lon': node_a['lon']}]

                adjacency_list.setdefault(node_a['id'], []).append(walk_edge_ab)
                adjacency_list.setdefault(node_b['id'], []).append(walk_edge_ba)

    final_output = {
        'allNodes': all_nodes,
        'adjacencyList': adjacency_list,
    }

    with open(OUTPUT_NETWORK_PATH, 'w') as f:
        json.dump(final_output, f, indent=2)

    print("\n--- Network Building Success ---")
    print(f"Total Final Unique Nodes: {len(all_nodes)}")
    print(f"Total Final Outbound Edges (JEEPNEY + WALK): {sum(len(v) for v in adjacency_list.values())}")
    print(f"Final graph saved to {OUTPUT_NETWORK_PATH}.")
    print("--------------------------------\n")


if __name__ == '__main__':
    build_optimized_network()