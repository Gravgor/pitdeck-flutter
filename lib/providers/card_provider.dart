import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/card.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/main.dart';

class CardProvider with ChangeNotifier {
  final String _baseUrl = 'https://api.pitdeck.app/api';
  List<CardModel> _cards = [];
  final Map<String, CardDetailModel> _cardDetails = {};
  final kDebugToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJjbTNsbGlmNnEwMDAwMTM1enh1NWdtOGJ1IiwiaWF0IjoxNzM5NTM0ODQyLCJleHAiOjE3NDAxMzk2NDJ9.CHNTGbn7m-SAgdlhzBB9Z5tHK-x1YqMt15OYz-x3pS8';
  List<CardModel> get cards => _cards;
  Map<String, CardDetailModel> get cardDetails => _cardDetails;

  bool isLoading = false;

  List<CardModel> getUserCards() {
    return _cards;
  }

  Future<List<CardModel>> fetchUserCards() async {
    try {
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final userId = userProvider.user?.id;
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> cardsData = json.decode(response.body);

        _cards = cardsData.map((json) => CardModel.fromJson(json)).toList()
          ..sort((a, b) =>
              (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
                  a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
        notifyListeners();
        return _cards;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load cards');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<CardDetailModel> fetchCardDetails(String cardId) async {
    try {    
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/cards/details/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final cardDetail = CardDetailModel.fromJson(json);

        // Cache the details
        _cardDetails[cardId] = cardDetail;
        notifyListeners();

        return cardDetail;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load card details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> revalidateUserCards() async {
    await fetchUserCards();
  }

  Future<void> sellCard(String cardId, int price) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    final response = await http.post(
      Uri.parse('$_baseUrl/marketplace/put-for-sale/$cardId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'price': price,
      }),
    );
    if (response.statusCode == 201) {
      await fetchUserCards();
      await userProvider.fetchUserProfile();
      notifyListeners();
    }
  }

  Future<void> removeFromMarketplace(String cardId) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    final response = await http.post(
      Uri.parse('$_baseUrl/marketplace/remove-from-sale/$cardId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      notifyListeners();
    }
  }
}
