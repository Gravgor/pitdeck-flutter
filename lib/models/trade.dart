import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/models/user.dart';

enum TradeStatus { PENDING, ACCEPTED, REJECTED, CANCELLED, EXPIRED }

class TradeModel {
  final String id;
  final User sender;
  final String senderId;
  final TradeStatus status;
  final bool isOpenTrade;
  final String? note;
  final DateTime? expiresAt;
  final List<CardDetailModel> offeredCards;
  final int coinsOffered;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<User> receivers;
  final List<CardDetailModel> wantedCards;

  TradeModel({
    required this.id,
    required this.sender,
    required this.senderId,
    required this.status,
    required this.isOpenTrade,
    this.note,
    this.expiresAt,
    required this.offeredCards,
    required this.coinsOffered,
    required this.createdAt,
    required this.updatedAt,
    List<User>? receivers,
    List<CardDetailModel>? wantedCards,
  })  : receivers = receivers ?? [],
        wantedCards = wantedCards ?? [];

  factory TradeModel.fromJson(Map<String, dynamic> json) {
    return TradeModel(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      senderId: json['senderId'],
      status: TradeStatus.values.firstWhere(
        (e) => e.toString() == 'TradeStatus.${json['status']}',
        orElse: () => TradeStatus.PENDING,
      ),
      isOpenTrade: json['isOpenTrade'] ?? false,
      note: json['note'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      offeredCards: (json['offeredCards'] as List<dynamic>)
          .map((card) => CardDetailModel.fromJson(card))
          .toList(),
      coinsOffered: json['coinsOffered'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      receivers: json['receivers'] != null
          ? (json['receivers'] as List<dynamic>)
              .map((user) => User.fromJson(user))
              .toList()
          : [],
      wantedCards: json['wantedCards'] != null
          ? (json['wantedCards'] as List<dynamic>)
              .map((card) => CardDetailModel.fromJson(card))
              .toList()
          : [],
    );
  }
}
