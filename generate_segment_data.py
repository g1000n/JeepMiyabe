import json
import os

# --- Configuration ---
BLUEPRINT_FILE = 'route_segments_blueprint.json'
POLYLINE_LOOKUP_FILE = 'routes_polyline_lookup.json'
OUTPUT_FILE = 'final_segments_for_firestore.json'
# ---------------------

def load_json(filepath):
    """Loads a JSON file, checking if it exists."""
    if not os.path.exists(filepath):
        print(f"Error: File not found at path: {filepath}")
        return None
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON in {filepath}: {e}")
        return None

def process_data():
    """Reads blueprint and polyline data, generates final segment documents."""
    print("--- Starting Segment Data Generation ---")

    # 1. Load Blueprint and Polyline Data
    # FIX: Changed BLUEPOINT_FILE to BLUEPRINT_FILE
    blueprint = load_json(BLUEPRINT_FILE)
    if blueprint is None: return

    polyline_lookup = load_json(POLYLINE_LOOKUP_FILE)
    if polyline_lookup is None: return

    # 2. Process and Normalize Segments
    final_segments = []

    # Iterate over each route defined in the blueprint
    for route_data in blueprint:
        route_id = route_data.get('routeId')
        
        # Check if the full polyline data exists for this routeId
        if route_id not in polyline_lookup:
            print(f"Warning: Full polyline data missing for Route ID: {route_id}. Skipping.")
            continue

        full_polyline = polyline_lookup[route_id].get('fullPolyline', [])

        if not full_polyline:
            print(f"Warning: Full polyline array is empty for Route ID: {route_id}. Skipping.")
            continue
            
        route_color_hex = route_data.get('colorHex', '#000000')

        # Iterate over each defined segment within the route
        for segment_definition in route_data.get('segments', []):
            
            segment_id = segment_definition['segmentId']
            start_index = segment_definition['startIndex']
            end_index = segment_definition['endIndex']
            
            # --- Validation Checks ---
            if start_index < 0 or start_index >= len(full_polyline) or \
               end_index < 0 or end_index >= len(full_polyline) or \
               start_index > end_index:
                print(f"Error: Indices out of bounds or invalid for segment {segment_id}. Skipping.")
                continue

            # 3. Derive Start and End Points from the Original Polyline
            start_point = full_polyline[start_index]
            end_point = full_polyline[end_index]
            
            # 4. Construct the Final Segment Document
            segment_doc = {
                "segmentId": segment_id,
                "routeId": route_id,
                "routeName": route_data['routeName'],
                "direction": segment_definition['direction'],
                "startIndex": start_index,
                "endIndex": end_index,
                "startPoint": start_point,
                "endPoint": end_point,
                "colorHex": route_color_hex,
                "totalPoints": (end_index - start_index) + 1 # Helpful for debugging/tracking
            }
            
            final_segments.append(segment_doc)
            print(f"Successfully processed segment: {segment_id}")


    # 5. Write Output to File
    try:
        with open(OUTPUT_FILE, 'w') as outfile:
            json.dump(final_segments, outfile, indent=2)
        print(f"\n--- Success! ---")
        print(f"Total {len(final_segments)} segments created and saved to {OUTPUT_FILE}")
        print("This file is ready for mass upload to Firestore!")
    except Exception as e:
        print(f"Failed to write output file: {e}")

if __name__ == "__main__":
    process_data()
