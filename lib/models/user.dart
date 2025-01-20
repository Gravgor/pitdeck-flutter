import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class User {
  final String id;
  final String? name;
  final String? email;
  final DateTime? emailVerified;
  final String? image;
  final int coins;
  final int level;
  final int xp;
  final int totalXp;
  final String? role;
  final String bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastActive;
  final String token;

  User({
    required this.id,
    this.name,
    this.email,
    this.emailVerified,
    this.image,
    this.coins = 1000,
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.bio = '',
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.lastActive,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerified: json['emailVerified'] != null
          ? DateTime.parse(json['emailVerified'])
          : null,
      image: json['image'],
      coins: json['coins'] ?? 1000,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      totalXp: json['totalXp'] ?? 0,
      bio: json['bio'] ?? '',
      role: json['role'] ?? 'user',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'])
          : null,
      token: token ?? json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emailVerified': emailVerified?.toIso8601String(),
      'image': image,
      'coins': coins,
      'level': level,
      'xp': xp,
      'totalXp': totalXp,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
      'token': token,
    };
  }
}
