import 'package:flutter/material.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/screens/main_wrapper.dart';
import 'package:pitdeck/screens/auth/onboarding_screen.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthProvider with ChangeNotifier {
  final _userSubject = BehaviorSubject<User?>();
  final _baseUrl = 'https://api.pitdeck.app/api';
  static const String _isLoggedIn = 'isLoggedIn';
  static const String _token = 'token';
  static const String _userId = 'userId';

  User? get currentUser => _userSubject.valueOrNull;
  Stream<User?> get userStream => _userSubject.stream;

  Future<void> saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedIn, true);
    await prefs.setString(_token, user.token);
    await prefs.setString(_userId, user.id);
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final initialUser = User(
          id: data['user']['id'],
          email: data['user']['email'],
          name: data['user']['name'],
          token: data['token'],
          createdAt: DateTime.parse(
              data['user']['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.now(),
          coins: data['user']['coins'] ?? 1000,
          level: data['user']['level'] ?? 1,
          xp: data['user']['xp'] ?? 0,
          totalXp: data['user']['totalXp'] ?? 0,
          image: data['user']['image'],
          bio: data['user']['bio'] ?? '',
          isPremium: data['user']['isPremium'] ?? false,
        );

        // First store basic user data
        _userSubject.add(initialUser);

        // Then fetch detailed user info
        final detailsResponse = await http.get(
          Uri.parse('$_baseUrl/users/${initialUser.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${initialUser.token}',
          },
        );

        if (detailsResponse.statusCode == 200) {
          final userDetails = json.decode(detailsResponse.body);
          final fullUser = User(
            id: userDetails['id'],
            name: userDetails['name'],
            email: userDetails['email'],
            image: userDetails['image'],
            coins: userDetails['coins'],
            totalXp: userDetails['totalXp'],
            level: userDetails['level'],
            bio: userDetails['bio'],
            xp: userDetails['xp'],
            createdAt: DateTime.parse(userDetails['createdAt']),
            updatedAt: DateTime.now(),
            isPremium: userDetails['isPremium'],
            token: initialUser.token,
          );
          await saveUserToPrefs(fullUser);
          _userSubject.add(fullUser);
          await Provider.of<UserProvider>(navigatorKey.currentContext!,
                  listen: false)
              .updateUser(fullUser);

          notifyListeners();
        } else {
          throw Exception('Failed to fetch user details');
        }
      } else {
        throw Exception('Failed to login');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await Provider.of<UserProvider>(navigatorKey.currentContext!, listen: false)
        .clearUser();
    _userSubject.add(null);
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final initialUser = User.fromJson(data['user'], token: data['token']);

        _userSubject.add(initialUser);

        final detailsResponse = await http.get(
          Uri.parse('$_baseUrl/users/${initialUser.id}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${initialUser.token}',
          },
        );

        if (detailsResponse.statusCode == 200) {
          final userDetails = json.decode(detailsResponse.body);
          final fullUser = User.fromJson(userDetails, token: initialUser.token);

          _userSubject.add(fullUser);
          await Provider.of<UserProvider>(navigatorKey.currentContext!,
                  listen: false)
              .updateUser(fullUser);

          notifyListeners();
        } else {
          throw Exception('Failed to fetch user details');
        }
      } else {
        throw Exception('Failed to register');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userId);
      final token = prefs.getString(_token);
      if (userId == null || token == null) {
        throw Exception('User ID or token not found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userDetails = json.decode(response.body);
        final user = User.fromJson(userDetails, token: token);
        _userSubject.add(user);

        await Provider.of<UserProvider>(navigatorKey.currentContext!,
                listen: false)
            .updateUser(user);

        notifyListeners();
      } else {
        throw Exception('Failed to fetch user details: ${response.statusCode}');
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _userSubject.add(null);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Failed to get ID token');

      // Send to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/google/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['id']);
        await prefs.setBool('isLoggedIn', true);
        await getUserDetails();
        notifyListeners();
      } else {
        throw Exception('Failed to authenticate with Google');
      }
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Get Firebase token for push notifications
      final messaging = FirebaseMessaging.instance;

      // Request permission first (iOS requires this)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get the token
      final deviceToken = await messaging.getAPNSToken();

      // Send to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/mobile/apple'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identityToken': credential.identityToken,
          'authorizationCode': credential.authorizationCode,
          'givenName': credential.givenName,
          'familyName': credential.familyName,
          'email': credential.email,
          'deviceToken': deviceToken,
          'deviceType': 'ios',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('userId', data['user']['id']);
        await prefs.setBool('isLoggedIn', true);

        // Save device token locally if needed
        if (deviceToken != null) {
          await prefs.setString('deviceToken', deviceToken);
        }

        await getUserDetails();
        if (data['user']['needUsernameSetup']) {
          Navigator.of(navigatorKey.currentContext!)
              .pushReplacementNamed('/onboarding');
        } else {
          Navigator.of(navigatorKey.currentContext!)
              .pushReplacementNamed('/main');
        }

        notifyListeners();
      } else {
        throw Exception('Failed to authenticate with Apple');
      }
    } catch (e) {
      throw Exception('Apple sign in failed: $e');
    }
  }

  Future<void> updateUsername(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/update/name'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${currentUser?.token}',
        },
        body: json.encode({'name': username}),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final user = User.fromJson(data['user'], token: currentUser?.token);
        _userSubject.add(user);
        notifyListeners();
      } else {
        throw Exception('Failed to update username');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setupPushNotifications() async {
    final messaging = FirebaseMessaging.instance;

    // Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      if (currentUser != null) {
        // Send updated token to backend
        await http.post(
          Uri.parse('$_baseUrl/auth/update-device-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${currentUser!.token}',
          },
          body: json.encode({
            'deviceToken': newToken,
            'deviceType': 'ios',
          }),
        );
      }
    });
  }

  @override
  void dispose() {
    _userSubject.close();
    super.dispose();
  }
}
