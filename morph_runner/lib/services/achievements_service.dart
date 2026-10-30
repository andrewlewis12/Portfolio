import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/game_screen.dart';
import '../utils/game_data.dart';
import 'dart:convert';

import '../utils/rank_system.dart';

enum AchievementCategory {
  gameplay,
  scoring,
  mastery,
  progression,
  special,
  social,
  rank
}

enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int maxProgress;
  final int rewardPoints;
  final bool isSecret;
  final String? secretHint;
  
  int currentProgress;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.rarity,
    this.maxProgress = 1,
    this.rewardPoints = 10,
    this.isSecret = false,
    this.secretHint,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  bool get isCompleted => currentProgress >= maxProgress;
  double get progressPercentage => maxProgress > 0 ? (currentProgress / maxProgress).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      category: template.category,
      rarity: template.rarity,
      maxProgress: template.maxProgress,
      rewardPoints: template.rewardPoints,
      isSecret: template.isSecret,
      secretHint: template.secretHint,
      currentProgress: json['currentProgress'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['unlockedAt'])
          : null,
    );
  }
}

class AchievementNotification {
  final Achievement achievement;
  final DateTime timestamp;
  bool isNew;

  AchievementNotification({
    required this.achievement,
    required this.timestamp,
    this.isNew = true,
  });
}

class AchievementsService extends ChangeNotifier {
  static AchievementsService? _instance;
  static AchievementsService get instance => _instance ??= AchievementsService._();
  AchievementsService._();

  final Map<String, Achievement> _achievements = {};
  final List<AchievementNotification> _recentNotifications = [];
  bool _isInitialized = false;
  int _totalAchievementPoints = 0;

  // Getters
  List<Achievement> get allAchievements => _achievements.values.toList();
  List<Achievement> get unlockedAchievements => 
      _achievements.values.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements => 
      _achievements.values.where((a) => !a.isUnlocked).toList();
  List<AchievementNotification> get recentNotifications => 
      List.unmodifiable(_recentNotifications);
  int get totalAchievementPoints => _totalAchievementPoints;
  int get unlockedCount => unlockedAchievements.length;
  int get totalCount => _achievements.length;
  double get completionPercentage => totalCount > 0 ? (unlockedCount / totalCount) : 0.0;

  /// Initialize the achievements system
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _initializeAchievements();
    await _loadProgress();
    _calculateTotalPoints();
    _isInitialized = true;
    
