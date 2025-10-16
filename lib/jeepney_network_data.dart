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
    'N01': Node(
        id: 'N01',
        position: const LatLng(15.168122223153073, 120.58459637453271),
        name: 'Bayanihan Jeepney Terminal'),
    'N02': Node(
        id: 'N02',
        position: const LatLng(15.178132414995723, 120.58728291382715),
        name: 'Dau Access Road'),

    // 2. Clark/Sapang Bato area
    'N03': Node(
        id: 'N03',
        position: const LatLng(15.16305204732774, 120.55473730830217),
        name: 'Fil-Am Friendship Highway'),
    'N04': Node(
        id: 'N04',
        position: const LatLng(15.170933172394623, 120.51501727223763),
        name: 'Sapang Bato Barangay Hall'),

    // 3. Balibago/Marquee area
    'N05': Node(
        id: 'N05',
        position: const LatLng(15.16946765414794, 120.58930685405767),
        name: 'Balibago (Road to Dau)'),
    'N06': Node(
        id: 'N06',
        position: const LatLng(15.162560370889945, 120.59107576216996),
        name: 'Marlim Avenue'),
    'N07': Node(
        id: 'N07',
        position: const LatLng(15.162476539579057, 120.60835134728958),
        name: 'Marquee Mall by Ayala Malls'),
    'N08': Node(
        id: 'N08',
        position: const LatLng(15.153719303730984, 120.6048240781205),
        name: 'Pandan-Tabun Road'),
    'N09': Node(
        id: 'N09',
        position: const LatLng(15.14633138968331, 120.6140672764861),
        name: 'San Vicente Street, Capaya'),
    'N10': Node(
        id: 'N10',
        position: const LatLng(15.14566785692904, 120.61719106223454),
        name: 'Nepomuceno & Lazatin, Capaya'),
    'N11': Node(
        id: 'N11',
        position: const LatLng(15.157385727790757, 120.59225013133326),
        name: 'Robinsons Angeles'),
    'N12': Node(
        id: 'N12',
        position: const LatLng(15.15307225795962, 120.59192571795558),
        name: 'Marisol Roundabout'),

    // 4. Inner City/Pampang
    'N13': Node(
        id: 'N13',
        position: const LatLng(15.150806937623226, 120.59264629206302),
        name: 'Marisol-Pampang Jeepney Terminal'),
    'N14': Node(
        id: 'N14',
        position: const LatLng(15.149946558933049, 120.5842657630103),
        name: 'Arayat Blvd.-Arayat Road'),
    'N15': Node(
        id: 'N15',
        position: const LatLng(15.147178515304587, 120.58615084430178),
        name: '136 San Francisco St., Angeles, Pampanga'),
    'N16': Node(
        id: 'N16',
        position: const LatLng(15.143470904682285, 120.588363928338),
        name: 'Henson Ville Terminal'),
    'N17': Node(
        id: 'N17',
        position: const LatLng(15.145477507981582, 120.59523398671675),
        name: 'Angeles University Foundation'),
    'N18': Node(
        id: 'N18',
        position: const LatLng(15.142692807000863, 120.59652645730344),
        name: 'Angeles Intersection/Roundabout'),
    'N19': Node(
        id: 'N19',
        position: const LatLng(15.138839458618483, 120.59371441157968),
        name: '100a Santo Entiero St'),
    'N20': Node(
        id: 'N20',
        position: const LatLng(15.137831061596211, 120.58886265671481),
        name: 'Miranda-Plaridel Street Intersection'),
    'N21': Node(
        id: 'N21',
        position: const LatLng(15.13937751108868, 120.58659662391537),
        name: 'Newstar Shopping Mart'),
    'N22': Node(
        id: 'N22',
        position: const LatLng(15.136961541120508, 120.58649797187472),
        name: '248-102 Rizal Street Ext'),
    'N23': Node(
        id: 'N23',
        position: const LatLng(15.136078628012532, 120.5883267552127),
        name: '304 Santo Rosario St, Angeles, Pampanga'),
    'N24': Node(
        id: 'N24',
        position: const LatLng(15.134825927046702, 120.59063095384975),
        name: 'Holy Rosary Parish Church'),
    'N25': Node(
        id: 'N25',
        position: const LatLng(15.135588453717585, 120.59330024080815),
        name: 'Lakandula Street'),
    'N26': Node(
        id: 'N26',
        position: const LatLng(15.133639713699715, 120.58430415229193),
        name: 'Rizal Street Ext'),
    'N27': Node(
        id: 'N27',
        position: const LatLng(15.13460213899443, 120.567100472649),
        name: 'Sunset Estates'),

    // 5. SM Telabastagan / Southern Extensions
    'N28': Node(
        id: 'N28',
        position: const LatLng(15.12168324431814, 120.60046354507185),
        name: 'SM Telabastagan Terminal'),
    'N29': Node(
        id: 'N29',
        position: const LatLng(15.134251048500333, 120.59120807974612),
        name: 'Holy Angel University'),
    'N30': Node(
        id: 'N30',
        position: const LatLng(15.127062195834817, 120.59689172979789),
        name: 'Super 8 (San Fernando-Villa Pampang Terminal)'),
    'N31': Node(
        id: 'N31',
        position: const LatLng(15.125346577935126, 120.59816782088681),
        name: 'Sacred Heart Medical Center'),
    'N32': Node(
        id: 'N32',
        position: const LatLng(15.123673715007401, 120.5990014935524),
        name: 'Chevalier School'),
    'N33': Node(
        id: 'N33',
        position: const LatLng(15.13882801470678, 120.58755922236452),
        name: 'Jollibee Rotonda, San Nicolas Market'),
    'N34': Node(
        id: 'N34',
        position: const LatLng(15.166489559701413, 120.5771989295957),
        name: 'Public Transport Terminal (SM City Clark)'),
    'N35': Node(
        id: 'N35',
        position: const LatLng(15.166491757108336, 120.58282696723248),
        name: 'Henson Ville Terminal'),
    'N36': Node(
        id: 'N36',
        position: const LatLng(15.158228767911242, 120.5921409581609),
        name: 'Systems Plus Balibago'),

    'N37': Node(
        id: 'N37',
        position: const LatLng(15.152633172342862, 120.58335530153454),
        name: 'Our Lady of Fatima Church'),

    'N38': Node(
        id: 'N38',
        position: const LatLng(15.160243050500826, 120.5826226717244),
        name: 'Poleng Villa'),

    'N39': Node(
        id: 'N39',
        position: const LatLng(15.161217823411056, 120.58175658010379),
        name: 'Malabanias Road'),

    'N40': Node(
        id: 'N40',
        position: const LatLng(15.12968339481647, 120.57538621875474),
        name: 'Overpass Intersection'),

    // 6. New nodes from the extended list (N41, N42, N43, N44)
    'N41': Node(
        id: 'N41',
        position: const LatLng(15.144474509315053, 120.55938943379525),
        name: 'Security Bank, cor Poinsettia Avenue'),
    'N42': Node(
        id: 'N42',
        position: const LatLng(15.152794350180983, 120.59216746673009),
        name: '7-eleven Ninoy Aquino (Marisol)'),
    'N43': Node(
        id: 'N43',
        position: const LatLng(15.135573995928794, 120.58730678010825),
        name: 'Nepo Mart'),
    'N44': Node(
        id: 'N44',
        position: const LatLng(15.135941494350044, 120.59146839921544),
        name: '1225 Miranda-Sto. Entierro St. Intersection'),
    'N48': Node(
        id: 'N48',
        position: const LatLng(15.163763689386034, 120.55613180852866),
        name: 'Mr. Wang Chinese Restaurant'),
    'N49': Node(
        id: 'N49',
        position: const LatLng(15.165155111956631, 120.55881787134152),
        name: 'Little Chinatown'),
    'N50': Node(
        id: 'N50',
        position: const LatLng(15.1662477040375, 120.56122979357431),
        name: 'Oasis Entrance'),
    'N51': Node(
        id: 'N51',
        position: const LatLng(15.166656966092535, 120.5647177933902),
        name: 'Clark Side Entrance'),
    'N53': Node(
        id: 'N52',
        position: const LatLng(15.166168930349212, 120.57024324786535),
        name: 'Don Juico Avenue'),
    'N52': Node(
        id: 'N53',
        position: const LatLng(15.166615217878718, 120.56704796317382),
        name: 'Don Juico Avenue 2'),
    'N54': Node(
        id: 'N54',
        position: const LatLng(15.166136729276836, 120.57024235353519),
        name: 'Red Planet Clark'),
    'N55': Node(
        id: 'N55',
        position: const LatLng(15.165387890177486, 120.57471089049888),
        name: 'Margarita Station'),
    'N56': Node(
        id: 'N56',
        position: const LatLng(15.165285476382685, 120.57575793962214),
        name: '21st Street'),
    'N57': Node(
        id: 'N57',
        position: const LatLng(15.165609994874618, 120.57855944351667),
        name: 'Tratorria Altrove'),
    'N58': Node(
        id: 'N58',
        position: const LatLng(15.166484629946067, 120.58290665127366),
        name: 'Bayad Center'),
    'N59': Node(
        id: 'N59',
        position: const LatLng(15.130152748894668, 120.59507946010962),
        name: 'LBS Bakeshop Angeles'),
    'N60': Node(
        id: 'N60',
        position: const LatLng(15.13229392333138, 120.59309621180884),
        name: 'Eggs N Brekky Angeles'),
    'N61': Node(
        id: 'N61',
        position: const LatLng(15.140600515589039, 120.59174485203957),
        name: 'The Infinite Shawarma'),
    'N62': Node(
        id: 'N62',
        position: const LatLng(15.141704765411255, 120.59093616601994),
        name: 'C Dayrit Street'),
    'N63': Node(
        id: 'N63',
        position: const LatLng(15.142656253901281, 120.58973990079353),
        name: 'Rizal Street'),
    'N64': Node(
        id: 'N64',
        position: const LatLng(15.145006023676963, 120.58871255687673),
        name: 'Pampang Public Market Entrance'), // Duplicate of N41
    'N65': Node(
        id: 'N65',
        position: const LatLng(15.145514715514064, 120.5875223098476),
        name: 'San Francisco Street'),
    'N66': Node(
        id: 'N66',
        position: const LatLng(15.14991280521148, 120.61464551624323),
        name: 'Pandan Tabun Road'),
    'N67': Node(
        id: 'N67',
        position: const LatLng(15.14963115190089, 120.60220630811929),
        name: 'Puregold Pandan'),
    'N68': Node(
        id: 'N68',
        position: const LatLng(15.133546652969557, 120.59186222892947),
        name: 'Centro Coffee Shop'),
    'N69': Node(
        id: 'N69',
        position: const LatLng(15.134989228449365, 120.59287583370713),
        name: 'Lakandula Street'),
    'N70': Node(
        id: 'N70',
        position: const LatLng(15.148691305107189, 120.61407048214025),
        name: 'Powerfill Tabun'),
    'N71': Node(
        id: 'N71',
        position: const LatLng(15.141308400266706, 120.58775026702676),
        name: 'Henson Street'),
    'N72': Node(
        id: 'N72',
        position: const LatLng(15.136626325460645, 120.5920199247791),
        name: 'Los Komunidad'),
    'N73': Node(
        id: 'N73',
        position: const LatLng(15.149645403047593, 120.5904952838617),
        name: 'Pax et Lumen'),
    'N74': Node(
        id: 'N74',
        position: const LatLng(15.152068686603025, 120.59163790490092),
        name: 'Red 7 Fitness Gym'),
    'N75': Node(
        id: 'N75',
        position: const LatLng(15.147523433478703, 120.58952637761352),
        name: 'Aling Lucing'),
    'N76': Node(
        id: 'N76',
        position: const LatLng(15.162409441941097, 120.5840377988305),
        name: 'Narciso Street'),
    'N77': Node(
        id: 'N77',
        position: const LatLng(15.159168719008498, 120.5812547734269),
        name: 'Richtofen Street'),
    'N78': Node(
        id: 'N78',
        position: const LatLng(15.156815182389876, 120.58335565029219),
        name: 'Richtofen Street 2'),
    'N79': Node(
        id: 'N79',
        position: const LatLng(15.164848075983, 120.58323030142397),
        name: 'Narciso Street 2'),
    'N80': Node(
      id: 'N80',
      position: const LatLng(15.160098314474805, 120.60822613648322),
      name: 'Pandan Road 2',
    ),
    'N81': Node(
      id: 'N81',
      position: const LatLng(15.160709285735642, 120.60932047775378),
      name: 'Pandan Road 1',
    ),
    'N82': Node(
      id: 'N82',
      position: const LatLng(15.132805286561142, 120.56995474109118),
      name: 'Grumpy Joes',
    ),
    'N83': Node(
        id: 'N83',
        position: const LatLng(15.132857758003556, 120.58630260372267),
        name: 'Villa Teressa Gate'),
    'N84': Node(
        id: 'N84',
        position: const LatLng(15.135260646309115, 120.58784167758687),
        name: 'Nepo Mall'),
    'N85': Node(
        id: 'N85',
        position: const LatLng(15.136306143152643, 120.58606339835927),
        name: '293 Rizal Street Ext'),
    'N86': Node(
        id: 'N86',
        position: const LatLng(15.133027, 120.581585),
        name: 'NEPLUM Inc.'),
    'N87': Node(
        id: 'N87',
        position: const LatLng(15.131166647682385, 120.57691751235289),
        name: '7-Eleven 5350 Holy Family Village'),
    'N88': Node(
      id: 'N88',
      position: const LatLng(15.151449, 120.588355),
      name: 'Holy Family Village Entrance',
    ),
    'N89': Node(
        id: 'N89',
        position: const LatLng(15.136385932385183, 120.5877362515324),
        name: 'Sto Rosario st, Cor Plaridel Street'),
    'N90': Node(
      id: 'N90',
      position: const LatLng(15.137220514003628, 120.5882569508195),
      name: '2021 Plaridel Street',
    ),
    'N91': Node(
      id: 'N91',
      position: const LatLng(15.149525165682881, 120.58331197311372),
      name: 'Jollibee Pampang',
    ),
    'N92': Node(
      id: 'N92',
      position: const LatLng(15.149340451935991, 120.5783740312681),
      name: 'City College of Angeles/Angeles City National High School',
    ),
    'N93': Node(
      id: 'N93',
      position: const LatLng(15.148202175873555, 120.57434314275908),
      name: 'Pampang Barangay Hall',
    ),
    'N94': Node(
      id:'N94',
      position: const LatLng(15.145087133917675, 120.5645758183711),
      name: 'Timog Park Subd Gate 1'
    ),
    'N95': Node(
      id: 'N95',
      position: const LatLng(15.150625116166582, 120.55940322312249),
      name: 'Friendship Plaza',
    ),
    'N96': Node(
      id: 'N96',
      position: const LatLng(15.152375049439994, 120.55945199266341),
      name: 'Starbucks Friendship Highway Angeles City',
    ),
    'N97': Node(
      id: 'N97',
      position: const LatLng(15.15399517783768, 120.56032463933668),
      name: 'Shabu khan',
    ),
    'N98': Node(
      id: 'N98',
      position: const LatLng(15.15511899700585, 120.56028528242953),
      name: 'Papang\'s Crispy Pata',
    ),
    'N99': Node(
      id: 'N99',
      position: const LatLng(15.158073816058145, 120.55969767237336),
      name: 'Fil-Am Friendship Hwy Bridge',
    ),
    'N100': Node(
      id: 'N100',
      position: const LatLng(15.15918156717312, 120.55688757597602),
      name: 'Boom Chicken',
    ),
    'N101': Node(
      id: 'N101',
      position: const LatLng(15.162524005697943, 120.55326259377615),
      name: 'Family KTV',
    ),
    'N102': Node(
      id: 'N102',
      position: const LatLng(15.162522622073261, 120.55177541806499),
      name: 'Korean Furniture Factory Showroom',
    ),
    'N103': Node(
      id: 'N103',
      position: const LatLng(15.160521149752318, 120.55118214642378),
      name: 'Jose P Laurel Ave',
    ),
    'N104': Node(
      id: 'N104',
      position: const LatLng(15.161673408313732, 120.54829308824665),
      name: 'Jose P Laurel Ave',
    ),
    'N105': Node(
      id: 'N105',
      position: const LatLng(15.164408767372109, 120.54755346452164),
      name: 'Jose P Laurel Ave',
    ),
    'N106': Node(
      id: 'N106',
      position: const LatLng(15.171108942340991, 120.5384758325827),
      name: 'Jose P Laurel Ave',
    ),
    'N107': Node(
      id: 'N107',
      position: const LatLng(15.170275806728705, 120.52783824781157),
      name: 'Jose P Laurel Ave',
    ),
    'N108': Node( // Renamed the next entries to N108 and N109 to continue sequential numbering
      id: 'N108',
      position: const LatLng(15.172601476676132, 120.52186767026078),
      name: 'Jose P Laurel Ave',
    ),
    'N109': Node(
      id: 'N109',
      position: const LatLng(15.172197272208226, 120.517081585048),
      name: 'Jose P Laurel Ave',
    ),
    'N110': Node(
      id: 'N110',
      position: const LatLng(15.17169723144669, 120.51692362796035),
      name: 'Sapang Bato Bridge',
    ),
  };
}

