import 'package:flutter/foundation.dart';
import 'package:pitdeck/main.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:provider/provider.dart';
import '../models/favorite.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FavoriteProvider with ChangeNotifier {
  final _baseUrl = 'https://api.pitdeck.app/api';
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;


  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> fetchFavorites() async {
    try {
      _isLoading = true;
      notifyListeners();
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      final response = await http.get(Uri.parse('$_baseUrl/users/favorites'), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _favorites = (data as List)
            .map((json) => FavoriteModel.fromJson(json))
            .toList();
      }
    } catch (e) {
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