    if (kDebugMode) {
      print('AchievementsService initialized with ${_achievements.length} achievements');
    }
  }

  /// Define all achievements
  void _initializeAchievements() {
    final achievements = [
      // Gameplay Achievements
      Achievement(
        id: 'first_steps',
        title: 'First Steps',
        description: 'Complete your first game',
        icon: '🎮',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.common,
        rewardPoints: 10,
      ),
      
      Achievement(
        id: 'shape_shifter',
        title: 'Shape Shifter',
        description: 'Morph shapes 100 times',
        icon: '🔄',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.common,
        maxProgress: 100,
        rewardPoints: 25,
      ),

      Achievement(
        id: 'dash_master',
        title: 'Dash Master',
        description: 'Use dash ability 500 times',
        icon: '⚡',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.uncommon,
        maxProgress: 500,
        rewardPoints: 50,
      ),

      Achievement(
        id: 'marathon_runner',
        title: 'Marathon Runner',
        description: 'Play for 60 minutes total',
        icon: '🏃',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.uncommon,
        maxProgress: 3600, // 60 minutes in seconds
        rewardPoints: 75,
      ),

      Achievement(
        id: 'dedicated_player',
        title: 'Dedicated Player',
        description: 'Play 100 games',
        icon: '🎯',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.rare,
        maxProgress: 100,
        rewardPoints: 100,
      ),

      Achievement(
        id: 'first_powerup',
        title: 'Power Player',
        description: 'Collect your first powerup',
        icon: '⚡',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.common,
        rewardPoints: 15,
      ),

      Achievement(
        id: 'powerup_collector',
        title: 'Powerup Collector',
        description: 'Collect 50 powerups',
        icon: '🔋',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.uncommon,
        maxProgress: 50,
        rewardPoints: 50,
      ),

      Achievement(
        id: 'powerup_master',
        title: 'Powerup Master',
        description: 'Collect 200 powerups',
        icon: '💫',
        category: AchievementCategory.gameplay,
        rarity: AchievementRarity.rare,
        maxProgress: 200,
        rewardPoints: 100,
      ),

      // Scoring Achievements
      Achievement(
        id: 'first_thousand',
        title: 'First Thousand',
        description: 'Score 1,000 points in a single game',
        icon: '🔥',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.common,
        rewardPoints: 20,
      ),

      Achievement(
        id: 'ten_grand',
        title: '10 Grand',
        description: 'Score 10,000 points in a single game',
        icon: '💫',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.uncommon,
        rewardPoints: 50,
      ),

      Achievement(
        id: 'fifty_thousand_club',
        title: '50 Thousand Club',
        description: 'Score 50,000 points in a single game',
        icon: '⭐',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.rare,
        rewardPoints: 100,
      ),

      Achievement(
        id: 'score_legend',
        title: 'Score Legend',
        description: 'Score 100,000 points in a single game',
        icon: '👑',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.epic,
        rewardPoints: 250,
      ),

      Achievement(
        id: 'transcendent',
        title: 'Transcendent',
        description: 'Score 1,000,000 points in a single game',
        icon: '🌟',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.legendary,
        rewardPoints: 500,
      ),

      // Mastery Achievements
      Achievement(
        id: 'perfect_timing',
        title: 'Perfect Timing',
        description: 'Pass through 50 obstacles without dashing',
        icon: '🎯',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 50,
        rewardPoints: 75,
      ),

      Achievement(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Reach 5x game speed',
        icon: '🚀',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.rare,
        rewardPoints: 100,
      ),

      Achievement(
        id: 'untouchable',
        title: 'Untouchable',
        description: 'Don\'t die to an X obstacle in a single game with 250+ obstacles',
        icon: '🛡️',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.epic,
        rewardPoints: 200,
      ),

      Achievement(
        id: 'shape_master',
        title: 'Shape Master',
        description: 'Use each shape type at least 50 times',
        icon: '🔮',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.rare,
        maxProgress: 8, // Number of shape types
        rewardPoints: 150,
      ),

      Achievement(
        id: 'slow_mo_expert',
        title: 'Slow Mo Expert',
        description: 'Use slow motion powerup 25 times',
        icon: '🐌',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 25,
        rewardPoints: 40,
      ),

      Achievement(
        id: 'score_booster',
        title: 'Score Booster',
        description: 'Use score multiplier powerup 30 times',
        icon: '⭐',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 30,
        rewardPoints: 45,
      ),

      Achievement(
        id: 'untouchable_shield',
        title: 'Untouchable',
        description: 'Use invincibility powerup 20 times',
        icon: '🛡️',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 20,
        rewardPoints: 60,
      ),

      Achievement(
        id: 'speed_demon_powerup',
        title: 'Turbo Charged',
        description: 'Use speed boost powerup 15 times',
        icon: '🚀',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 15,
        rewardPoints: 35,
      ),

      Achievement(
        id: 'shape_locker',
        title: 'Shape Locker',
        description: 'Use shape freeze powerup 25 times',
        icon: '🔒',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.uncommon,
        maxProgress: 25,
        rewardPoints: 40,
      ),

      Achievement(
        id: 'powerup_combo',
        title: 'Combo Master',
        description: 'Have 3 powerups active at the same time',
        icon: '🌈',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.rare,
        rewardPoints: 80,
      ),

      Achievement(
        id: 'invincible_run',
        title: 'Invincible Run',
        description: 'Pass 50 obstacles while invincible',
        icon: '💚',
        category: AchievementCategory.mastery,
        rarity: AchievementRarity.rare,
        maxProgress: 50,
        rewardPoints: 100,
      ),

      // Progression Achievements
      Achievement(
        id: 'getting_started',
        title: 'Getting Started',
        description: 'Complete the tutorial',
        icon: '📚',
        category: AchievementCategory.progression,
        rarity: AchievementRarity.common,
        rewardPoints: 15,
      ),

      Achievement(
        id: 'high_achiever',
        title: 'High Achiever',
        description: 'Beat your high score 5 times',
        icon: '📈',
        category: AchievementCategory.progression,
        rarity: AchievementRarity.uncommon,
        maxProgress: 5,
        rewardPoints: 50,
      ),

      Achievement(
        id: 'consistency',
        title: 'Consistency',
        description: 'Score over 1,000 points in 10 consecutive games',
        icon: '🎪',
        category: AchievementCategory.progression,
        rarity: AchievementRarity.rare,
        maxProgress: 10,
        rewardPoints: 125,
      ),

      Achievement(
        id: 'improvement',
        title: 'Improvement',
        description: 'Increase your high score by 25,000 points',
        icon: '📊',
        category: AchievementCategory.progression,
        rarity: AchievementRarity.epic,
        rewardPoints: 200,
      ),

      Achievement(
        id: 'powered_up_score',
        title: 'Powered Up Score',
        description: 'Score 25,000 points in a single game using powerups',
        icon: '⚡',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.rare,
        rewardPoints: 75,
      ),

      Achievement(
        id: 'multiplier_master',
        title: 'Multiplier Master',
        description: 'Earn 10,000 bonus points from score multipliers in one game',
        icon: '✨',
        category: AchievementCategory.scoring,
        rarity: AchievementRarity.epic,
        rewardPoints: 150,
      ),

      // Special Achievements
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Play a game before between 3 AM and 6 AM',
        icon: '🌅',
        category: AchievementCategory.special,
        rarity: AchievementRarity.uncommon,
        rewardPoints: 30,
      ),

      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Play a game between 3 AM and midnight',
        icon: '🌙',
        category: AchievementCategory.special,
        rarity: AchievementRarity.uncommon,
        rewardPoints: 30,
      ),

      Achievement(
        id: 'lucky_seven',
        title: 'Lucky Seven',
        description: 'Have 2 sevens in your score',
        icon: '🍀',
        category: AchievementCategory.special,
        rarity: AchievementRarity.rare,
        rewardPoints: 77,
      ),

      Achievement(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Complete a run without any dashes',
        icon: '💎',
        category: AchievementCategory.special,
        rarity: AchievementRarity.epic,
        isSecret: true,
        secretHint: 'Avoid using dash in an entire game...',
        rewardPoints: 300,
      ),

      Achievement(
        id: 'easter_egg',
        title: 'Easter Egg Hunter',
        description: 'Have a score with "1234" or "4321" in it',
        icon: '🥚',
        category: AchievementCategory.special,
        rarity: AchievementRarity.legendary,
        isSecret: true,
        secretHint: 'There\'s something special about certain numbers...',
        rewardPoints: 1000,
      ),

      Achievement(
        id: 'powerup_hoarder',
        title: 'Powerup Hoarder',
        description: 'Collect 5 powerups in a single game',
        icon: '🎒',
        category: AchievementCategory.special,
        rarity: AchievementRarity.rare,
        maxProgress: 5,
        rewardPoints: 60,
      ),

      Achievement(
        id: 'all_powerups',
        title: 'Full Arsenal',
        description: 'Use every type of powerup in a single game',
        icon: '🎯',
        category: AchievementCategory.special,
        rarity: AchievementRarity.epic,
        rewardPoints: 200,
      ),

      Achievement(
        id: 'no_powerups_run',
        title: 'Purist',
        description: 'Score 5,000 points without collecting any powerups',
        icon: '🎭',
        category: AchievementCategory.special,
        rarity: AchievementRarity.rare,
        isSecret: true,
        secretHint: 'Sometimes less is more...',
        rewardPoints: 120,
      ),

      // Social Achievements (for Leaderboard)
      Achievement(
        id: 'leaderboard_debut',
        title: 'Leaderboard Debut',
        description: 'Submit your first score to the leaderboard',
        icon: '🏆',
        category: AchievementCategory.social,
        rarity: AchievementRarity.common,
        rewardPoints: 25,
      ),

      Achievement(
        id: 'top_performer',
        title: 'Top Performer',
        description: 'Reach the top 10 on the leaderboard',
        icon: '🥇',
        category: AchievementCategory.social,
        rarity: AchievementRarity.epic,
        rewardPoints: 200,
      ),

      Achievement(
        id: 'champion',
        title: 'Champion',
        description: 'Reach #1 on the leaderboard',
        icon: '👑',
        category: AchievementCategory.social,
        rarity: AchievementRarity.legendary,
        rewardPoints: 500,
      ),

      // Rank Achievements
      Achievement(
        id: 'rank_wood',
        title: 'Wooden Warrior',
        description: 'Reach Wood rank',
        icon: '🪵',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.common,
        rewardPoints: 50,
      ),

      Achievement(
        id: 'rank_stone',
        title: 'Stone Solid',
        description: 'Reach Stone rank',
        icon: '🪨',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.common,
        rewardPoints: 75,
      ),

      Achievement(
        id: 'rank_carbon',
        title: 'Carbon Crusader',
        description: 'Reach Carbon rank',
        icon: '⚫',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.uncommon,
        rewardPoints: 100,
      ),

      Achievement(
        id: 'rank_iron',
        title: 'Iron Force',
        description: 'Reach Iron rank',
        icon: '⚙️',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.uncommon,
        rewardPoints: 150,
      ),

      Achievement(
        id: 'rank_gold',
        title: 'Golden Glory',
        description: 'Reach Gold rank',
        icon: '🥇',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.rare,
        rewardPoints: 250,
      ),

      Achievement(
        id: 'rank_emerald',
        title: 'Emerald Elite',
        description: 'Reach Emerald rank',
        icon: '💚',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.rare,
        rewardPoints: 400,
      ),

      Achievement(
        id: 'rank_diamond',
        title: 'Diamond Deity',
        description: 'Reach Diamond rank',
        icon: '💎',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.epic,
        rewardPoints: 600,
      ),

      Achievement(
        id: 'rank_sapphire',
        title: 'Sapphire Supreme',
        description: 'Reach Sapphire rank',
        icon: '🔷',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.epic,
        rewardPoints: 1000,
      ),

      Achievement(
        id: 'rank_himothy',
        title: 'The Himothy',
        description: 'Reach the legendary Himothy rank',
        icon: '👑',
        category: AchievementCategory.rank,
        rarity: AchievementRarity.legendary,
        rewardPoints: 2500,
      ),
    ];

    for (final achievement in achievements) {
      _achievements[achievement.id] = achievement;
    }
  }

  /// Load achievement progress from storage
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('achievements_progress');
      
      if (progressJson != null) {
        final Map<String, dynamic> progressMap = json.decode(progressJson);
        
        for (final entry in progressMap.entries) {
          final achievementId = entry.key;
          final progressData = entry.value as Map<String, dynamic>;
          
          if (_achievements.containsKey(achievementId)) {
            final template = _achievements[achievementId]!;
            _achievements[achievementId] = Achievement.fromJson(progressData, template);
          }
        }
      }
      
      // Load total points
      _totalAchievementPoints = prefs.getInt('total_achievement_points') ?? 0;
      
      if (kDebugMode) {
        print('Loaded achievement progress: ${unlockedCount}/${totalCount} unlocked');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading achievement progress: $e');
      }
    }
  }

  /// Save achievement progress to storage
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressMap = <String, dynamic>{};
      
      for (final achievement in _achievements.values) {
        progressMap[achievement.id] = achievement.toJson();
      }
      
      await prefs.setString('achievements_progress', json.encode(progressMap));
      await prefs.setInt('total_achievement_points', _totalAchievementPoints);
      
      if (kDebugMode) {
        print('Saved achievement progress');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving achievement progress: $e');
      }
    }
  }

  /// Calculate total achievement points
  void _calculateTotalPoints() {
    _totalAchievementPoints = unlockedAchievements
        .fold(0, (sum, achievement) => sum + achievement.rewardPoints);
  }

  /// Update achievement progress
  Future<bool> updateProgress(String achievementId, {int increment = 1, int? setValue}) async {
    final achievement = _achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return false;

    final oldProgress = achievement.currentProgress;
    
    if (setValue != null) {
      achievement.currentProgress = setValue.clamp(0, achievement.maxProgress);
    } else {
      achievement.currentProgress = (achievement.currentProgress + increment)
          .clamp(0, achievement.maxProgress);
    }

    // Check if achievement was just completed
    if (!achievement.isUnlocked && achievement.isCompleted) {
      achievement.isUnlocked = true;
      achievement.unlockedAt = DateTime.now();
      
      _totalAchievementPoints += achievement.rewardPoints;
      
      // Add notification
      _recentNotifications.insert(0, AchievementNotification(
        achievement: achievement,
        timestamp: DateTime.now(),
      ));
      
      // Keep only recent notifications (last 10)
      if (_recentNotifications.length > 10) {
        _recentNotifications.removeRange(10, _recentNotifications.length);
      }
      
      await _saveProgress();
      notifyListeners();
      
      if (kDebugMode) {
        print('Achievement unlocked: ${achievement.title}');
      }
      
      return true; // Achievement was unlocked
    }

    // Save progress if it changed
    if (oldProgress != achievement.currentProgress) {
      await _saveProgress();
      notifyListeners();
    }

    return false; // Achievement not unlocked
  }

  /// Game event handlers
  Future<void> onGameStarted() async {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Early bird achievement (before 6 AM)
    if (hour >= 3 && hour < 6) {
      await updateProgress('early_bird');
    }
    
    // Night owl achievement (after midnight)
    if (hour >= 0 && hour < 3) {
      await updateProgress('night_owl');
    }
  }

  bool hasTwoSevens(int score) {
    String s = score.toString();           // convert to string
    int count = 0;

    for (int i = 0; i < s.length; i++) {
      if (s[i] == '7') {
        count++;
      }
    }

    return count >= 2;
  }

  bool has1234Sequence(int score) {
    String s = score.toString();
    return s.contains("1234") || s.contains("4321");
  }

  Future<void> onGameCompleted({
    required int score,
    required double gameTimeSeconds,
    required int shapeMorphs,
    required int dashesUsed,
    required int obstaclesPassed,
    required int xObstaclesSeen,
    required int xObstaclesHit,
    required double maxSpeed,
    required bool wasNewHighScore,
    required Map<PlayerShape, int> shapeUsage,
    // Powerup parameters:
    required int powerupsCollected,
    required Map<PowerupType, int> powerupUsage,
    required int bonusPointsFromMultipliers,
    required bool usedAllPowerupTypes,
    required int invincibleObstaclesPassed,
  }) async {
    // FIRST: Record the game completion for consistency tracking
    // This must happen before other achievements to ensure proper tracking
    final previousHighScore = GameData.highScore;
    await GameData.recordGameCompletion(score);
    
    // Basic gameplay achievements
    await updateProgress('first_steps');
    await updateProgress('shape_shifter', increment: shapeMorphs);
    await updateProgress('dash_master', increment: dashesUsed);
    await updateProgress('marathon_runner', increment: gameTimeSeconds.round());
    await updateProgress('dedicated_player');

    // Scoring achievements
    if (score >= 1000) await updateProgress('first_thousand');
    if (score >= 10000) await updateProgress('ten_grand');
    if (score >= 50000) await updateProgress('fifty_thousand_club');
    if (score >= 100000) await updateProgress('score_legend');
    if (score >= 1000000) await updateProgress('transcendent');

    // Special score achievements
    if (hasTwoSevens(score)) await updateProgress('lucky_seven');

    // Mastery achievements
    if (maxSpeed >= 5.0) await updateProgress('speed_demon');
    
    if (dashesUsed == 0 && obstaclesPassed >= 5) {
      await updateProgress('perfectionist');
    }
    
    if (obstaclesPassed >= 250 && xObstaclesHit == 0) {
      await updateProgress('untouchable');
    }

    // Perfect timing (obstacles passed without dashing)
    final perfectPasses = obstaclesPassed - dashesUsed;
    if (perfectPasses > 0) {
      await updateProgress('perfect_timing', increment: perfectPasses);
    }

    // Shape mastery
    int shapesWithEnoughUsage = 0;
    for (final usage in shapeUsage.values) {
      if (usage >= 50) shapesWithEnoughUsage++;
    }
    await updateProgress('shape_master', setValue: shapesWithEnoughUsage);

    // Progression achievements
    if (wasNewHighScore) {
      await updateProgress('high_achiever');
      
      // Check for improvement achievement
      if (previousHighScore > 0 && score - previousHighScore >= 25000) {
        await updateProgress('improvement');
      }
    }

    // UPDATED CONSISTENCY TRACKING: Use the streak from GameData
    final currentStreak = GameData.consistentGamesStreak;
    if (currentStreak > 0) {
      // Update the consistency achievement with the current streak
      await updateProgress('consistency', setValue: currentStreak);
    }

    // Easter egg achievement (secret condition)
    if (has1234Sequence(score)) {
      await updateProgress('easter_egg');
    }
    
    // Powerup collection achievements
    await updateProgress('powerup_hoarder', setValue: powerupsCollected);
    
    // Powered up scoring
    if (powerupsCollected > 0 && score >= 25000) {
      await updateProgress('powered_up_score');
    }
    
    // Multiplier master
    if (bonusPointsFromMultipliers >= 10000) {
      await updateProgress('multiplier_master');
    }
    
    // Full arsenal
    if (usedAllPowerupTypes) {
      await updateProgress('all_powerups');
    }
    
    // Purist achievement (no powerups)
    if (powerupsCollected == 0 && score >= 5000) {
      await updateProgress('no_powerups_run');
    }
  }
  
  Future<void> onTutorialCompleted() async {
    await updateProgress('getting_started');
  }
  
  /// Track powerup collection and usage
  Future<void> onPowerupCollected(PowerupType type) async {
    await updateProgress('first_powerup');
    await updateProgress('powerup_collector');
    await updateProgress('powerup_master');
    
    // Track specific powerup types
    switch (type) {
      case PowerupType.slowMotion:
        await updateProgress('slow_mo_expert');
        break;
      case PowerupType.scoreMultiplier:
        await updateProgress('score_booster');
        break;
      case PowerupType.invincibility:
        await updateProgress('untouchable_shield');
        break;
      case PowerupType.speedBoost:
        await updateProgress('speed_demon_powerup');
        break;
      case PowerupType.shapeFreeze:
        await updateProgress('shape_locker');
        break;
    }
  }

  /// Track multiple active powerups
  Future<void> onMultiplePowerupsActive(int count) async {
    if (count >= 3) {
      await updateProgress('powerup_combo');
    }
  }

  /// Track obstacles passed while invincible
  Future<void> onObstaclePassedWhileInvincible() async {
    await updateProgress('invincible_run');
  }

  Future<void> onLeaderboardSubmission({bool isFirstTime = false, int? rank}) async {
    if (isFirstTime) {
      await updateProgress('leaderboard_debut');
    }
    
    if (rank != null) {
      if (rank <= 10) await updateProgress('top_performer');
      if (rank == 1) await updateProgress('champion');
    }
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.values
        .where((a) => a.category == category)
        .toList()
        ..sort((a, b) => a.rarity.index.compareTo(b.rarity.index));
  }

  /// Get achievements by rarity
  List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return _achievements.values
        .where((a) => a.rarity == rarity)
        .toList();
  }

  /// Get achievement by ID
  Achievement? getAchievement(String id) {
    return _achievements[id];
  }

  /// Mark notification as read
  void markNotificationAsRead(int index) {
    if (index >= 0 && index < _recentNotifications.length) {
      _recentNotifications[index] = AchievementNotification(
        achievement: _recentNotifications[index].achievement,
        timestamp: _recentNotifications[index].timestamp,
        isNew: false,
      );
      notifyListeners();
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _recentNotifications.clear();
    notifyListeners();
  }

  /// Get completion statistics
  Map<AchievementCategory, Map<String, int>> getCompletionStats() {
    final stats = <AchievementCategory, Map<String, int>>{};
    
    for (final category in AchievementCategory.values) {
      final categoryAchievements = getAchievementsByCategory(category);
      final unlockedInCategory = categoryAchievements.where((a) => a.isUnlocked).length;
      
      stats[category] = {
        'total': categoryAchievements.length,
        'unlocked': unlockedInCategory,
      };
    }
    
    return stats;
  }

  /// Reset all achievements (for testing/debugging)
  Future<void> resetAllAchievements() async {
    for (final achievement in _achievements.values) {
      achievement.currentProgress = 0;
      achievement.isUnlocked = false;
      achievement.unlockedAt = null;
    }
    
    _totalAchievementPoints = 0;
    _recentNotifications.clear();
    
    await _saveProgress();
    notifyListeners();
    
    if (kDebugMode) {
      print('All achievements reset');
    }
  }

  /// Get next achievements to work towards
  List<Achievement> getNextAchievements({int limit = 5}) {
    return lockedAchievements
        .where((a) => !a.isSecret || a.currentProgress > 0)
        .where((a) => a.currentProgress > 0 || a.maxProgress == 1)
        .toList()
        ..sort((a, b) {
          // Sort by progress percentage descending, then by rarity
          final progressDiff = b.progressPercentage.compareTo(a.progressPercentage);
          if (progressDiff != 0) return progressDiff;
          return a.rarity.index.compareTo(b.rarity.index);
        })
        ..take(limit).toList();
  }

  /// Get rarity color
  static Color getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey.shade600;
      case AchievementRarity.uncommon:
        return Colors.green.shade600;
      case AchievementRarity.rare:
        return Colors.blue.shade600;
      case AchievementRarity.epic:
        return Colors.purple.shade600;
      case AchievementRarity.legendary:
        return Colors.orange.shade600;
    }
  }

  /// Get category icon
  static String getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gameplay:
        return '🎮';
      case AchievementCategory.scoring:
        return '🏆';
      case AchievementCategory.mastery:
        return '⚡';
      case AchievementCategory.progression:
        return '📈';
      case AchievementCategory.special:
        return '✨';
      case AchievementCategory.social:
        return '👥';
      case AchievementCategory.rank:
        return '🏅';
    }
  }

  /// Get category name
  static String getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.gameplay:
        return 'Gameplay';
      case AchievementCategory.scoring:
        return 'Scoring';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.progression:
        return 'Progression';
      case AchievementCategory.special:
        return 'Special';
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.rank:
        return 'Rank';
    }
  }

  /// Get rarity name
  static String getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  /// Called when player achieves a new rank
  Future<void> onRankAchieved(RankTier tier) async {
    // If unranked, skip
    if (tier == RankTier.unranked) return;

    // Iterate through all ranks from lowest up to the achieved one
    for (int i = 0; i <= tier.index; i++) {
      final unlockedTier = RankTier.values[i];
      await updateProgress(_rankKey(unlockedTier));
    }
  }
  
  /// Maps enum to the achievement key
  String _rankKey(RankTier tier) {
    switch (tier) {
      case RankTier.wood:
        return 'rank_wood';
      case RankTier.stone:
        return 'rank_stone';
      case RankTier.carbon:
        return 'rank_carbon';
      case RankTier.iron:
        return 'rank_iron';
      case RankTier.gold:
        return 'rank_gold';
      case RankTier.emerald:
        return 'rank_emerald';
      case RankTier.diamond:
        return 'rank_diamond';
      case RankTier.sapphire:
        return 'rank_sapphire';
      case RankTier.himothy:
        return 'rank_himothy';
      case RankTier.unranked:
        return '';
    }
  }
}