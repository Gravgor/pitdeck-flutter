import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pitdeck/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/main_wrapper.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoggedIn = false;
  final String _baseUrl = 'https://api.pitdeck.app/api';
  IO.Socket? _socket;
  bool isSocketConnected = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> initializeFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (_isLoggedIn && _token != null) {
      try {
        await fetchUserProfile();
      } catch (e) {
        await logout();
      }
    }
  }

  Future<void> connectUserSocket() async {
    if (_user?.token == null) return;

    _socket?.dispose();
    _socket = IO.io(
        'https://api.pitdeck.app/users',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer ${_user!.token}'})
            .enableForceNew()
            .build());

    _setupSocketListeners();
    _socket?.connect();
    print('Manual socket connection attempt...');
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      isSocketConnected = true;
      notifyListeners();
      print('Users Socket connected');
    });

    _socket?.onDisconnect((_) {
      isSocketConnected = false;
      notifyListeners();
      print('Users Socket disconnected');
    });

    _socket?.on('user:update', (data) {
      if (_user != null) {
        if (data is Map<String, dynamic>) {
          _user = _user!.copyWith(
            name: data['name'] ?? _user!.name,
            image: data['image'] ?? _user!.image,
            bio: data['bio'] ?? _user!.bio,
            isPremium: data['isPremium'] ?? _user!.isPremium,
            coins: data['coins'] ?? _user!.coins,
            level: data['level'] ?? _user!.level,
          );
          notifyListeners();
        }
      }
    });
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _user = User.fromJson(userData, token: _token);
        notifyListeners();
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchUserProfileID(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
      );
      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _user = User.fromJson(userData, token: _token);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchUserDetails(String userId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _user = User.fromJson(userData, token: token);
        await DefaultCacheManager().putFile(
          'user_details',
          utf8.encode(json.encode(_user!.toJson())),
        );

        notifyListeners();
      } else {
        throw Exception('Failed to fetch user details');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> fetchAnotherUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        return User.fromJson(userData, token: _token);
      } else {
        return null;
      }
    } catch (e) {
      rethrow;
    }


  }

  Future<void> updateUser(User user) async {
    _user = user;
    await DefaultCacheManager().putFile(
      'user_details',
      utf8.encode(json.encode(user.toJson())),
    );
    notifyListeners();
  }

  Future<void> loadCachedUser() async {
    try {
      final fileInfo =
          await DefaultCacheManager().getFileFromCache('user_details');
      if (fileInfo != null) {
        final userData =
            json.decode(utf8.decode(await fileInfo.file.readAsBytes()));
        _user = User.fromJson(userData);
        if (_user?.token != null) {
          await connectUserSocket();
        }
        notifyListeners();
      }
    } catch (e) {
      print('No cached user details found');
    }
  }

  Future<void> clearUser() async {
    _socket?.dispose();
    _user = null;
    await DefaultCacheManager().removeFile('user_details');
    notifyListeners();
  }

  Future<void> updateUserBio(String newBio) async {
    // Add your API call here if needed
    _user = _user?.copyWith(bio: newBio);
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> login(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setBool('isLoggedIn', true);
    _token = token;
    _isLoggedIn = true;
    await fetchUserProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.setBool('isLoggedIn', false);
    _token = null;
    _user = null;
    _isLoggedIn = false;
    await DefaultCacheManager().removeFile('user_details');
    await DefaultCacheManager().removeFile('daily_reward_status');
    Navigator.of(navigatorKey.currentContext!).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
    notifyListeners();
  }
}
