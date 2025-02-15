import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'dart:async';
import 'package:pitdeck/config/mapbox_config.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import 'package:pitdeck/services/cache_service.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pitdeck/models/drop.dart';
import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pitdeck/components/control_center.dart';
import 'package:pitdeck/screens/widgets/main/topbar_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pitdeck/screens/daily_login_rewards.dart';
import 'package:pitdeck/services/daily_reward_service.dart';
import 'package:lottie/lottie.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  static final Map<String, DropModel> _cachedDrops = {};
  final CacheService _cacheService = CacheService();
  bool _isInitialLoad = true;
  bool _isDropModalOpen = false;

  MapboxMap? _mapboxMap;
  MarkerManager? _markerManager;
  geo.Position? _userLocation;
  Timer? _locationTimer;
  final bool _isLoading = false;
  bool _isLoadingLocation = true;
  IO.Socket? _socket;
  Timer? _socketReconnectTimer;
  bool _isSocketConnecting = false;
  final _retryDelays = [2, 5, 10, 30];

  int _retryAttempt = 0;

  final baseUrl = 'https://api.pitdeck.app/api';

  StreamSubscription<geo.Position>? _locationStreamSubscription;

  bool _hasUnclaimedReward = false;
  Map<String, dynamic>? _rewardStatus;

  @override
  @override
  void initState() {
    super.initState();
    _loadCachedState();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
      _initializeUserSocket();
      _checkDailyReward();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _socketReconnectTimer?.cancel();
    _locationStreamSubscription?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _loadCachedState() async {
    final cachedDrops = await _cacheService.getCachedDrops();
    final isInitialLoad = await _cacheService.getInitialLoad();

    setState(() {
      _cachedDrops.clear();
      _cachedDrops.addAll(cachedDrops);
      _isInitialLoad = isInitialLoad;
    });
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
      final auth = Provider.of<UserProvider>(context, listen: false);
      final lastLocation = auth.user?.lastLocation;

      if (lastLocation != null) {
        await _mapboxMap?.setCamera(
          CameraOptions(
            center: Point(
              coordinates:
                  Position(lastLocation.longitude, lastLocation.latitude),
            ),
            zoom: 15.0,
          ),
        );
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high);
      if (!mounted) return;

      setState(() {
        _userLocation = position;
        _isLoadingLocation = false;
      });

      _socket?.emit('location:update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      await _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _initializeUserSocket() async {
    final auth = Provider.of<UserProvider>(context, listen: false);
    await auth.connectUserSocket();
  }

  Future<void> _initializeSocket() async {
    if (_isSocketConnecting) return;
    _isSocketConnecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<UserProvider>(context, listen: false);
      final token = auth.user?.token;

      if (token == null) {
        print('Socket error: No auth token');
        return;
      }

      try {
        _socket = IO.io(
          'https://api.pitdeck.app/drops',
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setExtraHeaders({'Authorization': 'Bearer $token'})
              .enableAutoConnect()
              .build(),
        );

        _setupSocketListeners();
        _socket?.connect();
        print('Socket attempting connection...');
      } catch (e) {
        print('Socket init error: $e');
        _scheduleReconnect();
      }
    });
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('Socket connected');
      _isSocketConnecting = false;
      _retryAttempt = 0;
      _socketReconnectTimer?.cancel();
    });

    _socket?.onDisconnect((_) {
      print('Socket disconnected');
      _scheduleReconnect();
    });

    _socket?.on('drops:nearby', (data) {
      if (data != null) {
        try {
          final drops =
              (data as List).map((d) => DropModel.fromJson(d)).toList();
          _updateDrops(drops);
        } catch (e) {
          print('Error parsing drops: $e');
        }
      }
    });

    _socket?.onError((error) => print('Socket error: $error'));
    _socket?.onConnectError((error) => print('Connect error: $error'));
  }

  void _scheduleReconnect() {
    if (_socketReconnectTimer?.isActive ?? false) return;
    if (_retryAttempt >= _retryDelays.length) return;

    final delay = _retryDelays[_retryAttempt];
    print('Reconnecting in ${delay}s');

    _socketReconnectTimer = Timer(Duration(seconds: delay), () {
      _retryAttempt++;
      _isSocketConnecting = false;
      _initializeSocket();
    });
  }

  Future<void> _updateDrops(List<DropModel> drops) async {
    if (!mounted) return;
    try {
      for (var drop in drops) {
        _cachedDrops[drop.id.toString()] = drop;
      }

      if (_isInitialLoad) {
        await _markerManager?.clearAllMarkers();
        for (var drop in _cachedDrops.values) {
          await _markerManager?.addDropMarker(drop);
        }
        _isInitialLoad = false;
        await _cacheService.setInitialLoad(false);
      } else {
        final List<String> newDropIds =
            drops.map((drop) => drop.id.toString()).toList();
        final List<String> currentDropIds =
            _markerManager?.getCurrentDropIds() ?? [];

        final Set<String> newDropSet = Set.from(newDropIds);
        final Set<String> currentDropSet = Set.from(currentDropIds);

        final dropsToRemove = currentDropSet.difference(newDropSet);
        final dropsToAdd = newDropSet.difference(currentDropSet);

        // Remove old markers
        for (var dropId in dropsToRemove) {
          await _markerManager?.removeMarker(dropId);
          _cachedDrops.remove(dropId);
        }

        // Add new markers
        for (var dropId in dropsToAdd) {
          final drop = _cachedDrops[dropId];
          if (drop != null) {
            await _markerManager?.addDropMarker(drop);
          }
        }
      }
    } catch (e) {
      print('Error updating drops: $e');
    }
  }


  Future<void> _startLocationUpdates() async {
    _locationStreamSubscription?.cancel();

    const geo.LocationSettings locationSettings = geo.LocationSettings(
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationStreamSubscription = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((geo.Position position) {
      if (mounted) {
        setState(() {
      _userLocation = position;
      _isLoadingLocation = false;
      });
      _socket?.emit('location:update', {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });

        _mapboxMap?.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 15.0,
          ),
        );
      }
    }, onError: (error) {
      print('Error getting location stream: $error');
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
    await _getCurrentLocation();
  }

  void _showDropModal(DropModel drop) async {
    final newDrop = _markerManager?.getDropForId(drop.id);
    final distance = await _calculateDistance(newDrop!);
    final auth = Provider.of<UserProvider>(context, listen: false);
    final isPremium = auth.user?.isPremium ?? false;
    final maxRange = isPremium ? 500.0 : 100.0;
    final isInRange = distance <= maxRange;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.8, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF040412),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getRarityColor(newDrop.rarity).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColor(newDrop.rarity).withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropHeader(newDrop, distance, isInRange, isPremium),
                    _buildDropContent(newDrop, isInRange),
                    _buildDropFooter(newDrop, isInRange),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropHeader(
      DropModel drop, double distance, bool isInRange, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRarityColor(drop.rarity).withOpacity(0.2),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRarityColor(drop.rarity).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getRarityColor(drop.rarity).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: _getRarityColor(drop.rarity),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      drop.rarity.toString().split('.').last,
                      style: TextStyle(
                        color: _getRarityColor(drop.rarity),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInRange
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isInRange
                        ? const Color(0xFF10B981).withOpacity(0.3)
                        : const Color(0xFFEF4444).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInRange ? Icons.near_me : Icons.location_off,
                      color: isInRange
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${distance.toStringAsFixed(0)}m',
                      style: TextStyle(
                        color: isInRange
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isPremium && distance > 100 && distance <= 500) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFB800).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB800).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFFFB800),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Upgrade to Premium to Reach',
                    style: TextStyle(
                      color: Color(0xFFFFB800),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropContent(DropModel drop, bool isInRange) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRarityColor(drop.rarity).withOpacity(0.05),
            Colors.transparent,
            _getRarityColor(drop.rarity).withOpacity(0.05),
          ],
        ),
        border: Border.symmetric(
          horizontal: BorderSide(
            color: _getRarityColor(drop.rarity).withOpacity(0.1),
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getRarityColor(drop.rarity).withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Icon(
            Icons.card_giftcard,
            color: _getRarityColor(drop.rarity).withOpacity(0.4),
            size: 80,
          ),
          if (!isInRange)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                Icons.lock,
                color: _getRarityColor(drop.rarity),
                size: 40,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropFooter(DropModel drop, bool isInRange) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: isInRange ? () => _openDrop(drop) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isInRange
                  ? _getRarityColor(drop.rarity)
                  : const Color(0xFF1A1A2E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<double> _calculateDistance(DropModel drop) async {
    if (_userLocation == null) return double.infinity;
    // Get fresh location
    final location = await geo.Geolocator.getCurrentPosition();
    return geo.Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
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
      final location = await geo.Geolocator.getCurrentPosition();
      final response = await http.post(
        Uri.parse('$baseUrl/drops/claim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'dropId': drop.id,
          'latitude': location.latitude,
          'longitude': location.longitude,
        }),
      );
      if (!mounted) return;

      if (response.statusCode == 201) {
        final rewards = json.decode(response.body);
        Navigator.pop(context);
        _cachedDrops.remove(drop.id);
        _markerManager?.removeMarker(drop.id);
        setState(() {
          _isDropModalOpen = false;
        });
        _showRewardsDialog(rewards, drop.rarity);
      } else if (response.statusCode == 403) {
        setState(() {
          _isDropModalOpen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far away from this drop')),
        );
      } else if (response.statusCode == 500) {
        setState(() {
          _isDropModalOpen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far away from this drop')),
        );
      } else {
        setState(() {
          _isDropModalOpen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error claiming drop')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDropModalOpen = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming drop: $e')),
      );
    }
  }

  void _showRewardsDialog(Map<String, dynamic> rewards, DropRarity rarity) {
    final List<dynamic> rewardsList = rewards['rewards'];
    final rarityColor = _getRarityColor(rarity);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0, end: 1),
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
        builder: (context, value, child) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15 * value, sigmaY: 15 * value),
          child: Dialog.fullscreen(
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background animation
                Lottie.network(
                  'https://lottie.host/c7e44f6d-b2ed-4991-97e9-361dd205ed5e/x2YDkwPwFB.lottie',
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  fit: BoxFit.cover,
                ),
                // Main content
                Center(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0, end: 1),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) => Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: rarityColor.withOpacity(0.3 * value),
                                blurRadius: 50,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Card container
                        Transform.scale(
                          scale: value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFF040412),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: rarityColor.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: rarityColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background pattern
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: GridPainter(
                                      color: rarityColor.withOpacity(0.1),
                                      gridSize: 10,
                                    ),
                                  ),
                                ),
                                // Icon
                                Icon(
                                  Icons.card_giftcard,
                                  size: 80,
                                  color: rarityColor.withOpacity(0.8),
                                ),
                                // Animated border
                                AnimatedBuilder(
                                  animation: AlwaysStoppedAnimation(value),
                                  builder: (context, child) {
                                    return CustomPaint(
                                      size: const Size(200, 200),
                                      painter: BorderPainter(
                                        progress: value,
                                        color: rarityColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.0,
            colors: [
              _getRarityColor(rarity).withOpacity(0.15),
              const Color(0xFF040412),
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
                            const SizedBox(height: 70),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  _getRarityColor(rarity),
                                  _getRarityColor(rarity).withOpacity(0.7),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'New Drop Unlocked!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Orbitron',
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _getRarityColor(rarity).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
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
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _getRarityColor(rarity)
                                              .withOpacity(0.2),
                                          _getRarityColor(rarity)
                                              .withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getRarityColor(rarity)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '#${card['serialNumber']}',
                                      style: TextStyle(
                                        color: _getRarityColor(rarity),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getRarityColor(rarity)
                                        .withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  card['imageUrl'],
                                  fit: BoxFit.cover,
                                  height: 400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color:
                                      _getRarityColor(rarity).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildCardDetail(
                                    Icons.calendar_today,
                                    'Year',
                                    card['year'].toString(),
                                    color: _getRarityColor(rarity),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  _buildCardDetail(
                                    Icons.category,
                                    'Series',
                                    card['series'],
                                    color: _getRarityColor(rarity),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  _buildCardDetail(
                                    Icons.auto_awesome,
                                    'Rarity',
                                    card['rarity'],
                                    color: _getRarityColor(rarity),
                                  ),
                                ],
                              ),
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
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getRarityColor(rarity),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add to Collection',
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
                      _buildActionButton(
                        Icons.swap_horiz,
                        'Trade',
                        () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 40),
                      _buildActionButton(
                        Icons.sell,
                        'Sell',
                        () => Navigator.pop(context),
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetail(IconData icon, String label, String value,
      {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontFamily: 'Orbitron',
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          if (_isLoadingLocation == true) ...[
            Scaffold(
              backgroundColor: const Color(0xFF040412),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_searching,
                          color: Color(0xFF3B82F6),
                          size: 60,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Getting your location...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please enable location services to continue',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const TopBarWidget(),
          _buildControlCenter(),
          _buildRefreshButton(),
          _buildEventBanner(),
          Positioned(
            left: 16,
            bottom: 25,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: IconButton(
                    onPressed: _showDailyReward,
                    icon: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                if (_hasUnclaimedReward)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return MapWidget(
      key: const ValueKey("mapWidget"),
      styleUri: MapboxConfig.styleUrl,
      onMapCreated: _onMapCreated,
    );
  }

  Widget _buildRefreshButton() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.5),
                builder: (context) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Center(
                    child: SizedBox(
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
                                      const Color(0xFF3B82F6).withOpacity(0.1),
                                      const Color(0xFF3B82F6).withOpacity(0.5),
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

              Navigator.of(context).pop();
            },
            backgroundColor: const Color(0xFF1A1A2E),
            label: const Text(
              'Refresh this area',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEventBanner() {
    return Positioned(
      top: 125, // Position above Mapbox attribution
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

  Widget _buildControlCenter() {
    return Positioned(
      right: 16,
      bottom: 25,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'controlCenter',
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
                    child: const ControlCenter(),
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF1A1A2E),
            child:
                const Icon(Icons.dashboard_customize, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }

  Future<void> _checkDailyReward() async {
    try {
      final token =
          Provider.of<UserProvider>(context, listen: false).user?.token;
      if (token == null) return;
      final rewardService =
          Provider.of<DailyRewardService>(context, listen: false);
      final status = await rewardService.getDailyRewardStatus(token);
      if (mounted) {
        setState(() {
          _rewardStatus = status;
          _hasUnclaimedReward = status['canClaim'];
        });
      }
    } catch (e) {
      showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: Text('Error checking daily reward: $e'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ));
      print('Error checking daily reward: $e');
    }
  }

  void _showDailyReward() {
    final token = Provider.of<UserProvider>(context, listen: false).user?.token;
    if (token != null) {
      showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          return PopScope(
            canPop: true,
            child: DailyLoginRewardsPopup(token: token),
          );
        },
      );
    }
  }
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
    return dropId != null ? _markerDrops[dropId] : null;
  }

  Future<void> addDropMarker(DropModel dropData) async {
    try {
      final drop = dropData;
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

// Add this custom clipper for hexagonal shape
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;

    path.moveTo(width * 0.5, 0);
    path.lineTo(width, height * 0.25);
    path.lineTo(width, height * 0.75);
    path.lineTo(width * 0.5, height);
    path.lineTo(0, height * 0.75);
    path.lineTo(0, height * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Grid pattern painter
class GridPainter extends CustomPainter {
  final Color color;
  final double gridSize;

  GridPainter({required this.color, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated border painter
class BorderPainter extends CustomPainter {
  final double progress;
  final Color color;

  BorderPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path()
      ..moveTo(0, size.height * progress)
      ..lineTo(0, 0)
      ..lineTo(size.width * progress, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
