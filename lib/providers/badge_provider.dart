import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pitdeck/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/badge.dart';

class BadgeProvider with ChangeNotifier {
  final _baseUrl = 'https://api.pitdeck.app/api';
  List<BadgeModel> _badges = [];
  bool _isLoading = false;

  List<BadgeModel> get badges => _badges;
  bool get isLoading => _isLoading;

  Future<void> fetchBadges() async {
    try {
      _isLoading = true;
      notifyListeners();
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      final response = await http.get(Uri.parse('$_baseUrl/users/badges'), headers: {
        'Authorization': 'Bearer $token',
      });
      _badges = (response.body as List)
          .map((json) => BadgeModel.fromJson(json))
          .toList();
    } catch (e) {
      _badges = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserBadges(String token, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();
      final response = await http.get(Uri.parse('$_baseUrl/badges/user/$userId'), headers: {
        'Authorization': 'Bearer $token',
      });
      _badges = (response.body as List)
          .map((json) => BadgeModel.fromJson(json))
          .toList();
    } catch (e) {
      _badges = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

  }
}
