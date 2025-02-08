import 'package:http/http.dart' as http;
import 'dart:convert';

class DailyRewardService {
  static const String baseUrl = 'https://api.pitdeck.app/api';

  Future<Map<String, dynamic>> getDailyRewardStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/daily-reward/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to get daily reward status: $e');
    }
  }

  Future<Map<String, dynamic>> claimDailyReward(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-reward/claim'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }

    } catch (e) {
      throw Exception('Failed to claim daily reward: $e');
    }
  }

  Future<Map<String, dynamic>> useStreakSaver(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/daily-reward/streak-saver'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to use streak saver: $e');
    }
  }
}
