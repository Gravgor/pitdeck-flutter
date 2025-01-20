class Pack {
  final String id;
  final String name;
  final String description;
  final int price;
  final String type;
  final String imageUrl;
  final int cardsPerPack;
  final Map<String, int> dropRates;
  final List<String> guaranteedRarities;
  final String? cardTypeFilter;
  final String? seriesFilter;
  final int? yearFilter;
  final String? teamFilter;
  final String? driverFilter;
  final String? eventFilter;
  final bool isLimited;
  final int? limitedQuantity;
  final bool isPromotional;

  Pack({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.imageUrl,
    required this.cardsPerPack,
    required this.dropRates,
    required this.guaranteedRarities,
    this.cardTypeFilter,
    this.seriesFilter,
    this.yearFilter,
    this.teamFilter,
    this.driverFilter,
    this.eventFilter,
    required this.isLimited,
    this.limitedQuantity,
    required this.isPromotional,
  });

  factory Pack.fromJson(Map<String, dynamic> json) {
    return Pack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      type: json['type'],
      imageUrl: json['imageUrl'],
      cardsPerPack: json['cardsPerPack'],
      dropRates: Map<String, int>.from(json['dropRates']),
      guaranteedRarities: List<String>.from(json['guaranteedRarities']),
      cardTypeFilter: json['cardTypeFilter'],
      seriesFilter: json['seriesFilter'],
      yearFilter: json['yearFilter'],
      teamFilter: json['teamFilter'],
      driverFilter: json['driverFilter'],
      eventFilter: json['eventFilter'],
      isLimited: json['isLimited'],
      limitedQuantity: json['limitedQuantity'],
      isPromotional: json['isPromotional'],
    );
  }
}
