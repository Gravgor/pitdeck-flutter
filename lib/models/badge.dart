class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}
