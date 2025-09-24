// routes.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final List<Polyline> jeepneyRoutes = [
  // MAIN GATE - FRIENDSHIP (Sand/Brown)
  Polyline(
    polylineId: PolylineId('mainGate_friendship'),
    color: Colors.brown,
    width: 5,
    points: [
      LatLng(15.1449, 120.5887),
      LatLng(15.1460, 120.5900),
      LatLng(15.1470, 120.5920),
    ],
  ),

  // C’POINT - BALIBAGO - H’WAY (Grey)
  Polyline(
    polylineId: PolylineId('checkpoint_balibago_highway'),
    color: Colors.grey,
    width: 5,
    points: [
      LatLng(15.1450, 120.5850),
      LatLng(15.1465, 120.5870),
      LatLng(15.1480, 120.5890),
    ],
  ),

  // SM CITY - MAIN GATE – DAU (Purple)
  Polyline(
    polylineId: PolylineId('smCity_mainGate_dau'),
    color: Colors.purple,
    width: 5,
    points: [
      LatLng(15.1440, 120.5880),
      LatLng(15.1455, 120.5900),
      LatLng(15.1470, 120.5925),
    ],
  ),

  // CHECKPOINT - HENSONVILLE - HOLY (White)
  Polyline(
    polylineId: PolylineId('checkpoint_henson_holy'),
    color: Colors.white,
    width: 5,
    points: [
      LatLng(15.1450, 120.5860),
      LatLng(15.1465, 120.5880),
      LatLng(15.1480, 120.5900),
    ],
  ),

  // SAPANG BATO – ANGELES (Maroon)
  Polyline(
    polylineId: PolylineId('sapangbato_angeles'),
    color: Colors.redAccent,
    width: 5,
    points: [
      LatLng(15.1435, 120.5850),
      LatLng(15.1450, 120.5870),
      LatLng(15.1465, 120.5890),
    ],
  ),

  // CHECKPOINT - HOLY - HIGHWAY (Lavender)
  Polyline(
    polylineId: PolylineId('checkpoint_holy_highway'),
    color: Colors.purpleAccent, // Lavender
    width: 5,
    points: [
      LatLng(15.1445, 120.5865),
      LatLng(15.1460, 120.5885),
      LatLng(15.1475, 120.5905),
    ],
  ),

  // MARISOL - PAMPANG (Green)
  Polyline(
    polylineId: PolylineId('marisol_pampang'),
    color: Colors.green,
    width: 5,
    points: [
      LatLng(15.1450, 120.5855),
      LatLng(15.1465, 120.5875),
      LatLng(15.1480, 120.5895),
    ],
  ),

  // PANDANG - PAMPANG (Blue)
  Polyline(
    polylineId: PolylineId('pandang_pampang'),
    color: Colors.blue,
    width: 5,
    points: [
      LatLng(15.1440, 120.5845),
      LatLng(15.1455, 120.5865),
      LatLng(15.1470, 120.5885),
    ],
  ),

  // SUNSET - NEPO (Orange)
  Polyline(
    polylineId: PolylineId('sunset_nepo'),
    color: Colors.orange,
    width: 5,
    points: [
      LatLng(15.134617204729926, 120.56709447917916),
      LatLng(15.138662661480405, 120.56300148325974),
      LatLng(15.138832832253568, 120.56286045230787),
      LatLng(15.139038252493995, 120.56271186618433),
      LatLng(15.142793969392686, 120.56030236544072),
      LatLng(15.143688116180156, 120.55958853787395),
      LatLng(15.144072206600505, 120.55942232286945),
      LatLng(15.144387014360795, 120.55938580594108),

      LatLng(15.144478174823256, 120.55939084276189),
      LatLng(15.145334175913142, 120.56632238173489),
      LatLng(15.144502654894632, 120.56649999854761),
      // LatLng(15.144387014360795, 120.55938580594108),
      // LatLng(15.144387014360795, 120.55938580594108),
      // LatLng(15.144387014360795, 120.55938580594108),
    ],
  ),

  // VILLA - PAMPANG (Yellow)
  Polyline(
    polylineId: PolylineId('villa_pampang'),
    color: Colors.yellow,
    width: 5,
    points: [
      LatLng(15.1440, 120.5840),
      LatLng(15.1455, 120.5860),
      LatLng(15.1470, 120.5880),
    ],
  ),

  // CAPAYA - ANGELES (Pink)
  Polyline(
    polylineId: PolylineId('capaya_angeles'),
    color: Colors.pink,
    width: 5,
    points: [
      LatLng(15.1435, 120.5830),
      LatLng(15.1450, 120.5850),
      LatLng(15.1465, 120.5870),
    ],
  ),
];