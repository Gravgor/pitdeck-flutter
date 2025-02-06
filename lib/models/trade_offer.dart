import 'package:pitdeck/models/card.dart';

enum TradeOfferStatus { pending, accepted, declined, cancelled }

class OfferUserModel {
  final String id;
  final String name;
  final String? image;
  final int level;

  OfferUserModel({
    required this.id,
    required this.name,
    this.image,
    required this.level,
  });

  factory OfferUserModel.fromJson(Map<String, dynamic> json) {
    return OfferUserModel(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      level: json['level'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'level': level,
    };
  }
}

class TradeOfferModel {
  final String id;
  final String tradeId;
  final String userId;
  final int coins;
  final String? note;
  final TradeOfferStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final List<CardModel> offeredCards;
  final OfferUserModel user;

  TradeOfferModel({
    required this.id,
    required this.tradeId,
    required this.userId,
    required this.coins,
    this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    required this.offeredCards,
    required this.user,
  });

  factory TradeOfferModel.fromJson(Map<String, dynamic> json) {
    return TradeOfferModel(
      id: json['id'],
      tradeId: json['tradeId'],
      userId: json['userId'],
      coins: json['coins'] ?? 0,
      note: json['note'],
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      offeredCards: (json['offeredCards'] as List)
          .map((card) => CardModel.fromJson(card))
          .toList(),
      user: OfferUserModel.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeId': tradeId,
      'userId': userId,
      'coins': coins,
      'note': note,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'offeredCards': offeredCards.map((card) => card.toJson()).toList(),
      'user': user.toJson(),
    };
  }

  static TradeOfferStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TradeOfferStatus.pending;
      case 'ACCEPTED':
        return TradeOfferStatus.accepted;
      case 'DECLINED':
        return TradeOfferStatus.declined;
      case 'CANCELLED':
        return TradeOfferStatus.cancelled;
      default:
        return TradeOfferStatus.pending;
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

  bool get isPending => status == TradeOfferStatus.pending;
  bool get isAccepted => status == TradeOfferStatus.accepted;
  bool get isDeclined => status == TradeOfferStatus.declined;
  bool get isCancelled => status == TradeOfferStatus.cancelled;

  String get statusText {
    switch (status) {
      case TradeOfferStatus.pending:
        return 'Pending';
      case TradeOfferStatus.accepted:
        return 'Accepted';
      case TradeOfferStatus.declined:
        return 'Declined';
      case TradeOfferStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  TradeOfferModel copyWith({
    String? id,
    String? tradeId,
    String? userId,
    int? coins,
    String? note,
    TradeOfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    List<CardModel>? offeredCards,
    OfferUserModel? user,
  }) {
    return TradeOfferModel(
      id: id ?? this.id,
      tradeId: tradeId ?? this.tradeId,
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      note: note ?? this.note,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      offeredCards: offeredCards ?? this.offeredCards,
      user: user ?? this.user,
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
    final coinText = coins > 0 ? ' + $coins coins' : '';
    return '$cardText$coinText';
  }
}
