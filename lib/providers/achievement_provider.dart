import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/achievement.dart';

class AchievementProvider with ChangeNotifier {
  List<UserAchievement> _achievements = [];
  bool _isLoading = false;
  String? _error;

  List<UserAchievement> get achievements => _achievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserAchievements(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.pitdeck.app/api/users/achievements'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _achievements =
            data.map((json) => UserAchievement.fromJson(json)).toList();
      } else {
        _error = 'Failed to load achievements';
      }
    } catch (e) {
      _error = 'Network error occurred';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
