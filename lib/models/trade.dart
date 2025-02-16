import 'package:pitdeck/models/card.dart';

enum TradeStatus { PENDING, ACCEPTED, DECLINED, CANCELLED, EXPIRED, REJECTED }

class TradeModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String senderId;
  final TradeStatus status;
  final bool isOpenTrade;
  final String? note;
  final DateTime? expiresAt;
  final int coinsOffered;
  final List<CardDetailModel> offeredCards;
  final UserModel sender;

  TradeModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.senderId,
    required this.status,
    required this.isOpenTrade,
    this.note,
    this.expiresAt,
    required this.coinsOffered,
    required this.offeredCards,
    required this.sender,
  });

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    try {
      return TradeModel(
        id: json['id'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String? ?? ''),
        updatedAt: DateTime.parse(json['updatedAt'] as String? ?? ''),
        senderId: json['senderId'] as String? ?? '',
        status: TradeStatus.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              (json['status'] as String? ?? 'PENDING'),
          orElse: () => TradeStatus.PENDING,
        ),
        isOpenTrade: json['isOpenTrade'] as bool? ?? true,
        note: json['note'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        coinsOffered: json['coinsOffered'] as int? ?? 0,
        offeredCards: (json['offeredCards'] as List<dynamic>? ?? [])
            .map((cardJson) =>
                CardDetailModel.fromJson(cardJson as Map<String, dynamic>))
            .toList(),
        sender:
            UserModel.fromJson(json['sender'] as Map<String, dynamic>? ?? {}),
      );
    } catch (e, stackTrace) {
      print('Error parsing TradeModel: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool hasOffers() {
    return offeredCards.isNotEmpty;
  }

   factory TradeModel.empty() {
    return TradeModel(
      id: '',
      offeredCards: [],
      status: TradeStatus.PENDING,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      senderId: '',
      isOpenTrade: true,
      coinsOffered: 0,
      sender: UserModel.empty(),
    );
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

  factory UserModel.empty() {
    return UserModel(
      id: '',
      name: '',
      image: null,
      level: 0,
    );
}
}
