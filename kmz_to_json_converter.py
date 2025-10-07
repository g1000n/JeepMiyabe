import xml.etree.ElementTree as ET
import json
import os
import re
import zipfile # Added for KMZ handling

# IMPORTANT:
# 1. This script can now handle BOTH KMZ and KML files directly.
# 2. Place all your KMZ or KML files in a single folder (e.g., 'kml_files').

# --- CONFIGURATION ---
INPUT_DIR = 'kml_files'  # Directory where your KMZ/KML files are located
OUTPUT_FILE = 'jeepney_routes_data.json'
# --- END CONFIGURATION ---


# Register KML namespaces for correct parsing
# KML's default namespace is typically ignored by default, so we map it to an alias 'kml'
NS = {'kml': 'http://www.opengis.net/kml/2.2'}
ET.register_namespace('', 'http://www.opengis.net/kml/2.2')

def get_kml_content(filepath):
    """Reads content from a .kml file or extracts doc.kml from a .kmz file."""
    if filepath.lower().endswith('.kmz'):
        try:
            with zipfile.ZipFile(filepath, 'r') as kmz:
                # KML content in KMZ is usually named 'doc.kml'
                return kmz.read('doc.kml')
        except zipfile.BadZipFile:
            print(f"Error: Invalid KMZ file: {filepath}")
            return None
        except KeyError:
            print(f"Error: KMZ file {filepath} does not contain 'doc.kml'.")
            return None
    elif filepath.lower().endswith('.kml'):
        try:
            with open(filepath, 'rb') as f:
                return f.read()
        except Exception as e:
            print(f"Error reading KML file {filepath}: {e}")
            return None
    return None


def extract_data_from_content(kml_content, filepath):
    """Parses KML content (bytes) to extract polyline data, name, and style color."""
    if kml_content is None:
        return None

    try:
        # Parse KML content from memory
        root = ET.fromstring(kml_content)
        
        # We assume the main data (Placemark) is within a Folder or directly in the root Document
        document = root.find('kml:Document', NS)
        
        # 1. Find the Placemark (which holds the route definition)
        placemark = None
        if document is not None:
             placemark = document.find('kml:Placemark', NS)
        
        # If not in document or document is None, try root
        if placemark is None:
             placemark = root.find('kml:Placemark', NS)
             
        # Often placemarks are nested in folders, we'll try a common structure if simple Placemark fails
        if placemark is None and document is not None:
            folder = document.find('kml:Folder', NS)
            if folder is not None:
                 placemark = folder.find('kml:Placemark', NS)


        if placemark is None:
            # Fallback check, using XPath-like syntax to find the first Placemark anywhere
            for elem in root.iter():
                if elem.tag == '{http://www.opengis.net/kml/2.2}Placemark':
                    placemark = elem
                    break

        if placemark is None:
            print(f"Warning: Could not find Placemark in {filepath}. Skipping.")
            return None

        # 2. Extract Route Name
        route_name_elem = placemark.find('kml:name', NS)
        # Use file basename if name tag is missing
        route_name = route_name_elem.text.strip() if route_name_elem is not None and route_name_elem.text else os.path.basename(filepath)

        # 3. Extract Coordinates (The core data)
        line_string = placemark.find('kml:LineString', NS)
        # Handle LineString or just checking if coordinates exist under geometry tags
        coords_elem = None
        if line_string is not None:
            coords_elem = line_string.find('kml:coordinates', NS)

        # Fallback check for coordinates under different geometry types (e.g., MultiGeometry or just a general coordinates tag)
        if coords_elem is None:
             for elem in placemark.iter():
                 if elem.tag == '{http://www.opengis.net/kml/2.2}coordinates':
                     coords_elem = elem
                     break
        
        if coords_elem is None or not coords_elem.text:
            print(f"Warning: No LineString coordinates found for {route_name}. Skipping.")
            return None

        # Clean the coordinate string: remove newlines, carriage returns, and extra spaces
        coords_string = re.sub(r'[\r\n\t\s]+', ' ', coords_elem.text).strip()
        
        # Split the string by space, then process each Lat/Lon/Alt group
        coordinates = []
        for triplet in coords_string.split(' '):
            if not triplet:
                continue
            # Coordinates in KML are Lon,Lat,Alt (or Lon,Lat). We only need Lat, Lon.
            lon_lat_alt = triplet.split(',')
            if len(lon_lat_alt) >= 2:
                try:
                    lon = float(lon_lat_alt[0])
                    lat = float(lon_lat_alt[1])
                    
                    # FIX: Store as dictionary {"lat": lat, "lon": lon} to match Dart RoutePoint.fromJson
                    coordinates.append({"lat": lat, "lon": lon}) 
                except ValueError:
                    print(f"Warning: Skipping invalid coordinate triplet in {route_name}: {triplet}")


        # 4. Extract Color and format for Dart
        color_map = {
            'Grey': '#808080',
            'Pink': '#FFC0CB',
            'White': '#FFFFFF',
            'Violet': '#4B0082', 
            'Sand': '#C2B280',
            'Green': '#008000',
            'Blue': '#0000FF',
            'Red': '#FF0000',
            'Various': '#3F3F3F', 
            'Orange': '#FF4500',
            'Yellow': '#FFFF00',
            'Lavander': '#4B0082', 
        }
        
        color_match = re.search(r'\((.*?)\)', route_name)
        color_name = color_match.group(1).strip() if color_match else 'Default'
        
        if color_name == 'Violet':
             color_name = 'Lavander'
             
        # Get standard HEX color (e.g., #FF0000)
        color_hex = color_map.get(color_name, '#000000') 
        
        # FIX: Convert to Dart Color String format (e.g., "0xFFFF0000")
        # We need to strip the # and prepend "0xFF" (for full opacity)
        dart_color_string = '0xFF' + color_hex.lstrip('#').upper()
        
        return {
            "name": route_name, # FIX: Key name matches Dart
            "color": dart_color_string, # FIX: Key name and format match Dart
            "points": coordinates # FIX: Key name and format match Dart
        }

    except ET.ParseError as e:
        print(f"Error parsing XML content from {filepath}: {e}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred processing content from {filepath}: {e}")
        return None


def convert_kml_files_to_json():
    """Main function to iterate over KMZ/KML files and generate a single JSON output."""
    if not os.path.exists(INPUT_DIR):
        print(f"Error: Input directory '{INPUT_DIR}' not found. Please create it and place your KMZ/KML files inside.")
        return

    all_routes_data = []
    
    # Process all files ending in .kml or .kmz in the input directory
    valid_extensions = ('.kml', '.kmz')
    files_to_process = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith(valid_extensions)]

    if not files_to_process:
        print(f"No KML or KMZ files found in '{INPUT_DIR}'.")
        return

    print(f"Found {len(files_to_process)} files to process...")

    for filename in files_to_process:
        filepath = os.path.join(INPUT_DIR, filename)
        
        # 1. Get KML content (either from KML file or unzipping KMZ)
        kml_content = get_kml_content(filepath)

        # 2. Extract data from the content
        route_data = extract_data_from_content(kml_content, filepath)

        if route_data:
            all_routes_data.append(route_data)

    # Write the combined data to the output JSON file
    with open(OUTPUT_FILE, 'w') as f:
        json.dump(all_routes_data, f, indent=2)

    print(f"\n--- SUCCESS ---")
    print(f"Successfully processed {len(all_routes_data)} routes.")
    print(f"Data saved to {OUTPUT_FILE}")
    print("-----------------\n")


if __name__ == '__main__':
    convert_kml_files_to_json()
