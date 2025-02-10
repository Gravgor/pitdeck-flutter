import 'package:flutter/src/widgets/icon_data.dart';

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String type;
  final String rarity;
  final DateTime? earnedAt;



  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.rarity,
    this.earnedAt,
  });


  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      type: json['type'],
      rarity: json['rarity'],
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])

          : null,
    );
  }

  IconData? get icon => null;
}
