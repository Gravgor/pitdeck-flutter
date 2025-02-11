import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/badge.dart';
import 'dart:convert';

class BadgeProvider extends ChangeNotifier {
  final _baseUrl = 'https://api.pitdeck.app/api';
  final Map<String, List<BadgeModel>> _userBadges = {};

  List<BadgeModel> getBadgesForUser(String userId) {
    return _userBadges[userId] ?? [];
  }

  bool hasLoadedForUser(String userId) {
    return _userBadges.containsKey(userId);
  }

  Future<void> fetchUserBadges(String token, String userId) async {
    if (_userBadges.containsKey(userId)) return;

    try {
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
      notifyListeners();
    }
  }
}
