class CardModel {
  final String id;
  final String name;
  final String type;
  final String series;
  final String serialNumber;
  final String imageUrl;
  final String rarity;
  final bool isForSale;

  CardModel({
    required this.id,
    required this.name,
    required this.type,
    required this.series,
    required this.serialNumber,
    required this.imageUrl,
    required this.rarity,
    required this.isForSale,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      series: json['series'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rarity: json['rarity'] ?? '',
      isForSale: json['isForSale'] ?? false,
    );
  }
}

class CardDetailModel {
  final String id;
  final String name;
  final String type;
  final String rarity;
  final String imageUrl;
  final String description;
  final String edition;
  final String serialNumber;
  final Map<String, dynamic> stats;
  final String series;
  final int year;
  final bool isExclusive;
  final bool isForSale;
  final bool isForTrade;

  CardDetailModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.imageUrl,
    required this.description,
    required this.edition,
    required this.serialNumber,
    required this.stats,
    required this.series,
    required this.year,
    required this.isExclusive,
    required this.isForSale,
    required this.isForTrade,
  });

  factory CardDetailModel.fromJson(Map<String, dynamic> json) {
    return CardDetailModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      rarity: json['rarity'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      edition: json['edition'],
      serialNumber: json['serialNumber'],
      stats: json['stats'] ?? {},
      series: json['series'],
      year: json['year'],
      isExclusive: json['isExclusive'] ?? false,
      isForSale: json['isForSale'] ?? false,
      isForTrade: json['isForTrade'] ?? false,
    );
  }
}
