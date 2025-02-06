import 'package:pitdeck/models/card.dart';

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
  final UserModel seller;

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
      return ListingModel(
        id: json['id'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.parse(json['updatedAt'] as String? ?? ''),
        sellerId: json['sellerId'] as String? ?? '',
        status: json['status'] as String? ?? 'PENDING',
        note: json['note'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        price: json['price'] as int? ?? 0,
        card: CardDetailModel.fromJson(json['card'] as Map<String, dynamic>? ?? {}),
        seller:
            UserModel.fromJson(json['seller'] as Map<String, dynamic>? ?? {}),
      );
    } catch (e, stackTrace) {
      print('Error parsing ListingModel: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String? image;
  final int level;

  UserModel({required this.id, required this.name, this.image, required this.level});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      image: json['image'] as String?,
      level: json['level'] as int? ?? 0,
    );
  }
}
