import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'dart:async';
import 'package:pitdeck/config/mapbox_config.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:pitdeck/screens/collection_screen.dart';
import 'package:pitdeck/screens/market_screen.dart';
import 'package:pitdeck/screens/packs_screen.dart';
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
  bool _isLoading = false;
  final baseUrl = 'https://api.pitdeck.app/api';
  final developerUrl = 'http://192.168.1.105:3000/api'; // TODO: Remove this
  geo.Position? _lastLocation;

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

      if (_lastLocation == null) {
        await _getNearbyDrops(position);
      }

      await _updateRangeCircle(position);

      await _mapboxMap?.flyTo(
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

  Future<void> _getNearbyDrops(geo.Position position) async {
    if (_markerManager == null) {
      print('Marker manager not ready');
      return;
    }

    try {
      final auth = Provider.of<UserProvider>(context, listen: false);
      final response = await http.get(
        Uri.parse(
            '$baseUrl/drops?lat=${position.latitude}&lng=${position.longitude}&radius=11000'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.user?.token}',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['drops'] != null) {
          final List<dynamic> newDrops = responseData['drops'];
          final List<String> newDropIds =
              newDrops.map<String>((drop) => drop['id'].toString()).toList();
          final List<String> currentDropIds =
              _markerManager!.getCurrentDropIds();

          final Set<String> newDropSet = Set.from(newDropIds);
          final Set<String> currentDropSet = Set.from(currentDropIds);

          final dropsToRemove = currentDropSet.difference(newDropSet);
          final dropsToAdd = newDropSet.difference(currentDropSet);

          for (var dropId in dropsToRemove) {
            await _markerManager?.removeMarker(dropId);
          }

          for (var drop in newDrops) {
            if (dropsToAdd.contains(drop['id'].toString())) {
              await _markerManager?.addDropMarker(drop);
            }
          }
        }
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    return true;
  }

  Future<void> _updateRangeCircle(geo.Position position) async {
    await _circleAnnotationManager?.deleteAll();

    final auth = Provider.of<UserProvider>(context, listen: false);
    final isPremium = auth.user?.isPremium ?? false;

    final zoom =
        await _mapboxMap?.getCameraState().then((state) => state.zoom) ?? 15.0;

    final options = CircleAnnotationOptions(
      geometry: Point(
        coordinates: Position(position.longitude, position.latitude),
      ),
      circleRadius: isPremium ? 5000 / zoom : 1000 / zoom,
      circleColor: Colors.blue.value,
      circleOpacity: 0.2,
      circleStrokeWidth: 2.0,
      circleStrokeColor: Colors.blue.value,
      circleStrokeOpacity: 0.5,
      circleBlur: 1.0,
    );

    await _circleAnnotationManager?.create(options);
  }

  Future<void> _startLocationUpdates() async {
    _locationTimer?.cancel();
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
    // _circleAnnotationManager =
    //     await mapboxMap.annotations.createCircleAnnotationManager();
    if (_userLocation != null) {
      await _getNearbyDrops(_userLocation!);
    } else {
      await _getCurrentLocation();
    }
  }

  void _showDropModal(DropModel drop) {
    final newDrop = _markerManager?.getDropForId(drop.id);
    final distance = _calculateDistance(newDrop!);
    final auth = Provider.of<UserProvider>(context, listen: false);
    final isPremium = auth.user?.isPremium ?? false;
    final maxRange = isPremium ? 500.0 : 100.0;
    final isInRange = distance <= maxRange;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 1.0, end: 0.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, 50 * value),
            child: Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getRarityColor(newDrop.rarity).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getRarityColor(newDrop.rarity).withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) => Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRarityColor(newDrop.rarity)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  newDrop.rarity.toString().split('.').last,
                                  style: TextStyle(
                                    color: _getRarityColor(newDrop.rarity),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${distance.toStringAsFixed(0)}m away',
                                style: TextStyle(
                                  color: isInRange ? Colors.green : Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isPremium &&
                                  distance > 100 &&
                                  distance <= 1500) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Get Premium to reach this drop!',
                                  style: TextStyle(
                                    color: Colors.amber.shade300,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Container(
                          height: 200,
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _getRarityColor(newDrop.rarity)
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRarityColor(newDrop.rarity)
                                  .withOpacity(0.1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: ElevatedButton(
                            onPressed:
                                isInRange ? () => _openDrop(newDrop) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isInRange
                                  ? _getRarityColor(newDrop.rarity)
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    ).roundToDouble();
  }

  Future<void> _openDrop(DropModel drop) async {
    if (!mounted) return;

    final auth = Provider.of<UserProvider>(context, listen: false);
    final token = auth.user?.token;

    try {
      if (_userLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get your location')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/drops/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'dropId': drop.id,
          'latitude': _userLocation!.latitude,
          'longitude': _userLocation!.longitude,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final rewards = json.decode(response.body);
        Navigator.pop(context);
        _markerManager?.removeMarker(drop.id);
        _showRewardsDialog(rewards, drop.rarity);
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far away from this drop')),
        );
      
      } else {
        print(response.body);
        throw Exception('Failed to claim drop');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming drop: $e')),
      );
    }
  }

  void _showRewardsDialog(Map<String, dynamic> rewards, DropRarity rarity) {
    final List<dynamic> rewardsList = rewards['rewards'] ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8 * value, sigmaY: 8 * value),
          child: Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A2E),
                    _getRarityColor(rarity).withOpacity(0.1),
                    const Color(0xFF1A1A2E),
                  ],
                ),
              ),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween(begin: 0, end: 1),
                  builder: (context, value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer rotating circles
                        Transform.rotate(
                          angle: value * 4 * pi,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  _getRarityColor(rarity).withOpacity(0),
                                  _getRarityColor(rarity),
                                  _getRarityColor(rarity).withOpacity(0),
                                ],
                                stops: [0, value, 1],
                              ),
                            ),
                          ),
                        ),
                        // Inner pulsing circle
                        Transform.scale(
                          scale: 1 + (0.2 * sin(value * 3 * pi)),
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A2E),
                              border: Border.all(
                                color: _getRarityColor(rarity),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      _getRarityColor(rarity).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: value * 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Center icon
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 1500),
                          tween: Tween(begin: 0, end: 1),
                          curve: Curves.elasticOut,
                          builder: (context, scaleValue, child) =>
                              Transform.scale(
                            scale: scaleValue,
                            child: Icon(
                              Icons.card_giftcard,
                              size: 50 + (20 * sin(value * 6 * pi)),
                              color: _getRarityColor(rarity),
                            ),
                          ),
                        ),
                        // Particles
                        ...List.generate(12, (index) {
                          final angle = (index / 12) * 2 * pi;
                          final radius = 150 * value;
                          return Positioned(
                            left: cos(angle) * radius + 100,
                            top: sin(angle) * radius + 100,
                            child: Transform.scale(
                              scale: (1 - value) * 2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getRarityColor(rarity),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                  onEnd: () {
                    Navigator.of(context).pushReplacement(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 500),
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return FadeTransition(
                            opacity: animation,
                            child: _buildFinalReward(rewardsList, rarity),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalReward(List<dynamic> rewardsList, DropRarity rarity) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E),
              _getRarityColor(rarity).withOpacity(0.1),
              const Color(0xFF1A1A2E),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: rewardsList.map((reward) {
                    if (reward['type'] == 'CARD') {
                      final card = reward['card'];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: _getRarityColor(rarity),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'New Drop Unlocked!',
                                  style: TextStyle(
                                    color: _getRarityColor(rarity),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Text(
                              card['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _getRarityColor(rarity).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color:
                                      _getRarityColor(rarity).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '#${card['serialNumber']}',
                                style: TextStyle(
                                  color: _getRarityColor(rarity),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Container(
                              height: 400,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getRarityColor(rarity)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  card['imageUrl'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCardDetail(
                                  Icons.calendar_today,
                                  'Year',
                                  card['year'].toString(),
                                ),
                                const SizedBox(width: 12),
                                _buildCardDetail(
                                  Icons.category,
                                  'Series',
                                  card['series'],
                                ),
                                const SizedBox(width: 12),
                                _buildCardDetail(
                                  Icons.auto_awesome,
                                  'Rarity',
                                  card['rarity'],
                                  color: _getRarityColor(rarity),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to trade creation
                        },
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 40),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Navigate to market listing
                        },
                        icon: const Icon(
                          Icons.sell,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardDetail(IconData icon, String label, String value,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ?? Colors.white.withOpacity(0.7),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
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

  Color _getRarityColorString(String rarity) {
    switch (rarity) {
      case 'COMMON':
        return Colors.grey;
      case 'UNCOMMON':
        return Colors.green;
      case 'RARE':
        return Colors.blue;
      case 'EPIC':
        return Colors.purple;
      case 'LEGENDARY':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _testDropAnimation() {
    final mockRewards = {
      "rewards": [
        {
          "type": "CARD",
          "card": {
            "id": "test123",
            "name": "Lewis Hamilton",
            "imageUrl": "https://picsum.photos/400/300",
            "serialNumber": "123/999",
            "rarity": "LEGENDARY",
            "series": "2024 Season",
            "year": "2024"
          }
        }
      ]
    };

    _showRewardsDialog(mockRewards, DropRarity.LEGENDARY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          _buildTopBar(),
          _buildControlCenter(),
          _buildRefreshButton(),
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

  Widget _buildControlCenter() {
    return Positioned(
      right: 16,
      bottom: 100,
      child: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 500),
              tween: Tween(begin: 1.0, end: 0.0),
              curve: Curves.easeOutExpo,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 100 * value),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.93,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0A0A1A).withOpacity(0.98),
                          const Color(0xFF1A1A2E).withOpacity(0.98),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF3B82F6),
                              Color(0xFF60A5FA),
                              Color(0xFF3B82F6),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Control Center',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.count(
                            shrinkWrap: true,
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            children: [
                              _buildControlTile(
                                icon: Icons.card_giftcard,
                                label: 'Packs',
                                description: 'Open new card packs',
                                gradient: const [
                                  Color(0xFFEF4444),
                                  Color(0xFFF97316)
                                ],
                                glowColor: const Color(0xFFEF4444),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PacksScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildControlTile(
                                icon: Icons.star_rounded,
                                label: 'Quests',
                                description: 'Complete challenges',
                                gradient: const [
                                  Color(0xFFFFB800),
                                  Color(0xFFFF9500)
                                ],
                                glowColor: const Color(0xFFFFB800),
                                onTap: () {
                                  // TODO: Navigate to quests
                                },
                              ),
                              _buildControlTile(
                                icon: Icons.flag_rounded,
                                label: 'Races',
                                description: 'Join competitions',
                                gradient: const [
                                  Color(0xFF10B981),
                                  Color(0xFF059669)
                                ],
                                glowColor: const Color(0xFF10B981),
                                onTap: () {
                                  // TODO: Navigate to races
                                },
                              ),
                              _buildControlTile(
                                icon: Icons.leaderboard_rounded,
                                label: 'Leaderboard',
                                description: 'View rankings',
                                gradient: const [
                                  Color(0xFF8B5CF6),
                                  Color(0xFF6D28D9)
                                ],
                                glowColor: const Color(0xFF8B5CF6),
                                onTap: () {
                                  // TODO: Navigate to leaderboard
                                },
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 32,
                          ),
                          child: Divider(
                            color: Color(0xFF2A2A3F),
                            thickness: 2,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF1A1A2E).withOpacity(0.5),
                                  const Color(0xFF2A2A3F).withOpacity(0.5),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [Colors.white, Color(0xFF60A5FA)],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Coming Soon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Stay tuned for exciting new features and content!',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.dashboard_customize, color: Color(0xFF3B82F6)),
      ),
    );
  }

  Widget _buildControlTile({
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradient,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.1),
              gradient[1].withOpacity(0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: gradient[0].withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Positioned(
      right: 16,
      bottom: 160,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () async {
              if (_userLocation != null) {
                // Show scanning animation
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black.withOpacity(0.5),
                  builder: (context) => BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating circle
                            TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: 0, end: 4 * 3.14159),
                              curve: Curves.linear,
                              builder: (context, value, child) =>
                                  Transform.rotate(
                                angle: value,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6)
                                          .withOpacity(0.5),
                                      width: 2,
                                    ),
                                    gradient: SweepGradient(
                                      colors: [
                                        const Color(0xFF3B82F6)
                                            .withOpacity(0.1),
                                        const Color(0xFF3B82F6)
                                            .withOpacity(0.5),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Inner scanning line
                            TweenAnimationBuilder<double>(
                              duration: const Duration(seconds: 2),
                              tween: Tween(begin: -1, end: 1),
                              curve: Curves.easeInOut,
                              builder: (context, value, child) =>
                                  Transform.translate(
                                offset: Offset(0, 100 * value),
                                child: Container(
                                  width: 150,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0),
                                        Colors.blue.withOpacity(0.8),
                                        Colors.blue.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Center dot
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF3B82F6),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

                // Perform the actual refresh
                await _getNearbyDrops(_userLocation!);
                _lastLocation = _userLocation;

                // Close the scanning animation
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            backgroundColor: const Color(0xFF1A1A2E),
            child: const Icon(Icons.refresh, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 16),
          /*FloatingActionButton(
            onPressed: _testDropAnimation,
            backgroundColor: const Color(0xFF1A1A2E),
            child: const Icon(Icons.play_arrow, color: Color(0xFF3B82F6)),
          ),*/
        ],
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
  final Map<String, String> _annotationToDropId = {};
  final PointAnnotationManager _pointAnnotationManager;
  final Function(DropModel) _onDropTap;

  MarkerManager(this._pointAnnotationManager, this._onDropTap);

  DropModel? getDropForId(String id) {
    return _markerDrops[id];
  }

  DropModel? getDropByAnnotationId(String annotationId) {
    final dropId = _annotationToDropId[annotationId];
    print('Drop ID: $dropId');
    return dropId != null ? _markerDrops[dropId] : null;
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
      _markerDrops[drop.id] = drop;
      _dropMarkers[drop.id] = annotation;
      _annotationToDropId[annotation.id] = drop.id;

      _pointAnnotationManager.addOnPointAnnotationClickListener(
        PointAnnotationClickListener(drop, _onDropTap, this),
      );
    } catch (e) {
      print('Error creating marker: $e');
    }
  }

  Future<void> removeMarker(String dropId) async {
    if (_dropMarkers.containsKey(dropId)) {
      await _pointAnnotationManager.delete(_dropMarkers[dropId]!);
      _dropMarkers.remove(dropId);
      _markerDrops.remove(dropId);
    }
  }

  Future<void> clearAllMarkers() async {
    await _pointAnnotationManager.deleteAll();
    _dropMarkers.clear();
    _markerDrops.clear();
    _annotationToDropId.clear();
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

  List<String> getCurrentDropIds() {
    return _markerDrops.keys.toList();
  }
}

class PointAnnotationClickListener extends OnPointAnnotationClickListener {
  final DropModel drop;
  final Function(DropModel) onTap;
  final MarkerManager markerManager;

  PointAnnotationClickListener(this.drop, this.onTap, this.markerManager);

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    final clickedDrop = markerManager.getDropByAnnotationId(annotation.id);
    if (clickedDrop != null) {
      onTap(clickedDrop);
    }
    return true;
  }
}
