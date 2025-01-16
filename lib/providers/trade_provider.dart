import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/trade.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/main.dart';

class TradeProvider with ChangeNotifier {
  final String _baseUrl = 'https://api.pitdeck.app/api';
  List<TradeModel> _trades = [];

  List<TradeModel> get trades => _trades;
  List<TradeModel> get activeTrades {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final currentUserId = userProvider.user?.id;

    return _trades
        .where((trade) =>
            trade.status == TradeStatus.PENDING &&
            trade.senderId != currentUserId)
        .toList();
  }

  Future<List<TradeModel>> fetchTrades() async {
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
        Uri.parse('$_baseUrl/marketplace/listings/trade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tradesData = json.decode(response.body);
        print('Fetched trades: $tradesData');
        _trades = tradesData.map((json) => TradeModel.fromJson(json)).toList();
        notifyListeners();
        return _trades;
      } else {
        final errorData = json.decode(response.body);
        print('Trade fetch error: ${response.statusCode} - ${response.body}');
        throw Exception(errorData['message'] ?? 'Failed to load trades');
      }
    } catch (e) {
      print('Trade fetch exception: $e');
      throw Exception('Network error: $e');
    }
  }

  List<TradeModel> getUserListings(String userId) {
    return _trades.where((trade) => trade.senderId == userId).toList();
  }

  Future<void> createTrade({
    required List<String> offeredCardIds,
    required int coinsOffered,
    String? note,
    List<String>? receiverIds,
    List<String>? wantedCardIds,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/listings/trade'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'offeredCardIds': offeredCardIds,
          'coinsOffered': coinsOffered,
          'note': note,
          'receiverIds': receiverIds,
          'wantedCardIds': wantedCardIds,
          'isOpenTrade': receiverIds == null || receiverIds.isEmpty,
        }),
      );

      if (response.statusCode == 201) {
        final newTrade = TradeModel.fromJson(json.decode(response.body));
        _trades.add(newTrade);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create trade');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> cancelTrade(String tradeId) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/marketplace/listings/trade/$tradeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final index = _trades.indexWhere((trade) => trade.id == tradeId);
        if (index != -1) {
          _trades[index] = TradeModel.fromJson(json.decode(response.body));
          notifyListeners();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel trade');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

    Future<void> acceptTrade(String tradeId) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/listings/trade/$tradeId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final updatedTrade = TradeModel.fromJson(json.decode(response.body));
        final index = _trades.indexWhere((trade) => trade.id == tradeId);
        if (index != -1) {
          _trades[index] = updatedTrade;
          notifyListeners();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to accept trade');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> declineTrade(String tradeId) async {
    try {
      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      final token = userProvider.user?.token;

      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/listings/trade/$tradeId/decline'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final updatedTrade = TradeModel.fromJson(json.decode(response.body));
        final index = _trades.indexWhere((trade) => trade.id == tradeId);
        if (index != -1) {
          _trades[index] = updatedTrade;
          notifyListeners();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to decline trade');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
