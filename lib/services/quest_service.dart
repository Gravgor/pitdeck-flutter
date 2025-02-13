import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pitdeck/models/quest.dart';

class QuestService extends ChangeNotifier {
  final String baseUrl = 'https://api.pitdeck.app/api';
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Quest>> getAvailableQuests(String token) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/quests/available'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbTNsbGlmNnEwMDAwMTM1enh1NWdtOGJ1IiwiaWF0IjoxNzM4ODkxMDMwLCJleHAiOjE3Mzk0OTU4MzB9.ynEoK8qfo95ahsOnk5FsLcu-aKM8oFTLUW6oOPcrT9E',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> questsJson = json.decode(response.body);
        return questsJson.map((quest) => Quest.fromJson(quest)).toList();
      } else {
        _error = json.decode(response.body)['message'];
        throw Exception(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Quest>> getAvailableQuestsByCategory(
      String token, String category) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$baseUrl/quests/available/$category'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbTNsbGlmNnEwMDAwMTM1enh1NWdtOGJ1IiwiaWF0IjoxNzM4ODkxMDMwLCJleHAiOjE3Mzk0OTU4MzB9.ynEoK8qfo95ahsOnk5FsLcu-aKM8oFTLUW6oOPcrT9E',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> questsJson = json.decode(response.body);
        return questsJson.map((quest) => Quest.fromJson(quest)).toList();
      } else {
        _error = json.decode(response.body)['message'];
        throw Exception(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getQuestProgress(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quests/progress/summary'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbTNsbGlmNnEwMDAwMTM1enh1NWdtOGJ1IiwiaWF0IjoxNzM4ODkxMDMwLCJleHAiOjE3Mzk0OTU4MzB9.ynEoK8qfo95ahsOnk5FsLcu-aKM8oFTLUW6oOPcrT9E',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } catch (e) {
      throw Exception('Failed to load quest progress');
    }
  }

  Future<Map<String, dynamic>> claimQuestReward(
      String token, String questId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('$baseUrl/quests/$questId/claim'),
        headers: {
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbTNsbGlmNnEwMDAwMTM1enh1NWdtOGJ1IiwiaWF0IjoxNzM4ODkxMDMwLCJleHAiOjE3Mzk0OTU4MzB9.ynEoK8qfo95ahsOnk5FsLcu-aKM8oFTLUW6oOPcrT9E',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['message']);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