// --- STEP 2: JEEPNEY ROUTE EDGE DEFINITIONS (UNCHANGED) ---
final List<Map<String, dynamic>> rawEdgeDefinitions = [
  // 1. MAIN GATE - FRIENDSHIP (Sand) (Simple Route: Outbound/Inbound)
  {
    'route': 'MAIN GATE - FRIENDSHIP (Sand) Outbound',
    'color': const Color(0xFFC2B280),
    'nodes': [
      'N03',
      'N48',
      'N49',
      'N50',
      'N51',
      'N52',
      'N53',
      'N54',
      'N55',
      'N56',
      'N57',
      'N58',
      'N35'
    ]
  },
  {
    'route': 'MAIN GATE - FRIENDSHIP (Sand) Inbound',
    'color': const Color(0xFFC2B280),
    'nodes': [
      'N35',
      'N58',
      'N57',
      'N56',
      'N55',
      'N54',
      'N53',
      'N52',
      'N51',
      'N50',
      'N49',
      'N48',
      'N03'
    ]
  },

// 2. C’POINT - BALIBAGO - H’WAY (Grey) (Loop Route: Single Entry)
  {
    'route': 'C’POINT - BALIBAGO - H’WAY (Grey) Loop',
    'color': const Color(0xFF808080),
    'nodes': [
      'N34',
      'N01',
      'N05', // N35 removed from this section of the loop
      'N06',
      'N11',
      'N12',
      'N88', // NEW Node
      'N14',
      'N15',
      'N65',
      'N64',
      'N16',
      'N71',
      'N33',
      'N22',
      'N85', // Defined in previous step
      'N26',
      'N83', // Defined in previous step
      'N84', // Defined in previous step
      'N43',
      'N89', // NEW Node
      'N90',
      'N20',
      'N33', // Second Pass
      'N71',
      'N16',
      'N64',
      'N65',
      'N15',
      'N14',
      'N88', // Return Loop Node
      'N12',
      'N11',
      'N06',
      'N05',
      'N01' // Last node in the list. Loop logic connects N01 to N34.
    ]
  },

  // 3. SM CITY - MAIN GATE – DAU (Various) (Simple Route: Outbound/Inbound)
  {
    'route': 'SM CITY - MAIN GATE – DAU (Various) Outbound',
    'color': const Color.fromARGB(255, 63, 63, 63),
    'nodes': ['N34', 'N01', 'N05', 'N02']
  },
  {
    'route': 'SM CITY - MAIN GATE – DAU (Various) Inbound',
    'color': const Color.fromARGB(255, 63, 63, 63),
    'nodes': ['N02', 'N05', 'N01', 'N34']
  },

// 4. CHECKPOINT - HENSONVILLE - HOLY (White) (Loop Route: Single Entry)
  {
    'route': 'CHECKPOINT - HENSONVILLE - HOLY (White) Loop',
    'color': Colors.white,
    'nodes': [
      'N35', // START
      'N76',
      'N39',
      'N38',
      'N77',
      'N78',
      'N37',
      'N14',
      'N15',
      'N65',
      'N64',
      'N16',
      'N71',
      'N33',
      'N22',
      'N89', // Requires N89 definition
      'N23',
      'N24',
      'N29',
      'N68',
      'N69',
      'N44',
      'N20',
      'N33',
      'N71',
      'N16',
      'N64',
      'N65',
      'N15',
      'N14',
      'N37',
      'N78',
      'N77',
      'N38',
      'N39',
      'N76' // END (Loop logic connects N76 back to N35)
    ]
  },

// 5. SAPANG BATO – ANGLES (Maroon) (Simple Route: Outbound/Inbound)
{
  'route': 'SAPANG BATO – ANGELES (Maroon) Outbound',
  'color': const Color(0xFF800000), 
  'nodes': [
    'N04', 
    'N110',
    'N109',
    'N108',
    'N107',
    'N106',
    'N105',
    'N104',
    'N103',
    'N102',
    'N101',
    'N03',
    'N100',
    'N99',
    'N98',
    'N97',
    'N96',
    'N95',
    'N41',
    'N94',
    'N93',
    'N92',
    'N91',
    'N14',
    'N15', 
  ],
},
{
  'route': 'SAPANG BATO – ANGELES (Maroon) Inbound',
  'color': const Color(0xFF800000),
  'nodes': [
    'N15',
    'N14',
    'N91',
    'N92',
    'N93',
    'N94',
    'N41',
    'N95',
    'N96',
    'N97',
    'N98',
    'N99',
    'N100',
    'N03',
    'N101',
    'N102',
    'N103',
    'N104',
    'N105',
    'N106',
    'N107',
    'N108',
    'N109',
    'N110',
    'N04',
  ],
},

  // 6. CHECKPOINT - HOLY - HIGHWAY (Lavander) (Loop Route: Single Entry) - UPDATED
  {
    'route': 'CHECKPOINT - HOLY - HIGHWAY (Lavander) Loop',
    'color': Colors.indigo,
    'nodes': [
      'N34',
      'N01',
      'N05',
      'N06',
      'N11',
      'N12',
      'N74',
      'N73',
      'N75',
      'N64',
      'N16',
      'N71',
      'N33',
      'N22',
      'N85', // 293 Rizal Street Ext
      'N26', // Rizal Street Ext
      'N83', // Villa Teressa Gate
      'N84', // Nepo Mall
      'N23',
      'N24',
      'N29',
      'N68',
      'N69',
      'N25',
      'N72',
      'N19',
      'N18',
      'N17',
      'N13',
      'N12',
      'N11',
      'N06',
      'N05',
      'N01' // Last node in the sequence
    ] // The Loop logic will connect N01 back to N34
  },

// 7. MARISOL - PAMPANG (Green)
  {
    'route': 'MARISOL - PAMPANG (Green) Outbound',
    'color': Colors.green,
    'nodes': [
      'N15',
      'N65',
      'N64',
      'N16',
      'N71',
      'N33',
      'N22',
      'N89',
      'N23',
      'N24',
      'N29',
      'N68',
      'N69',
      'N25',
      'N72',
      'N19',
      'N18',
      'N17',
      'N13'
    ]
  },
  {
    'route': 'MARISOL - PAMPANG (Green) Inbound',
    'color': Colors.green,
    'nodes': [
      'N13',
      'N17',
      'N18',
      'N19',
      'N72',
      'N25',
      'N69',
      'N68',
      'N29',
      'N24',
      'N23',
      'N89',
      'N22',
      'N33',
      'N71',
      'N16',
      'N64',
      'N65',
      'N15'
    ]
  },
  {
    'route': 'PANDANG - PAMPANG (Blue) Loop', // Route name shown on map or list
    'color': Colors.blue, // Display color for this route
    'nodes': [
      // Ordered list of waypoints or stops
      'N07',
      "N81",
      'N80',
      'N08',
      'N67',
      'N18',
      'N19',
      'N72',
      'N44',
      'N20',
      'N33',
      'N22',
      'N89',
      'N23',
      'N24',
      'N29',
      'N68',
      'N69',
      'N25',
      'N72',
      'N19',
      'N18',
      'N67',
      'N08',
      'N80', // <- Must exist in _defineAllNodes() with coordinates
      'N81', // <- Must exist in _defineAllNodes() with coordinates
      'N07' // Completes the loop (route returns to starting point)
    ]
  },

// 9. SUNSET - NEPO (Orange)
  {
    'route': 'SUNSET - NEPO (Orange) Loop',
    'color': Colors.deepOrange,
    'nodes': [
      'N27',
      'N82',
      'N40',
      'N87',
      'N86',
      'N26',
      'N83',
      'N84',
      'N43',
      'N85',
      'N26',
      'N86',
      'N87',
      'N40',
      'N82',
      'N27'
    ]
  },

// 10. VILLA - PAMPANG SM TELEBESTAGEN (Yellow)
  {
    'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Outbound',
    'color': Colors.yellow,
    'nodes': [
      'N15',
      'N65',
      'N64',
      'N16',
      'N63',
      'N62',
      'N61',
      'N19',
      'N24',
      'N29',
      'N60',
      'N59',
      'N30',
      'N31',
      'N32',
      'N28'
    ]
  },
  {
    'route': 'VILLA - PAMPANG SM TELEBESTAGEN (Yellow) Inbound',
    'color': Colors.yellow,
    'nodes': [
      'N28',
      'N32',
      'N31',
      'N30',
      'N59',
      'N60',
      'N68',
      'N69',
      'N25',
      'N72',
      'N19',
      'N61',
      'N62',
      'N63',
      'N16',
      'N64',
      'N65',
      'N15'
    ]
  },

// 11. CAPAYA - ANGELES (Pink) - CONVERTED TO A LOOP
{
  'route': 'CAPAYA - ANGELES (Pink) Loop',
  'color': Colors.pink,
  'nodes': [
    'N10', // START
    'N09',
    'N70',
    'N66',
    'N08',
    'N67',
    'N18',
    'N19',
    'N72',
    'N44',
    'N20',
    'N33',
    'N22',
    'N89', // Requires N89 definition
    'N23',
    'N24',
    'N29',
    'N68',
    'N69',
    'N25',
    'N72', // Loopback segment starts here
    'N19',
    'N18',
    'N67',
    'N08',
    'N66',
    'N70',
    'N09',
    'N10' // END (Loop logic connects N10 back to N10)
  ]
},

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

List<String> get uniqueNodeNames {
  // Access the values of the already initialized map 'allNodes'
  final allNames = allNodes.values.map((node) => node.name).toList();
  
  // Use a Set to ensure all names are unique, then return as a List
  return allNames.toSet().toList();
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
    final routeColorName =
        _extractColorName(routeName); // Extract the simple name

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
          routeColorName:
              routeColorName, // <-- FIX: Passing the required string name
          // PASSING THE ROUTE COLOR AND POLYLINE POINTS
          routeColor: routeColor,
          polylinePoints: [startPos, endPos],
        );

        // Add the edge to the starting node's list
        adjacencyList.putIfAbsent(startId, () => []).add(edge);
      } else {
        print(
            'Error: Missing node in route $routeName. Check IDs $startId or $endId.');
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

        final edge = Edge(
          startNodeId: lastId,
          endNodeId: firstId,
          weight: weight,
          routeName: routeName,
          routeColorName: routeColorName,
          routeColor: routeColor,
          polylinePoints: [lastPos, firstPos],
        );

        adjacencyList.putIfAbsent(lastId, () => []).add(edge);
      } else {
        print(
            'Error: Missing loop endpoints for $routeName: $lastId → $firstId');
      }
    }
  }

  // Finally, build and return the graph
  return JeepneyGraph(
    nodes: allNodes,
    adjacencyList: adjacencyList,
  );
}
