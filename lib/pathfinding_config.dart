/// --- WEIGHT AND COST CONFIGURATION ---
/// These constants convert raw distance (km) into an estimated cost (minutes).

/// Average speed of a jeepney in km/min.
/// (Example: 18 km/h = 0.3 km/min. Use a realistic estimate for city travel.)
const double JEEPNEY_AVG_SPEED_KM_PER_MIN = 0.45; 

/// Estimated time (in minutes) a passenger waits for a connecting jeepney
/// when transferring between routes. This is a crucial cost penalty.
const double TRANSFER_WAIT_PENALTY_MINUTES = 8.0; 

/// Estimated time (in minutes) to walk 1 kilometer.
/// (Example: 5 km/h walking speed = 12 minutes/km)
const double WALK_TIME_PER_KM_MINUTES = 12.0; 
