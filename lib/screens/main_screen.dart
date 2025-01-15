import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'dart:async';
import 'package:pitdeck/config/mapbox_config.dart';
import 'package:pitdeck/models/drop_rarity.dart';
import 'package:pitdeck/widgets/drop_modal.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';

void main() {
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  geo.Position? _userLocation;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      _enableLocationComponent();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high);
      print('Position: ${position.latitude}, ${position.longitude}');

      if (!mounted) return;

      setState(() {
        _userLocation = position;
      });

      // Center map on user's location if map is available
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 2000),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _startLocationUpdates() {
    // Cancel any existing timer
    _locationTimer?.cancel();

    // Get initial location
    _getCurrentLocation();

    // Start periodic updates
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _getCurrentLocation();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _enableLocationComponent() async {
    if (_mapboxMap != null) {
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          puckBearingEnabled: true,
          showAccuracyRing: true,
        ),
      );
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _enableLocationComponent();
    _pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();

    await _initializeMarkers();
  }

  Future<void> _initializeMarkers() async {
    if (_pointAnnotationManager == null) return;

    await _pointAnnotationManager?.deleteAll();
  }

  Future<void> _addMarker(Map<String, dynamic> drop) async {
    if (_pointAnnotationManager == null) return;

    final String markerPath = _getMarkerAssetPath(drop['rarity']);
    final ByteData bytes = await rootBundle.load(markerPath);
    final Uint8List list = bytes.buffer.asUint8List();

    final options = PointAnnotationOptions(
      geometry: drop['position'],
      image: list,
      iconSize: 2.5,
      iconOffset: [0, 0],
      symbolSortKey: 1,
    );

    await _pointAnnotationManager?.create(options);
  }

  String _getMarkerAssetPath(DropRarity rarity) {
    switch (rarity) {
      case DropRarity.common:
        return 'assets/markers/common.png';
      case DropRarity.uncommon:
        return 'assets/markers/uncommon.png';
      case DropRarity.rare:
        return 'assets/markers/rare.png';
      case DropRarity.epic:
        return 'assets/markers/epic.png';
      case DropRarity.legendary:
        return 'assets/markers/legendary.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          _buildTopBar(),
          _buildARButton(),
          _buildEventBanner(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: MapboxConfig.styleUrl,
      onMapCreated: _onMapCreated,
    );
  }

  void _onMarkerTapped(Map<String, dynamic> drop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DropModal(
        rarity: drop['rarity'],
        dropName: drop['name'],
        onCollect: () {
          Navigator.pop(context);
          setState(() {
            drop['collected'] = true;
            _initializeMarkers(); // Refresh markers to update collected state
          });
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFEF4444),
                  Color(0xFF3B82F6),
                  Color(0xFFEFB344),
                ],
              ).createShader(bounds),
              child: const Text(
                'PITDECK',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.military_tech,
                        color: Color(0xFF3B82F6),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Consumer<UserProvider>(
                        builder: (context, userProvider, _) => Text(
                          'LVL ${userProvider.user?.level ?? 1}',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Consumer<UserProvider>(
                  builder: (context, auth, _) => Text(
                    auth.user?.name ?? 'Guest',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARButton() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.view_in_ar, color: Colors.white),
      ),
    );
  }

  Widget _buildDropCounter() {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.catching_pokemon, color: Color(0xFF3B82F6), size: 20),
            SizedBox(width: 8),
            Text(
              '3/10 Drops',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    return Positioned(
      top: 160,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.campaign, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Special Event: Double Drops Weekend!',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A1A),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.map, 'Map', true),
              _buildNavItem(Icons.card_membership, 'Collection', false),
              _buildNavItem(Icons.store, 'Market', false),
              _buildNavItem(Icons.person, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          final int index = label == 'Collection'
              ? 1
              : label == 'Market'
                  ? 2
                  : label == 'Profile'
                      ? 3
                      : 0;
          final navProvider =
              Provider.of<NavigationProvider>(context, listen: false);

          navProvider.changePage(index);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey,
                fontSize: 12,
                fontFamily: 'Orbitron',
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Position? {
  // ignore: recursive_getters
  get longitude => this?.longitude ?? 0;
  get latitude => this?.latitude ?? 0;
}
