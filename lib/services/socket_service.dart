import 'package:pitdeck/main.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/models/drop.dart';
import 'dart:async';

class DropsSocketService {
  IO.Socket? socket;
  Function(List<DropModel>)? onDropsUpdate;
  Timer? _reconnectTimer;
  bool _isConnecting = false;
  final _retryDelays = [2, 5, 10, 30]; // Seconds between retry attempts
  int _retryAttempt = 0;
  List<DropModel> drops = [];
  final baseUrl = 'ws://api.pitdeck.app/drops';

  void initSocket(UserProvider auth) {
    if (_isConnecting) return;
    _isConnecting = true;

    final token = auth.user?.token;
    print(
        'Initializing socket with token: ${token?.substring(0, 10)}...');

    if (token == null) {
      print('Socket error: No auth token available');
      return;
    }

    try {
      socket = IO.io(
        baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setReconnectionAttempts(3)
            .enableAutoConnect()
            .setQuery({'token': token}) // Try adding token as query parameter
            .build(),
      );

      print('Socket instance created, attempting connection...');
      _setupSocketListeners();
      socket?.connect(); // Explicitly call connect
    } catch (e) {
      print('Socket initialization error: $e');
      _scheduleReconnect();
    }
  }

  void _setupSocketListeners() {
    socket?.onConnect((_) {
      print('Socket connected successfully');
      _isConnecting = false;
      _retryAttempt = 0;
      _reconnectTimer?.cancel();
      getDrops();
    });

    socket?.onConnectError((error) {
      print('Socket connection error: $error');
      print('Current socket state: ${socket?.connected}');
      _scheduleReconnect();
    });

    socket?.onError((error) => print('Socket error: $error'));
    socket?.onDisconnect((_) => print('Socket disconnected'));

    socket?.on('drops:nearby', (data) {
      print('Received drops: $data');
      if (data != null) {
        try {
          final drops =
              (data as List).map((d) => DropModel.fromJson(d)).toList();
          this.drops = drops;
          onDropsUpdate?.call(drops);
        } catch (e) {
          print('Error parsing drops data: $e');
        }
      }
    });
  }

  List<DropModel> getDrops() {
    return drops;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_retryAttempt >= _retryDelays.length) return;

    final delay = _retryDelays[_retryAttempt];
    print('Scheduling reconnect in $delay seconds');

    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _retryAttempt++;
      _isConnecting = false;
      initSocket(Provider.of<UserProvider>(navigatorKey.currentContext!,
          listen: false));
    });
  }

  void startLocationUpdates() async {
    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return;
    }

    Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // minimum distance (meters) before updates
    )).listen((Position position) {
      if (socket != null) {
        socket?.emit('location:update',
            {'latitude': position.latitude, 'longitude': position.longitude});
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
  }
}
