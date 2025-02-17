import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class DailyRewardService extends ChangeNotifier {
  static const String baseUrl = 'https://api.pitdeck.app/api';

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _rewardStatus;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get rewardStatus => _rewardStatus;

  Future<void> initialize() async {
    _isLoading = false;
    _error = null;
    _rewardStatus = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> getDailyRewardStatus(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/daily-reward/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _rewardStatus = json.decode(response.body);
        return _rewardStatus!;
      } else {
        _error = json.decode(response.body)['message'];
        throw Exception(_error);
      }
    } catch (e) {
      _error = 'Failed to get daily reward status: $e';
      throw Exception(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> claimDailyReward(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/daily-reward/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        await getDailyRewardStatus(token); 
        return result;
      } else {
        _error = json.decode(response.body)['message'];
        return null;
      }
    } catch (e) {
      _error = 'Failed to claim daily reward: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> useStreakSaver(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/daily-reward/streak-saver'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        await getDailyRewardStatus(
            token); // Refresh status after using streak saver
        return result;
      } else {
        _error = json.decode(response.body)['message'];
        return null;
      }
    } catch (e) {
      _error = 'Failed to use streak saver: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
