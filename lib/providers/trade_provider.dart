import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/trade.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class TradeProvider with ChangeNotifier {
  final String _baseUrl = 'https://api.pitdeck.app/api';
  List<TradeModel> _trades = [];
  late IO.Socket _socket;

  TradeProvider() {
    _initializeSocket();
  }

  void _initializeSocket() {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;

    _socket = IO.io(
      'https://api.pitdeck.app',
      IO.OptionBuilder().setTransports(['websocket']).setExtraHeaders(
          {'Authorization': 'Bearer $token'}).build(),
    );

    _socket.onConnect((_) {
      print('Connected to WebSocket');
      _socket.emit('subscribeMarketplace');
    });

    _socket.on('newTrade', (data) {
      final newTrade = TradeModel.fromJson(data);
      _trades.add(newTrade);
      notifyListeners();
    });

    _socket.onDisconnect((_) => print('Disconnected from WebSocket'));
    _socket.onError((err) => print('WebSocket error: $err'));
  }

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
        Uri.parse('$_baseUrl/marketplace/trades'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> tradesData = responseData['trades'];
        _trades = tradesData
            .map((json) {
              try {
                return TradeModel.fromJson(json);
              } catch (e) {
                print('Error parsing trade: $e');
                print('Trade data: $json');
                return null;
              }
            })
            .whereType<TradeModel>()
            .toList();
        notifyListeners();
        return _trades;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load trades');
      }
    } catch (e) {
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
        Uri.parse('$_baseUrl/marketplace/trades'),
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
        Uri.parse('$_baseUrl/marketplace/trades/$tradeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _trades.removeWhere((trade) => trade.id == tradeId);
        notifyListeners();
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

  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
