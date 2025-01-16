import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/listing.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/main.dart';

class ListingProvider with ChangeNotifier {
  final String _baseUrl = 'https://api.pitdeck.app/api';
  List<ListingModel> _listings = [];

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
        Uri.parse('$_baseUrl/marketplace/listings/sell'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> listingsData = json.decode(response.body);
        _listings =
            listingsData.map((json) => ListingModel.fromJson(json)).toList();
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
        Uri.parse('$_baseUrl/listings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'cardId': cardId,
          'price': price,
        }),
      );

      if (response.statusCode == 201) {
        final newListing = ListingModel.fromJson(json.decode(response.body));
        _listings.add(newListing);
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
        Uri.parse('$_baseUrl/listings/$listingId/buy'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update the listing status instead of removing it
        final index =
            _listings.indexWhere((listing) => listing.id == listingId);
        if (index != -1) {
          final updatedListing =
              ListingModel.fromJson(json.decode(response.body));
          _listings[index] = updatedListing;
          notifyListeners();
        }
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
        Uri.parse('$_baseUrl/listings/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final index =
            _listings.indexWhere((listing) => listing.id == listingId);
        if (index != -1) {
          _listings[index] = ListingModel.fromJson(json.decode(response.body));
          notifyListeners();
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel listing');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
