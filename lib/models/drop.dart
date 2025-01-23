enum DropType { STANDARD, SPECIAL, EVENT, CARD }

enum DropRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

class DropModel {
  final String id;
  final DropType type;
  final DropRarity rarity;
  final double latitude;
  final double longitude;
  final String? circuitId;
  final DateTime expiresAt;
  final String? userId;
  final bool isActive;
  final DateTime createdAt;
  final List<DropReward> rewards;
  final String? annotationId;

  DropModel({
    required this.id,
    required this.type,
    required this.rarity,
    required this.latitude,
    required this.longitude,
    this.circuitId,
    required this.expiresAt,
    this.userId,
    required this.isActive,
    required this.createdAt,
    required this.rewards,
    this.annotationId,
  });

  factory DropModel.fromJson(Map<String, dynamic> json) {
    return DropModel(
      id: json['id'],
      type: DropType.values.firstWhere(
        (e) => e.toString() == 'DropType.${json['type']}',
        orElse: () => DropType.STANDARD,
      ),
      rarity: DropRarity.values.firstWhere(
        (e) => e.toString() == 'DropRarity.${json['rarity']}',
        orElse: () => DropRarity.COMMON,
      ),
      latitude: json['latitude'],
      longitude: json['longitude'],
      circuitId: json['circuitId'],
      expiresAt: DateTime.parse(json['expiresAt']),
      userId: json['userId'],
      isActive: json['isActive'],
      createdAt: DateTime.parse(json['createdAt']),
      rewards: (json['rewards'] as List<dynamic>)
          .map((reward) => DropReward.fromJson(reward))
          .toList(),
      annotationId: json['annotationId'],
    );
  }

  @override
  String toString() {
    return 'Drop(id: $id, type: $type, rarity: $rarity, rewards: ${rewards.length}, annotationId: $annotationId)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'rarity': rarity,
      // ... other properties
    };
  }
}

class DropReward {
  final String id;
  final String type;
  final int amount;
  final String? cardId;
  final String dropId;
  final DateTime createdAt;
  final DateTime updatedAt;

  DropReward({
    required this.id,
    required this.type,
    required this.amount,
    this.cardId,
    required this.dropId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DropReward.fromJson(Map<String, dynamic> json) {
    return DropReward(
      id: json['id'],
      type: json['type'],
      amount: json['amount'],
      cardId: json['cardId'],
      dropId: json['dropId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
