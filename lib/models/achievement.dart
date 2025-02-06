class Achievement {
  final String title;
  final String description;
  final String type;
  final String imageUrl;
  final int requirement;
  final int xpReward;

  Achievement({
    required this.title,
    required this.description,
    required this.type,
    required this.imageUrl,
    required this.requirement,
    required this.xpReward,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      title: json['title'],
      description: json['description'],
      type: json['type'],
      imageUrl: json['imageUrl'],
      requirement: json['requirement'],
      xpReward: json['xpReward'],
    );
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final int progress;
  final DateTime? unlockedAt;
  final Achievement achievement;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.progress,
    this.unlockedAt,
    required this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['userId'],
      achievementId: json['achievementId'],
      progress: json['progress'],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
      achievement: Achievement.fromJson(json['achievement']),
    );
  }
}
