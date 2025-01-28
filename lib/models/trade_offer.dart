import 'package:pitdeck/models/card.dart';
import 'package:pitdeck/models/user.dart';

enum TradeOfferStatus { PENDING, ACCEPTED, DECLINED, CANCELLED }

class TradeOfferModel {
  final String id;
  final String tradeId;
  final User sender;
  final List<CardModel> offeredCards;
  final int coinsOffered;
  final String? note;
  final DateTime createdAt;
  final TradeOfferStatus status;

  TradeOfferModel({
    required this.id,
    required this.tradeId,
    required this.sender,
    required this.offeredCards,
    required this.coinsOffered,
    this.note,
    required this.createdAt,
    required this.status,
  });

  factory TradeOfferModel.fromJson(Map<String, dynamic> json) {
    return TradeOfferModel(
      id: json['_id'] ?? json['id'],
      tradeId: json['tradeId'],
      sender: User.fromJson(json['sender']),
      offeredCards: (json['offeredCards'] as List)
          .map((card) => CardModel.fromJson(card))
          .toList(),
      coinsOffered: json['coinsOffered'] ?? 0,
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      status: _parseStatus(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeId': tradeId,
      'sender': sender.toJson(),
      'offeredCards': offeredCards.map((card) => card.toJson()).toList(),
      'coinsOffered': coinsOffered,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  static TradeOfferStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TradeOfferStatus.PENDING;
      case 'ACCEPTED':
        return TradeOfferStatus.ACCEPTED;
      case 'DECLINED':
        return TradeOfferStatus.DECLINED;
      case 'CANCELLED':
        return TradeOfferStatus.CANCELLED;
      default:
        return TradeOfferStatus.PENDING;
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get isPending => status == TradeOfferStatus.PENDING;
  bool get isAccepted => status == TradeOfferStatus.ACCEPTED;
  bool get isDeclined => status == TradeOfferStatus.DECLINED;
  bool get isCancelled => status == TradeOfferStatus.CANCELLED;

  String get statusText {
    switch (status) {
      case TradeOfferStatus.PENDING:
        return 'Pending';
      case TradeOfferStatus.ACCEPTED:
        return 'Accepted';
      case TradeOfferStatus.DECLINED:
        return 'Declined';
      case TradeOfferStatus.CANCELLED:
        return 'Cancelled';
    }
  }

  TradeOfferModel copyWith({
    String? id,
    String? tradeId,
    User? sender,
    List<CardModel>? offeredCards,
    int? coinsOffered,
    String? note,
    DateTime? createdAt,
    TradeOfferStatus? status,
  }) {
    return TradeOfferModel(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      sender: sender ?? this.sender,
      offeredCards: offeredCards ?? this.offeredCards,
      coinsOffered: coinsOffered ?? this.coinsOffered,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeOfferModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;


  bool hasCard(String cardId) {
    return offeredCards.any((card) => card.id == cardId);
  }

  int get cardCount => offeredCards.length;


  String get summary {
    final cardText = cardCount == 1 ? '1 card' : '$cardCount cards';
    final coinText = coinsOffered > 0 ? ' + $coinsOffered coins' : '';
    return '$cardText$coinText';
  }
}
