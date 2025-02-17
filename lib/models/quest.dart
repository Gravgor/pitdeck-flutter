enum QuestCategory { BASIC, PIT_CREW, GRAND_PRIX, CHAMPIONS_LEAGUE }

enum QuestStatus { ACTIVE, COMPLETED, CLAIMED, LOCKED }

class QuestReward {
  final int? coins;
  final String? badge;
  final String? visualEffect;
  final List<Map<String, dynamic>>? cards;
  final Map<String, dynamic>? pack;

  QuestReward({
    this.coins,
    this.badge,
    this.visualEffect,
    this.cards,
    this.pack,
  });

  factory QuestReward.fromJson(Map<String, dynamic> json) {
    return QuestReward(
      coins: json['coins'],
      badge: json['badge'],
      visualEffect: json['visualEffect'],
      cards: json['cards']?.cast<Map<String, dynamic>>(),
      pack: json['pack'],
    );
  }
}

class Quest {
  final String id;
  final String type;
  final QuestCategory category;
  final String title;
  final String description;
  final QuestStatus status;
  final int? minLevel;
  final int? maxLevel;
  final Map<String, dynamic> requirements;
  final QuestReward rewards;
  final DateTime startDate;
  final DateTime? endDate;

  Quest({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    this.minLevel,
    this.maxLevel,
    required this.requirements,
    required this.rewards,
    required this.startDate,
    this.endDate,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      type: json['type'],
      category: QuestCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      title: json['title'],
      description: json['description'],
      status: QuestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      minLevel: json['minLevel'],
      maxLevel: json['maxLevel'],
      requirements: json['requirements'],
      rewards: QuestReward.fromJson(json['rewards']),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
    );
  }

  String getProgressText() {
    if (requirements.containsKey('count')) {
      return '0/${requirements['count']}';
    } else if (requirements.containsKey('locations')) {
      return '0/${requirements['locations']}';
    } else if (requirements.containsKey('trades')) {
      return '0/${requirements['trades']}';
    } else if (requirements.containsKey('categories')) {
      return '0/${requirements['categories']}';
    } else if (requirements.containsKey('circuits')) {
      return '0/${requirements['circuits']}';
    } else if (requirements.containsKey('teams')) {
      return '0/${requirements['teams']}';
    } else if (requirements.containsKey('drops')) {
      return '0/${requirements['drops']}';
    } else if (requirements.containsKey('purchases')) {
      return '0/${requirements['purchases']}';
    } else if (requirements.containsKey('cardsPerTeam')) {
      return '0/${requirements['cardsPerTeam']}';
    } else if (requirements.containsKey('totalCircuits')) {
      return '0/${requirements['totalCircuits']}';
    }
    return '0/0';
  }

  double getProgress() {
    // Similar logic to getProgressText but returns a double between 0 and 1
    return 0.0; // Default for now, implement actual progress tracking
  }
}
