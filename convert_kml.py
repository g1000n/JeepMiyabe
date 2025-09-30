import zipfile
import re
import json
from bs4 import BeautifulSoup

def convert_kml_to_json(file_path):
    """Reads a KML/KMZ file, extracts polyline coordinates, and formats them as JSON."""
    
    kml_content = None
    if file_path.endswith('.kmz'):
        with zipfile.ZipFile(file_path, 'r') as kmz:
            kml_content = kmz.read('doc.kml')
    elif file_path.endswith('.kml'):
        with open(file_path, 'r', encoding='utf-8') as f:
            kml_content = f.read()
    else:
        print(f"Error: File must be .kml or .kmz: {file_path}")
        return []

    soup = BeautifulSoup(kml_content, 'xml')
    placemarks = soup.find_all('Placemark')
    
    json_routes = []

    # Simple list of colors for unique assignment (you can change these later)
    # R G B A
    default_colors = [
        "0xFFF44336", "0xFF2196F3", "0xFF4CAF50", "0xFFFF9800", 
        "0xFF9C27B0", "0xFF00BCD4", "0xFFCDDC39", "0xFFFFC107",
        "0xFF795548", "0xFF607D8B", "0xFFE91E63", "0xFF03A9F4"
    ]
    color_index = 0

    for placemark in placemarks:
        name_tag = placemark.find('name')
        coord_tag = placemark.find('coordinates')
        
        if name_tag and coord_tag:
            name = name_tag.text.strip()
            
            # The coordinate string is 'lon,lat,alt lon,lat,alt ...'
            coords_string = coord_tag.text.strip()
            points = coords_string.split()
            lat_lng_list = []

            for point in points:
                # Format is lon,lat,alt. We need to swap to lat, lon
                try:
                    lon, lat, _ = map(float, point.split(','))
                    # Store as dictionary for JSON output
                    lat_lng_list.append({"lat": lat, "lon": lon}) 
                except ValueError:
                    continue 

            if lat_lng_list:
                route_data = {
                    "name": name,
                    # Assign a unique color from the list and cycle
                    "color": default_colors[color_index % len(default_colors)],
                    "points": lat_lng_list
                }
                json_routes.append(route_data)
                color_index += 1

    return json_routes

# --- Execution ---
all_routes = []

# Process the first map's data
map1_data = convert_kml_to_json('routes_map1.kmz')
all_routes.extend(map1_data)

# Process the second map's data
map2_data = convert_kml_to_json('routes_map2.kmz')
all_routes.extend(map2_data)

# Write the combined data to a single JSON file
output_file = 'routes_data.json'
with open(output_file, 'w') as f:
    json.dump(all_routes, f, indent=2)

print(f"Successfully combined {len(map1_data) + len(map2_data)} routes into {output_file}")