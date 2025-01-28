class FavoriteModel {
  final String id;
  final String type; // 'DRIVER', 'TEAM', 'SERIES'
  final String name;
  final String imageUrl;
  final bool isLocked;
  final bool requiresPremium;

  FavoriteModel({
    required this.id,
    required this.type,
    required this.name,
    required this.imageUrl,
    this.isLocked = true,
    this.requiresPremium = false,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['_id'] ?? json['id'],
      type: json['type'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      isLocked: json['isLocked'] ?? true,
      requiresPremium: json['requiresPremium'] ?? false,
    );
  }
}
