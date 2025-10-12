/// Configuration constants for the Jeepney pathfinding algorithm.

// --- Time and Speed Constants ---
// Assumed average walking time per kilometer (Slightly reduced speed: 4 km/h).
// Increasing this makes walking relatively more expensive.
const double WALK_TIME_PER_KM_MINUTES = 15.0; // INCREASED (was 12.0)

// Assumed average jeepney speed in kilometers per minute (15 km/h speed).
const double JEEPNEY_AVG_SPEED_KM_PER_MIN = 0.25; 

// --- Penalty Constants (Crucial for eliminating bad multi-transfer routes) ---

/// The real-world estimated time a user waits for a jeep at a transfer point (for display).
const double REAL_TRANSFER_WAIT_TIME_MINUTES = 10.0; // Reduced to 10 min

/// Multiplier to drastically discourage transfers. The penalty should be large enough 
/// to discourage transfers, but not so large that it makes walking across the city look faster.
// Reduced the multiplier to make the penalty more reasonable.
const double TRANSFER_DISCOURAGEMENT_MULTIPLIER = 5.0; // REDUCED (was 10.0)

/// The effective, highly-penalized cost used in Dijkstra's algorithm.
// NEW EFFECTIVE PENALTY: 10.0 * 5.0 = 50.0 minutes (Much more reasonable than 150.0)
const double EFFECTIVE_TRANSFER_PENALTY_MINUTES = 
    REAL_TRANSFER_WAIT_TIME_MINUTES * TRANSFER_DISCOURAGEMENT_MULTIPLIER;


// --- GPS Snapping ---

/// The maximum distance (in kilometers) a user's GPS point can be from a network
/// node to be considered for snapping (e.g., 500 meters).
const double MAX_SNAP_DISTANCE_KM = 0.5;