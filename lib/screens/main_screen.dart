import 'dart:typed_data';
import 'dart:ui';

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
  IO.Socket? _socket;
  Timer? _socketReconnectTimer;
  bool _isSocketConnecting = false;
  final _retryDelays = [2, 5, 10, 30];

  int _retryAttempt = 0;

  final baseUrl = 'https://api.pitdeck.app/api';

  StreamSubscription<geo.Position>? _locationStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadCachedState();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSocket();
      _initializeUserSocket();
    });
    print('Current cached drops: ${_cachedDrops.length}');
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

      print('Initializing socket with token: ${token?.substring(0, 10)}...');

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


  void _showDropModal(DropModel drop) {
    if (_isDropModalOpen) return;
    setState(() {
      _isDropModalOpen = true;
    });
    final newDrop = _markerManager?.getDropForId(drop.id);
    final distance = _calculateDistance(newDrop!);
    final auth = Provider.of<UserProvider>(context, listen: false);
    final isPremium = auth.user?.isPremium ?? false;

    final maxRange = isPremium ? 500.0 : 100.0;
    final isInRange = distance <= maxRange;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getRarityColor(newDrop.rarity).withOpacity(0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColor(newDrop.rarity).withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getRarityColor(newDrop.rarity)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: _getRarityColor(newDrop.rarity),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      newDrop.rarity.toString().split('.').last,
                                      style: TextStyle(
                                        color: _getRarityColor(newDrop.rarity),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isInRange
                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                      : const Color(0xFFEF4444)
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isInRange
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.3)
                                        : const Color(0xFFEF4444)
                                            .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isInRange
                                          ? Icons.near_me
                                          : Icons.location_off,
                                      color: isInRange
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${distance.toStringAsFixed(0)}m away',
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
                              if (!isPremium &&
                                  distance > 100 &&
                                  distance <= 500) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(

                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB800)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFFFB800)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Color(0xFFFFB800),
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Get Premium to Reach',
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) => Transform.scale(
                        scale: value,
                        child: Container(
                          height: 280,
                          width: MediaQuery.of(context).size.width,
                          margin: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: _getRarityColor(newDrop.rarity)
                                .withOpacity(0.05),
                            border: Border(
                              top: BorderSide(
                                color: _getRarityColor(newDrop.rarity)
                                    .withOpacity(0.2),
                              ),
                              bottom: BorderSide(
                                color: _getRarityColor(newDrop.rarity)
                                    .withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.card_giftcard,
                                color: _getRarityColor(newDrop.rarity)
                                    .withOpacity(0.2),
                                size: 80,
                              ),
                              if (!isInRange)
                                Icon(
                                  Icons.lock,
                                  color: _getRarityColor(newDrop.rarity)
                                      .withOpacity(0.3),
                                  size: 40,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Transform.scale(
                          scale: value,
                          child: SizedBox(
                            width: double.infinity,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              child: ElevatedButton(
                                onPressed:
                                    isInRange ? () => _openDrop(newDrop) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isInRange
                                      ? _getRarityColor(newDrop.rarity)
                                      : const Color(0xFF2A2A3E),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        _cachedDrops.remove(drop.id);
        _markerManager?.removeMarker(drop.id);
        _showRewardsDialog(rewards, drop.rarity);
      } else if (response.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far away from this drop')),
        );
      } else if (response.statusCode == 500) {
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are too far away from this drop')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error claiming drop')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error claiming drop: $e')),
      );
    }
  }

  void _showRewardsDialog(Map<String, dynamic> rewards, DropRarity rarity) {
    final List<dynamic> rewardsList = rewards['rewards'];

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
                  builder: (context, value, child) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow
                      Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getRarityColor(rarity).withOpacity(0.3),
                              blurRadius: 50 * value,
                              spreadRadius: 20 * value,
                            ),
                          ],
                        ),
                      ),
                      // Rotating border
                      Transform.rotate(
                        angle: value * 2 * pi,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getRarityColor(rarity).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      // Main container
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A2E),
                          border: Border.all(
                            color: _getRarityColor(rarity),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 1000),
                            tween: Tween(begin: 0, end: 1),
                            curve: Curves.easeOutBack,
                            builder: (context, scaleValue, child) =>
                                Transform.scale(
                              scale: scaleValue,
                              child: Icon(
                                Icons.card_giftcard,
                                size: 60,
                                color: _getRarityColor(rarity),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Particles
                      ...List.generate(8, (index) {
                        final angle = (index / 8) * 2 * pi;
                        final radius = 120 * value;
                        return Positioned(
                          left: cos(angle) * radius + 150,
                          top: sin(angle) * radius + 150,
                          child: FadeTransition(
                            opacity: AlwaysStoppedAnimation(1 - value),
                            child: Container(
                              width: 4,
                              height: 12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: _getRarityColor(rarity),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
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
                            const SizedBox(height: 70),
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
                              width: MediaQuery.of(context).size.width,
                              height: 400,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: _getRarityColor(rarity)
                                        .withOpacity(0.2),
                                  ),
                                  bottom: BorderSide(
                                    color: _getRarityColor(rarity)
                                        .withOpacity(0.2),
                                  ),
                                ),
                              ),
                              child: Image.network(
                                card['imageUrl'],
                                fit: BoxFit.cover,
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
                        backgroundColor: _getRarityColor(rarity),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
          const TopBarWidget(),
          _buildControlCenter(),
          _buildRefreshButton(),
          _buildEventBanner(),
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
                child: const ControlCenter(),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.dashboard_customize, color: Color(0xFF3B82F6)),
      ),
    );
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
