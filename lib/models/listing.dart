import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/models/user.dart';

enum ListingStatus { ACTIVE, SOLD, CANCELLED }

class ListingModel {
  final String id;
  final int price;
  final ListingStatus status;
  final String cardId;
  final String sellerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CardDetailModel card;
  final User seller;

  ListingModel({
    required this.id,
    required this.price,
    required this.status,
    required this.cardId,
    required this.sellerId,
    required this.createdAt,
    required this.updatedAt,
    required this.card,
    required this.seller,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'],
      price: json['price'],
      status: ListingStatus.values.firstWhere(
        (e) => e.toString() == 'ListingStatus.${json['status']}',
        orElse: () => ListingStatus.ACTIVE,
      ),
      cardId: json['cardId'],
      sellerId: json['sellerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      card: CardDetailModel.fromJson(json['card']),
      seller: User.fromJson(json['seller']),
    );
  }
}
