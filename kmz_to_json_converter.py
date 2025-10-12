import xml.etree.ElementTree as ET
import json
import os
import re
import zipfile
import hashlib # For creating a stable, unique ID

# --- CONFIGURATION ---
# Create a folder named 'kml_files' in the same directory as this script, 
# and place all your .kml and .kmz files inside it.
INPUT_DIR = 'kml_files'
OUTPUT_FILE = 'routes_polyline_lookup.json'
# --- END CONFIGURATION ---

# Register KML namespaces for correct parsing
NS = {'kml': 'http://www.opengis.net/kml/2.2'}
ET.register_namespace('', 'http://www.opengis.net/kml/2.2')

def get_kml_content(filepath):
    """Reads content from a .kml file or extracts doc.kml from a .kmz file."""
    if filepath.lower().endswith('.kmz'):
        try:
            with zipfile.ZipFile(filepath, 'r') as kmz:
                # KML content inside KMZ is usually named 'doc.kml'
                return kmz.read('doc.kml')
        except (zipfile.BadZipFile, KeyError) as e:
            print(f"Error reading KMZ file {filepath}: {e}")
            return None
    elif filepath.lower().endswith('.kml'):
        try:
            with open(filepath, 'rb') as f:
                return f.read()
        except Exception as e:
            print(f"Error reading KML file {filepath}: {e}")
            return None
    return None

def generate_unique_id(route_name):
    """Generates a unique, URL-friendly ID from the route name."""
    # 1. Clean the name (remove color/parentheses, extra spaces)
    name_clean = re.sub(r'\s*\((.*?)\)\s*', '', route_name).strip()
    # Replace spaces and hyphens with underscores, convert to upper case
    name_clean = re.sub(r'[\s\-]+', '_', name_clean).upper()
    
    # Simple ID prefix
    prefix = name_clean if len(name_clean) < 15 else name_clean[:15]
    
    # Use a hash for guaranteed uniqueness
    name_hash = hashlib.sha1(route_name.encode('utf-8')).hexdigest()[:6]
    
    return f"R_{prefix}_{name_hash}"

