// models/achievement_models.dart
import 'package:flutter/material.dart';

enum AchievementCategory {
  score,
  lines,
  combo,
  level,
  gameplay,
  special,
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int targetValue;
  final int pointsReward;
  final bool isUnlocked;
  final int currentProgress;
  final DateTime? unlockedAt;
  final bool isSecret;
  final String? secretHint;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.targetValue,
    required this.pointsReward,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.unlockedAt,
    this.isSecret = false,
    this.secretHint,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? targetValue,
    int? pointsReward,
    bool? isUnlocked,
    int? currentProgress,
    DateTime? unlockedAt,
    bool? isSecret,
    String? secretHint,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      targetValue: targetValue ?? this.targetValue,
      pointsReward: pointsReward ?? this.pointsReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isSecret: isSecret ?? this.isSecret,
      secretHint: secretHint ?? this.secretHint,
    );
  }

  double get progressPercentage {
    if (targetValue == 0) return isUnlocked ? 1.0 : 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  Color get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey.shade400;
      case AchievementRarity.rare:
        return Colors.blue.shade400;
      case AchievementRarity.epic:
        return Colors.purple.shade400;
      case AchievementRarity.legendary:
        return Colors.amber.shade400;
    }
  }

  Color get categoryColor {
    switch (category) {
      case AchievementCategory.score:
        return Colors.green;
      case AchievementCategory.lines:
        return Colors.blue;
      case AchievementCategory.combo:
        return Colors.orange;
      case AchievementCategory.level:
        return Colors.purple;
      case AchievementCategory.gameplay:
        return Colors.cyan;
      case AchievementCategory.special:
        return Colors.pink;
    }
  }

  String get rarityName {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get categoryName {
    switch (category) {
      case AchievementCategory.score:
        return 'Score';
      case AchievementCategory.lines:
        return 'Lines';
      case AchievementCategory.combo:
        return 'Combo';
      case AchievementCategory.level:
        return 'Level';
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.special:
        return 'Special';
    }
  }

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'currentProgress': currentProgress,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
    };
  }

  static Achievement fromStoredData(Achievement template, Map<String, dynamic> data) {
    return template.copyWith(
      isUnlocked: data['isUnlocked'] ?? false,
      currentProgress: data['currentProgress'] ?? 0,
      unlockedAt: data['unlockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['unlockedAt'])
          : null,
    );
  }
}

