import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/listing.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/main.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ListingProvider with ChangeNotifier {
  final String _baseUrl = 'https://api.pitdeck.app/api';
  List<ListingModel> _listings = [];
  late IO.Socket _socket;

  ListingProvider() {
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

    _socket.on('newListing', (data) {
      try {
        final newListing = ListingModel.fromJson(data);
        _listings.add(newListing);
        notifyListeners();
      } catch (e) {
        print('Error parsing socket listing: $e');
        print('Listing data: $data');
      }
    });

    _socket.on('newSold', (data) {
      fetchListings();
    });

    _socket.onDisconnect((_) => print('Disconnected from WebSocket'));
    _socket.onError((err) => print('WebSocket error: $err'));
  }

  List<ListingModel> get listings => _listings;
  List<ListingModel> get activeListings => _listings
      .where((listing) => listing.status == ListingStatus.ACTIVE)
      .toList();

  Future<List<ListingModel>> fetchListings() async {
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
        Uri.parse('$_baseUrl/marketplace/listings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> listingsData = responseData['listings'];
        final activeListings = listingsData
            .where((listing) => listing['status'] == 'ACTIVE')
            .toList();
        final userProvider = Provider.of<UserProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        final userId = userProvider.user?.id;
        final filteredListings = activeListings
            .where((listing) => listing['sellerId'] != userId)
            .toList();
        _listings = filteredListings
            .map((json) {
              try {
                return ListingModel.fromJson(json);
              } catch (e) {
                print('Error parsing listing: $e');
                print('Listing data: $json');
                return null;
              }
            })
            .whereType<ListingModel>()
            .toList();
        notifyListeners();
        return _listings;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load listings');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> createListing({
    required String cardId,
    required int price,
    String? note,
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
        Uri.parse('$_baseUrl/marketplace/put-for-sale/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'price': price,
        }),
      );

      if (response.statusCode == 201) {
        print('Listing created successfully');
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create listing');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> buyListing(String listingId) async {
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
        Uri.parse('$_baseUrl/marketplace/buy/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        _listings.removeWhere((listing) => listing.id == listingId);
        // Refetch listings
        await userProvider.fetchUserProfile();
        fetchListings();
        notifyListeners();
        
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to buy listing');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> cancelListing(String listingId) async {
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
        Uri.parse('$_baseUrl/marketplace/listings/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _listings.removeWhere((listing) => listing.id == listingId);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel listing');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<void> removeFromSale(String listingId) async {
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
        Uri.parse('$_baseUrl/marketplace/remove-from-sale/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        _listings.removeWhere((listing) => listing.id == listingId);
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to remove from sale');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }


  
  

  Future<List<String>> getListedCardIds() async {
    final userProvider = Provider.of<UserProvider>(
      navigatorKey.currentContext!,
      listen: false,
    );
    final token = userProvider.user?.token;
    final response = await http.get(
      Uri.parse('$_baseUrl/marketplace/listings/card-ids'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> cardIds = json.decode(response.body);
      return cardIds.map((id) => id.toString()).toList();
    } else {
      throw Exception('Failed to get listed card ids');
    }
  }


  @override
  void dispose() {
    _socket.dispose();
    super.dispose();
  }
}
