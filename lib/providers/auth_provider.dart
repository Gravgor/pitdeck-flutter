import 'package:flutter/material.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:convert';
import '../models/user.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class AuthProvider with ChangeNotifier {
  final _userSubject = BehaviorSubject<User?>();
  final _baseUrl = 'https://api.pitdeck.app/api';

  User? get currentUser => _userSubject.valueOrNull;
  Stream<User?> get userStream => _userSubject.stream;

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

  @override
  void dispose() {
    _userSubject.close();
    super.dispose();
  }
}
