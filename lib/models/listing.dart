import 'package:pitdeck/models/card.dart';
import 'package:flutter/foundation.dart';
import 'package:pitdeck/models/trade_offer.dart';

enum ListingStatus { ACTIVE, SOLD, CANCELLED }

class ListingModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sellerId;
  final String status;
  final String? note;
  final DateTime? expiresAt;
  final int price;
  final CardDetailModel card;
  final OfferUserModel seller;

  ListingModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    required this.status,
    this.note,
    this.expiresAt,
    required this.price,
    required this.card,
    required this.seller,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    try {
      if (json.containsKey('message') && json.length == 1) {
        throw const FormatException('Response contains only message');
      }

      return ListingModel(
        id: json['id'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        sellerId: json['sellerId'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        note: json['note'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        price: json['price'] as int? ?? 0,
        card: json['card'] != null
            ? CardDetailModel.fromJson(json['card'] as Map<String, dynamic>)
            : CardDetailModel.empty(),
        seller: json['seller'] != null
            ? OfferUserModel.fromJson(json['seller'] as Map<String, dynamic>)
            : OfferUserModel.empty(),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing ListingModel: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String? image;
  final int level;

  UserModel(
      {required this.id, required this.name, this.image, required this.level});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      level: json['level'] as int? ?? 0,
    );
  }
}

extension CardDetailModelEmpty on CardDetailModel {
  static CardDetailModel empty() {
    return CardDetailModel(
      id: '', 
      name: '',
      description: '',
      imageUrl: '',
      rarity: 'COMMON',
      type: '',
      series: '',
      stats: {},
      edition: '',
      serialNumber: '',
      year: 0,
      isExclusive: false,
      isForSale: false,
      isForTrade: false,
      updatedAt: DateTime.now(),
    );
  }
}

extension OfferUserModelEmpty on OfferUserModel {
  static OfferUserModel empty() {
    return OfferUserModel(
      id: '',
      name: '',
      level: 0,
      image: '',
    );
  }
}
