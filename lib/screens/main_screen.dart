import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'dart:async';
import 'package:pitdeck/config/mapbox_config.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pitdeck/models/drop.dart';
import 'dart:math';

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
  MarkerManager? _markerManager;
  geo.Position? _userLocation;
  Timer? _locationTimer;
  CircleAnnotationManager? _circleAnnotationManager;
  geo.Position? _lastLocation;
  final double _minDistanceChange = 10.0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
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
      _startLocationUpdates();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    try {
      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high);
      if (!mounted) return;

      setState(() {
        _userLocation = position;
      });

      await _updateUserLocation(position);

      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 12.0,
        ),
        MapAnimationOptions(duration: 2000),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _updateUserLocation(geo.Position position) async {
    if (_markerManager == null) {
      print('Marker manager not ready');
      return;
    }

    // Skip update if location hasn't changed significantly
    if (_lastLocation != null &&
        geo.Geolocator.distanceBetween(
              _lastLocation!.latitude,
              _lastLocation!.longitude,
              position.latitude,
              position.longitude,
            ) <
            _minDistanceChange) {
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = userProvider.user?.token;

      if (token == null) return;

      await _updateRangeCircle(position);

      final response = await http.post(
        Uri.parse('https://api.pitdeck.app/api/users/location/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['drops'] != null) {
          await _markerManager?.clearAllMarkers();
          for (var drop in responseData['drops']) {
            print('Adding marker for drop: ${drop.toString()}');
            await _markerManager?.addDropMarker(drop);
          }
          _lastLocation = position;
        }
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _updateRangeCircle(geo.Position position) async {
    await _circleAnnotationManager?.deleteAll();

    // Get current zoom level
    final zoom =
        await _mapboxMap?.getCameraState().then((state) => state.zoom) ?? 15.0;

    final radiusScale = pow(2, zoom - 15).toDouble();
    final radiusPixels = 100.0 / radiusScale;

    final options = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(position.longitude, position.latitude),
      ),
      circleRadius: 20,
      circleColor: Colors.blue.value,
      circleOpacity: 0.2,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.blue.value,
      circleStrokeOpacity: 0.5,
    );

    await _circleAnnotationManager?.create(options);
  }

  Future<void> _startLocationUpdates() async {
    // Cancel any existing timer
    _locationTimer?.cancel();

    // Get initial location immediately
    await _getCurrentLocation();

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
    final pointAnnotationManager =
        await mapboxMap.annotations.createPointAnnotationManager();
    _markerManager = MarkerManager(pointAnnotationManager, _showDropModal);
    _circleAnnotationManager =
        await mapboxMap.annotations.createCircleAnnotationManager();
    if (_userLocation != null) {
      await _updateUserLocation(_userLocation!);
    } else {
      await _getCurrentLocation();
    }
  }

  void _showDropModal(DropModel drop) {
    final distance = _calculateDistance(drop);
    final isInRange = distance <= 100; // 100 meters range

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getRarityColor(drop.rarity).withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getRarityColor(drop.rarity).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRarityColor(drop.rarity).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      drop.rarity.toString().split('.').last,
                      style: TextStyle(
                        color: _getRarityColor(drop.rarity),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${distance.toStringAsFixed(0)}m away',
                    style: TextStyle(
                      color: isInRange ? Colors.green : Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getRarityColor(drop.rarity).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRarityColor(drop.rarity).withOpacity(0.1),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.help_outline,
                    size: 80,
                    color: _getRarityColor(drop.rarity).withOpacity(0.3),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isInRange ? () => _openDrop(drop) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isInRange
                            ? _getRarityColor(drop.rarity)
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isInRange ? Icons.lock_open : Icons.lock,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isInRange ? 'Open Drop' : 'Too Far Away',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDistance(DropModel drop) {
    if (_userLocation == null) return double.infinity;

    return geo.Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      drop.latitude,
      drop.longitude,
    ).roundToDouble(); // This function already returns meters
  }

  Future<void> _openDrop(DropModel drop) async {
    print('Opening drop:');
    print('- ID: ${drop.id}');
    print('- Type: ${drop.type}');
    print('- Rarity: ${drop.rarity}');
    print('- Distance: ${_calculateDistance(drop)}m');
    print('- Rewards: ${drop.rewards.length}');
    for (var reward in drop.rewards) {
      print(
          '  * ${reward.type}: ${reward.amount} (ID: ${reward.cardId ?? "N/A"})');
    }
    print('- Expires: ${drop.expiresAt}');

    // TODO: Implement drop opening logic
    Navigator.pop(context);
  }

  Color _getRarityColor(DropRarity rarity) {
    switch (rarity) {
      case DropRarity.COMMON:
        return Colors.grey;
      case DropRarity.UNCOMMON:
        return Colors.green;
      case DropRarity.RARE:
        return Colors.blue;
      case DropRarity.EPIC:
        return Colors.purple;
      case DropRarity.LEGENDARY:
        return Colors.orange;
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
      bottom: 30, // Position above Mapbox attribution
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

class MarkerManager {
  final Map<String, DropModel> _markerDrops = {};
  final Map<String, PointAnnotation> _dropMarkers = {};
  final PointAnnotationManager _pointAnnotationManager;
  final Function(DropModel) _onDropTap;

  MarkerManager(this._pointAnnotationManager, this._onDropTap);

  DropModel? getDropForAnnotation(String annotationId) {
    print('Getting drop for annotation: $annotationId');
    print('Available markers: ${_markerDrops.keys.join(', ')}');
    final drop = _markerDrops[annotationId];
    print('Found drop: ${drop?.toString()}');
    return drop;
  }

  Future<void> addDropMarker(Map<String, dynamic> dropData) async {
    try {
      final drop = DropModel.fromJson(dropData);
      final String markerPath = _getMarkerAssetPath(drop.rarity);

      final ByteData bytes = await rootBundle.load(markerPath);
      final Uint8List list = bytes.buffer.asUint8List();

      final point = Point(coordinates: Position(drop.longitude, drop.latitude));

      final options = PointAnnotationOptions(
        geometry: point,
        image: list,
        iconSize: 2.5,
        iconOffset: [0, 0],
        symbolSortKey: 1,
      );

      final annotation = await _pointAnnotationManager.create(options);
      _markerDrops[annotation.id] = drop;
      _dropMarkers[drop.id] = annotation;

      _pointAnnotationManager.addOnPointAnnotationClickListener(
        PointAnnotationClickListener(drop, _onDropTap, this),
      );
    } catch (e) {
      print('Error creating marker: $e');
    }
  }

  Future<void> clearAllMarkers() async {
    await _pointAnnotationManager.deleteAll();
    _markerDrops.clear();
    _dropMarkers.clear();
  }

  String _getMarkerAssetPath(DropRarity rarity) {
    switch (rarity) {
      case DropRarity.COMMON:
        return 'assets/markers/common.png';
      case DropRarity.UNCOMMON:
        return 'assets/markers/uncommon.png';
      case DropRarity.RARE:
        return 'assets/markers/rare.png';
      case DropRarity.EPIC:
        return 'assets/markers/epic.png';
      case DropRarity.LEGENDARY:
        return 'assets/markers/legendary.png';
    }
  }
}

class PointAnnotationClickListener extends OnPointAnnotationClickListener {
  final DropModel drop;
  final Function(DropModel) onTap;
  final MarkerManager markerManager;

  PointAnnotationClickListener(this.drop, this.onTap, this.markerManager);

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onTap(drop);
    return true;
  }
}
