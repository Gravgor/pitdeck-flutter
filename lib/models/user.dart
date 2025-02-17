import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class UserLocation {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
  final DateTime createdAt;

  UserLocation({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
    required this.createdAt,
  });

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      id: json['id'],
      userId: json['userId'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

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
  final bool isPremium;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastActive;
  final String? backgroundImage;
  final bool needUsernameSetup;
  final String league;
  final int leaguePosition;
  final String token;
  final List<UserLocation> locations;


  User({
    required this.id,
    this.name,
    this.email,
    this.emailVerified,
    this.image, 
    this.backgroundImage,
    this.coins = 1000,
    this.level = 1,
    this.xp = 0,
    this.totalXp = 0,
    this.bio = '',
    this.isPremium = false,
    this.needUsernameSetup = false,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
    this.lastLogin,
    this.lastActive,
    required this.token,
    this.locations = const [],
    required this.league,
    required this.leaguePosition,
    });

  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerified: json['emailVerified'] != null
          ? DateTime.parse(json['emailVerified'].toString())
          : null,
      image: json['image'] ?? '',
      backgroundImage: json['backgroundImage'] ?? '',
      coins: json['coins'] ?? 1000,
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      totalXp: json['totalXp'] ?? 0,
      bio: json['bio'] ?? '',
      role: json['role'] ?? 'user',
      isPremium: json['isPremium'] ?? false,
      needUsernameSetup: json['needUsernameSetup'] ?? false,
      league: json['league'] ?? 'ROOKIE',
      leaguePosition: json['leaguePosition'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'].toString())
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'].toString())
          : null,
      token: token ?? '',
      locations: (json['locations'] as List<dynamic>?)
              ?.map((loc) => UserLocation.fromJson(loc))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emailVerified': emailVerified?.toIso8601String(),
      'image': image,
      'backgroundImage': backgroundImage,
      'coins': coins,
      'level': level,
      'xp': xp,
      'totalXp': totalXp,
      'bio': bio,
      'isPremium': isPremium,
      'leaguePosition': leaguePosition,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),

      'lastActive': lastActive?.toIso8601String(),
      'token': token,
      'locations': locations.map((loc) => loc.toJson()).toList(),
    };
  }

  User copyWith({
    String? name,
    String? image,
    bool? isPremium,
    int? coins,
    int? level,
    String? bio,
    String? token,
    bool? needUsernameSetup,
    String? league,
    int? leaguePosition,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      image: image ?? this.image,
      isPremium: isPremium ?? this.isPremium,
      bio: bio ?? this.bio,
      coins: coins ?? this.coins,
      level: level ?? this.level,
      token: token ?? this.token,
      needUsernameSetup: needUsernameSetup ?? this.needUsernameSetup,
      league: league ?? this.league,
      leaguePosition: leaguePosition ?? this.leaguePosition,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  UserLocation? get lastLocation => locations.isNotEmpty
      ? locations.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b)
      : null;
}
