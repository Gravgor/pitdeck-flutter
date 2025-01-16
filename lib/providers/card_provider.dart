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
  Map<String, CardDetailModel> _cardDetails = {};

  List<CardModel> get cards => _cards;
  Map<String, CardDetailModel> get cardDetails => _cardDetails;

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

        _cards = cardsData.map((json) => CardModel.fromJson(json)).toList();
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
      // Return cached details if available
      if (_cardDetails.containsKey(cardId)) {
        return _cardDetails[cardId]!;
      }

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
}

