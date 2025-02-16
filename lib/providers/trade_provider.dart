import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pitdeck/models/trade_offer.dart';
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
  List<TradeModel> _myListings = [];
  final Map<String, List<TradeOfferModel>> _receivedOffers = {};
  List<TradeModel> _allReceivedOffers = [];

  Map<String, List<TradeOfferModel>> get receivedOffers => _receivedOffers;
  List<TradeModel> get allReceivedOffers => _allReceivedOffers;

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

      final response = await http.delete(
        Uri.parse('$_baseUrl/marketplace/trades/cancel/$tradeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        _trades.removeWhere((trade) => trade.id == tradeId);
        _myListings.removeWhere((trade) => trade.id == tradeId);
        _receivedOffers.remove(tradeId);
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

      if (response.statusCode == 201) {
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

  Future<void> makeOffer({
    required String tradeId,
    required List<String> offeredCardIds,
    required int coinsOffered,
    String? note,
  }) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/trades/make-offer/$tradeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'offeredCardIds': offeredCardIds,
          'coinsOffered': coinsOffered,
        }),
      );
      if (response.statusCode == 201) {
        final updatedTrade = TradeModel.fromJson(json.decode(response.body));
        final index = _trades.indexWhere((trade) => trade.id == tradeId);
        if (index != -1) {
          _trades[index] = updatedTrade;
          notifyListeners();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to make offer');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  List<TradeModel> get myListings => _myListings;

  Future<void> fetchMyListings() async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/trades/my-listings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> tradesData = json.decode(response.body);
        _myListings =
            tradesData.map((json) => TradeModel.fromJson(json)).toList();

        _myListings = _myListings
            .where((trade) =>
                trade.status != TradeStatus.CANCELLED &&
                trade.status != TradeStatus.ACCEPTED)
            .toList();

        // Safely fetch offers for each listing
        for (var trade in _myListings) {
          try {
            await fetchReceivedOffers(trade.id);
          } catch (e) {
            print('Error fetching offers for trade ${trade.id}: $e');
            _receivedOffers[trade.id] = [];
          }
        }

        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load my listings');
      }
    } catch (e) {
      print('Error fetching my listings: $e');
      _myListings = []; // Reset to empty list on error
      notifyListeners();
      throw Exception('Network error: $e');
    }
  }

  Future<void> fetchReceivedOffers(String tradeId) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/trade/$tradeId/offers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> offersData = json.decode(response.body);
        _receivedOffers[tradeId] =
            offersData.map((json) => TradeOfferModel.fromJson(json)).toList();
        print('Received offers: ${_receivedOffers[tradeId]}');
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to load received offers');
      }
    } catch (e) {
      print('Error fetching offers: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<void> fetchAllReceivedOffers() async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/marketplace/trades/received'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> tradesData = json.decode(response.body);
        print(tradesData);
        _allReceivedOffers =
            tradesData.map((json) => TradeModel.fromJson(json)).toList();
        _allReceivedOffers = _allReceivedOffers
            .where((trade) => trade.status == TradeStatus.PENDING)
            .toList();
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Failed to load received offers');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> acceptOffer(String offerId) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/trades/accept-offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 201) {
        final updatedTrade = TradeModel.fromJson(json.decode(response.body));
        final index = _allReceivedOffers
            .indexWhere((trade) => trade.id == updatedTrade.id);
        if (index != -1) {
          _allReceivedOffers[index] = updatedTrade;
          notifyListeners();
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to accept offer');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> declineOffer(String offerId) async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marketplace/trades/decline-offer/$offerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final updatedTrade = TradeModel.fromJson(json.decode(response.body));
        final index = _allReceivedOffers
            .indexWhere((trade) => trade.id == updatedTrade.id);
        if (index != -1) {
          _allReceivedOffers[index] = updatedTrade;
          notifyListeners();
        }
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<String>> getActiveTradeCardIds() async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,

    );
    final token = userProvider.user?.token;
    final response = await http.get(
      Uri.parse('$_baseUrl/marketplace/trades/active-trade-card-ids'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> cardIds = json.decode(response.body);
      return cardIds.map((id) => id.toString()).toList();
    } else {
      throw Exception('Failed to get active trade card ids');
    }
  }



  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