# MODIFIED: Added 'filename' parameter
def extract_data_from_content(kml_content, filepath, filename):
    """Parses KML content to extract polyline data, name, and style color."""
    if kml_content is None:
        return None

    try:
        # Parse KML content from memory
        root = ET.fromstring(kml_content)
        
        # 1. Find the Placemark and Name
        placemark = None
        # Start with the filename as a default route name
        route_name = filename 
        for elem in root.iter():
            if elem.tag == '{http://www.opengis.net/kml/2.2}Placemark':
                placemark = elem
                route_name_elem = placemark.find('kml:name', NS)
                if route_name_elem is not None and route_name_elem.text:
                    route_name = route_name_elem.text.strip()
                break
        
        if placemark is None:
            print(f"Warning: Could not find Placemark in {filename}. Skipping.")
            return None

        # 2. Find Coordinates
        coords_elem = None
        for elem in placemark.iter():
            if elem.tag == '{http://www.opengis.net/kml/2.2}coordinates':
                coords_elem = elem
                break
        
        if coords_elem is None or not coords_elem.text:
            print(f"Warning: No coordinates found for {route_name} (from {filename}). Skipping.")
            return None

        # Clean and parse coordinates (lon, lat, alt)
        coords_string = re.sub(r'[\r\n\t\s]+', ' ', coords_elem.text).strip()
        coordinates = []
        for triplet in coords_string.split(' '):
            if not triplet: continue
            lon_lat_alt = triplet.split(',')
            if len(lon_lat_alt) >= 2:
                try:
                    lon = float(lon_lat_alt[0])
                    lat = float(lon_lat_alt[1])
                    # KML standard is (longitude, latitude)
                    coordinates.append({"lat": lat, "lon": lon}) 
                except ValueError:
                    print(f"Warning: Skipping invalid coordinate triplet in {route_name}: {triplet}")

        # 3. Extract Color and format for Dart
        color_map = {
            'Grey': '#808080', 'Pink': '#FFC0CB', 'White': '#FFFFFF', 'Violet': '#4B0082', 
            'Sand': '#C2B280', 'Green': '#008000', 'Blue': '#0000FF', 'Red': '#FF0000', 
            'Various': '#3F3F3F', 'Orange': '#FF4500', 'Yellow': '#FFFF00', 'Lavander': '#4B0082', 
        }
        # Try to find the color name inside parentheses in the route name
        color_match = re.search(r'\((.*?)\)', route_name)
        color_name = color_match.group(1).strip() if color_match else 'Default'
        if color_name == 'Violet': color_name = 'Lavander'
        color_hex = color_map.get(color_name, '#000000') 
        # Convert to Dart format 0xFFRRGGBB
        dart_color_string = '0xFF' + color_hex.lstrip('#').upper()
        
        # 4. GENERATE the UNIQUE ID
        # CRITICAL FIX: Use the 'filename' (which includes color) instead of the internal KML 'route_name'
        # for ID generation to prevent hash collisions and ensure all 11 files are processed.
        unique_route_id = generate_unique_id(filename) 
        
        # NEW ROBUSTNESS CHECK: If the route name looks like a generic coordinate string,
        # use the clean filename instead for a user-friendly name.
        if "Directions from" in route_name or re.search(r'\d+\.\d+,\d+\.\d+', route_name):
            print(f"Warning: Route name '{route_name}' is generic. Using filename instead.")
            clean_filename = re.sub(r'\s*\.(kmz|kml)\s*$', '', filename, flags=re.IGNORECASE)
            route_name = clean_filename

        return {
            "routeId": unique_route_id,      # <-- Stable Unique ID, key for the map
            "routeName": route_name,         # <-- Descriptive Name (Internal KML Name, fixed if generic)
            "originalFileName": filename,    # <-- NEW: The file we processed
            "routeColorHex": dart_color_string,
            "routeColorName": color_name,
            "fullPolyline": coordinates      # <-- All coordinates for the entire KML/KMZ file
        }

    except ET.ParseError as e:
        print(f"Error parsing XML content from {filepath}: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred processing content from {filepath}: {e}")
        return None


def convert_kml_files_to_json():
    """Main function to iterate over KMZ/KML files and generate a single JSON lookup."""
    if not os.path.exists(INPUT_DIR):
        print(f"Creating input directory '{INPUT_DIR}'. Please place your KMZ/KML files inside it.")
        os.makedirs(INPUT_DIR)
        return

    all_routes_data = {} 
    
    valid_extensions = ('.kml', '.kmz')
    files_to_process = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith(valid_extensions)]

    if not files_to_process:
        print(f"No KML or KMZ files found in '{INPUT_DIR}'. Please add your route files.")
        return

    for filename in files_to_process:
        filepath = os.path.join(INPUT_DIR, filename)
        print(f"Processing: {filename}...")
        kml_content = get_kml_content(filepath)
        # MODIFIED: Passed 'filename'
        route_data = extract_data_from_content(kml_content, filepath, filename)

        if route_data:
            # Use the unique ID as the key for the lookup map
            # This is where duplicate IDs will overwrite data
            all_routes_data[route_data["routeId"]] = route_data

    # Write the combined data to the output JSON file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(all_routes_data, f, indent=2)

    print(f"\n--- SUCCESS ---")
    print(f"Successfully processed {len(all_routes_data)} routes.")
    print(f"Data saved to {OUTPUT_FILE}")
    print("\nNEXT STEP: Open 'routes_polyline_lookup.json' and use the 'fullPolyline' array to determine the 'startPolyIndex' and 'endPolyIndex' for each segment in your Dart segmentation map.")
    print("-----------------\n")


if __name__ == '__main__':
    convert_kml_files_to_json()