// Pre-defined achievements
class Achievements {
  static final List<Achievement> all = [
    // Score Achievements
    Achievement(
      id: 'first_score',
      title: 'First Points',
      description: 'Score your first 100 points',
      icon: Icons.stars,
      category: AchievementCategory.score,
      rarity: AchievementRarity.common,
      targetValue: 100,
      pointsReward: 50,
    ),
    Achievement(
      id: 'score_1k',
      title: 'Rising Star',
      description: 'Reach 5,000 points in a single game',
      icon: Icons.trending_up,
      category: AchievementCategory.score,
      rarity: AchievementRarity.common,
      targetValue: 5000,
      pointsReward: 100,
    ),
    Achievement(
      id: 'score_5k',
      title: 'Skilled Player',
      description: 'Reach 25,000 points in a single game',
      icon: Icons.emoji_events,
      category: AchievementCategory.score,
      rarity: AchievementRarity.rare,
      targetValue: 25000,
      pointsReward: 250,
    ),
    Achievement(
      id: 'score_10k',
      title: 'Point Master',
      description: 'Reach 100,000 points in a single game',
      icon: Icons.workspace_premium,
      category: AchievementCategory.score,
      rarity: AchievementRarity.epic,
      targetValue: 100000,
      pointsReward: 500,
    ),
    Achievement(
      id: 'score_25k',
      title: 'Score Legend',
      description: 'Reach 1,000,000 points in a single game',
      icon: Icons.diamond,
      category: AchievementCategory.score,
      rarity: AchievementRarity.legendary,
      targetValue: 1000000,
      pointsReward: 1000,
    ),

    // Line Clear Achievements
    Achievement(
      id: 'first_line',
      title: 'First Clear',
      description: 'Clear your first line',
      icon: Icons.view_headline,
      category: AchievementCategory.lines,
      rarity: AchievementRarity.common,
      targetValue: 1,
      pointsReward: 25,
    ),
    Achievement(
      id: 'lines_10',
      title: 'Line Clearer',
      description: 'Clear 100 lines total',
      icon: Icons.clear_all,
      category: AchievementCategory.lines,
      rarity: AchievementRarity.common,
      targetValue: 100,
      pointsReward: 100,
    ),
    Achievement(
      id: 'lines_50',
      title: 'Demolition Expert',
      description: 'Clear 1,000 lines total',
      icon: Icons.construction,
      category: AchievementCategory.lines,
      rarity: AchievementRarity.rare,
      targetValue: 1000,
      pointsReward: 250,
    ),
    Achievement(
      id: 'lines_100',
      title: 'Line Legend',
      description: 'Clear 5,000 lines total',
      icon: Icons.auto_awesome,
      category: AchievementCategory.lines,
      rarity: AchievementRarity.epic,
      targetValue: 5000,
      pointsReward: 500,
    ),
    Achievement(
      id: 'simultaneous_clear',
      title: 'Double Trouble',
      description: 'Clear a row and column simultaneously',
      icon: Icons.add,
      category: AchievementCategory.lines,
      rarity: AchievementRarity.rare,
      targetValue: 1,
      pointsReward: 300,
    ),

    // Combo Achievements
    Achievement(
      id: 'first_combo',
      title: 'Chain Reaction',
      description: 'Get your first combo (2x)',
      icon: Icons.link,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.common,
      targetValue: 2,
      pointsReward: 100,
    ),
    Achievement(
      id: 'combo_5',
      title: 'Combo Master',
      description: 'Achieve a 5x combo',
      icon: Icons.whatshot,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.rare,
      targetValue: 5,
      pointsReward: 300,
    ),
    Achievement(
      id: 'combo_10',
      title: 'Chain Lightning',
      description: 'Achieve an 8x combo',
      icon: Icons.flash_on,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.epic,
      targetValue: 8,
      pointsReward: 750,
    ),
    Achievement(
      id: 'combo_15',
      title: 'Cascade God',
      description: 'Achieve a 9x combo',
      icon: Icons.bolt,
      category: AchievementCategory.combo,
      rarity: AchievementRarity.legendary,
      targetValue: 9,
      pointsReward: 1500,
    ),

    // Level Achievements
    Achievement(
      id: 'level_5',
      title: 'Getting Started',
      description: 'Reach level 5',
      icon: Icons.grade,
      category: AchievementCategory.level,
      rarity: AchievementRarity.common,
      targetValue: 5,
      pointsReward: 150,
    ),
    Achievement(
      id: 'level_10',
      title: 'Dedicated Player',
      description: 'Reach level 10',
      icon: Icons.star,
      category: AchievementCategory.level,
      rarity: AchievementRarity.rare,
      targetValue: 10,
      pointsReward: 400,
    ),
    Achievement(
      id: 'level_20',
      title: 'Expert',
      description: 'Reach level 20',
      icon: Icons.star_border,
      category: AchievementCategory.level,
      rarity: AchievementRarity.epic,
      targetValue: 20,
      pointsReward: 800,
    ),

    // Gameplay Achievements
    Achievement(
      id: 'games_10',
      title: 'Regular Player',
      description: 'Play 10 games',
      icon: Icons.videogame_asset,
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.common,
      targetValue: 10,
      pointsReward: 200,
    ),
    Achievement(
      id: 'games_50',
      title: 'Devoted Gamer',
      description: 'Play 50 games',
      icon: Icons.sports_esports,
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.rare,
      targetValue: 50,
      pointsReward: 500,
    ),
    Achievement(
      id: 'perfect_placement',
      title: 'Perfect Fit',
      description: 'Place a piece that perfectly fills empty spaces',
      icon: Icons.fit_screen,
      category: AchievementCategory.gameplay,
      rarity: AchievementRarity.rare,
      targetValue: 1,
      pointsReward: 250,
      isSecret: true,
      secretHint: 'Find the perfect spot...',
    ),

    // Special Achievements
    Achievement(
      id: 'tutorial_complete',
      title: 'Student',
      description: 'Complete the tutorial',
      icon: Icons.school,
      category: AchievementCategory.special,
      rarity: AchievementRarity.common,
      targetValue: 1,
      pointsReward: 100,
    ),
    Achievement(
      id: 'gravity_master',
      title: 'Gravity Master',
      description: 'Trigger gravity 25 times in one game',
      icon: Icons.vertical_align_bottom,
      category: AchievementCategory.special,
      rarity: AchievementRarity.epic,
      targetValue: 25,
      pointsReward: 750,
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Place 10 pieces in under 30 seconds',
      icon: Icons.speed,
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      targetValue: 10,
      pointsReward: 1000,
      isSecret: true,
      secretHint: 'Sometimes speed beats strategy...',
    ),
    Achievement(
      id: 'comeback_king',
      title: 'Comeback King',
      description: 'Use a rewarded ad to continue and then beat your previous high score',
      icon: Icons.trending_up,
      category: AchievementCategory.special,
      rarity: AchievementRarity.legendary,
      targetValue: 1,
      pointsReward: 1500,
      isSecret: true,
      secretHint: 'Sometimes a second chance is all you need...',
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((achievement) => achievement.category == category).toList();
  }

  static List<Achievement> getByRarity(AchievementRarity rarity) {
    return all.where((achievement) => achievement.rarity == rarity).toList();
  }
}