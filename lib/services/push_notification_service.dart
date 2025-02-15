import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class PushNotificationService extends ChangeNotifier {
  static const String _deviceTokenKey = 'deviceToken';
  static const String _baseUrl = 'https://api.pitdeck.app/api';
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      if (Platform.isIOS) {
        await _requestIOSPermission();
      }

      final String? existingToken = await _getStoredToken();
      if (existingToken != null) {
        debugPrint('Existing device token: $existingToken');
        return;
      }

      final String? newToken = await _getNewToken();
      if (newToken != null) {
        await _storeToken(newToken);
        debugPrint('New device token: $newToken');
      }

      // Setup token refresh listener
      _setupTokenRefreshListener();
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  Future<void> _requestIOSPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('Push notification permission denied');
      throw Exception('Push notification permission denied');
    }
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceTokenKey);
  }

  Future<String?> _getNewToken() async {
    if (Platform.isIOS) {
      return await _fcm.getAPNSToken();
    }
    return await _fcm.getToken();
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceTokenKey, token);
  }

  void _setupTokenRefreshListener() {
    _fcm.onTokenRefresh.listen((String newToken) async {
      debugPrint('Token refreshed: $newToken');
      await _storeToken(newToken);
      await _sendTokenToServer(newToken);
    });
  }

  Future<void> _sendTokenToServer(String token, {String? authToken}) async {
    try {
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
      };

      

      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update-device-token'),
        headers: headers,
        body: json.encode({
          'deviceToken': token,
          'deviceType': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update device token on server');
      }
    } catch (e) {
      debugPrint('Error sending token to server: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    return await _getStoredToken();
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceTokenKey);
  }

  Future<void> updateServerToken(String? authToken) async {
    final deviceToken = await getToken();
    if (deviceToken != null && authToken != null) {
      await _sendTokenToServer(deviceToken, authToken: authToken);
    }
  }

  Future<void> setupNotificationHandlers() async {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message also contained a notification: ${message.notification}');
      }
    });

    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Message open handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // Handle app open from notification
    });
  }
}

// This needs to be a top-level function
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}
