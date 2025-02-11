import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/badge.dart';
import 'dart:convert';

class BadgeProvider with ChangeNotifier {
  final _baseUrl = 'https://api.pitdeck.app/api';
  List<BadgeModel> _badges = [];
  final Map<String, List<BadgeModel>> _userBadges = {};
  bool _isLoading = false;

  List<BadgeModel> get badges => _badges;
  bool get isLoading => _isLoading;

  List<BadgeModel> getBadgesForUser(String userId) {
    return _userBadges[userId] ?? [];
  }

  Future<void> fetchUserBadges(String token, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response =
          await http.get(Uri.parse('$_baseUrl/badges/user/$userId'), headers: {
        'Authorization': 'Bearer $token',
      });

      final List<dynamic> jsonData = json.decode(response.body);

      _badges = jsonData.map((json) => BadgeModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching badges: $e');
      _badges = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBadgesForUserByUserId(String token, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$_baseUrl/badges/user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userBadges[userId] =
            data.map((json) => BadgeModel.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      _userBadges[userId] = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
