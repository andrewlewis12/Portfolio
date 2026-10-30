// services/achievement_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/achievement_models.dart';
import 'storage_service.dart';
import 'audio_service.dart';
import '../services/achievement_service.dart';

class UnlockedAchievement {
  final Achievement achievement;
  final DateTime unlockedAt;

  UnlockedAchievement({
    required this.achievement,
    required this.unlockedAt,
  });
}

class AchievementService extends ChangeNotifier {
  final StorageService _storageService;
  final AudioService _audioService;
  
  List<Achievement> _achievements = [];
  List<UnlockedAchievement> _recentlyUnlocked = [];
  StreamController<UnlockedAchievement> _achievementUnlockedController = StreamController<UnlockedAchievement>.broadcast();
  
  // Game session tracking for special achievements
  int _currentGamePiecesPlaced = 0;
  int _currentGameGravityTriggers = 0;
  DateTime? _gameStartTime;
  List<String> _currentGamePieceTypes = [];
  bool _hasUsedRewardedAd = false;
  int _scoreBeforeRewardedAd = 0;

  AchievementService({
    required StorageService storageService,
    required AudioService audioService,
  }) : _storageService = storageService, _audioService = audioService {
    _initializeAchievements();
  }

  // Getters
  List<Achievement> get achievements => _achievements;
  List<UnlockedAchievement> get recentlyUnlocked => _recentlyUnlocked;
  Stream<UnlockedAchievement> get onAchievementUnlocked => _achievementUnlockedController.stream;
  
  int get totalPoints => _achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.pointsReward);
  
  int get unlockedCount => _achievements.where((a) => a.isUnlocked).length;
  int get totalCount => _achievements.length;
  
  double get completionPercentage => totalCount > 0 ? unlockedCount / totalCount : 0.0;

  Future<void> _initializeAchievements() async {
    // Load base achievements
    _achievements = List.from(Achievements.all);
    
    // Load saved progress
    await _loadAchievementProgress();
    
    notifyListeners();
  }

  Future<void> _loadAchievementProgress() async {
    final savedData = await _storageService.getString('achievements_data');
    if (savedData == null) return;

    try {
      final Map<String, dynamic> data = jsonDecode(savedData);
      
      for (int i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        final savedAchievement = data[achievement.id];
        
        if (savedAchievement != null) {
          _achievements[i] = Achievement.fromStoredData(achievement, savedAchievement);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading achievement progress: $e');
      }
    }
  }

  Future<void> _saveAchievementProgress() async {
    final data = <String, dynamic>{};
    
    for (final achievement in _achievements) {
      data[achievement.id] = achievement.toJson();
    }
    
    await _storageService.saveString('achievements_data', jsonEncode(data));
  }

  // Event tracking methods
  void onGameStarted() {
    _currentGamePiecesPlaced = 0;
    _currentGameGravityTriggers = 0;
    _gameStartTime = DateTime.now();
    _currentGamePieceTypes.clear();
    _hasUsedRewardedAd = false;
    _scoreBeforeRewardedAd = 0;
  }

  void onScoreChanged(int newScore, int previousScore) {
    _updateProgress('first_score', newScore);
    _updateProgress('score_1k', newScore);
    _updateProgress('score_5k', newScore);
    _updateProgress('score_10k', newScore);
    _updateProgress('score_25k', newScore);
    
    // Check comeback king achievement
    if (_hasUsedRewardedAd && newScore > _scoreBeforeRewardedAd) {
      _unlockAchievement('comeback_king');
    }
  }

  void onLineCleared(int totalLinesCleared, bool isSimultaneousRowColumn) {
    _updateProgress('first_line', totalLinesCleared);
    _updateProgress('lines_10', totalLinesCleared);
    _updateProgress('lines_50', totalLinesCleared);
    _updateProgress('lines_100', totalLinesCleared);
    
    if (isSimultaneousRowColumn) {
      _unlockAchievement('simultaneous_clear');
    }
  }

  void onComboAchieved(int comboLevel) {
    _updateProgress('first_combo', comboLevel);
    _updateProgress('combo_5', comboLevel);
    _updateProgress('combo_10', comboLevel);
    _updateProgress('combo_15', comboLevel);
  }

  void onLevelReached(int level) {
    _updateProgress('level_5', level);
    _updateProgress('level_10', level);
    _updateProgress('level_20', level);
  }

  void onGameCompleted(int gamesPlayed) {
    _updateProgress('games_10', gamesPlayed);
    _updateProgress('games_50', gamesPlayed);
    
    // Check speed demon achievement
    if (_gameStartTime != null && _currentGamePiecesPlaced >= 10) {
      final gameDuration = DateTime.now().difference(_gameStartTime!);
      if (gameDuration.inSeconds <= 30) {
        _unlockAchievement('speed_demon');
      }
    }
    
    // Check minimalist achievement
    final onlySingleBlocks = _currentGamePieceTypes.every((type) => type == 'single');
    if (onlySingleBlocks && _currentGamePieceTypes.length >= 10) {
      // This will be checked in the game service when score reaches 1000
    }
    
    // Check gravity master
    if (_currentGameGravityTriggers >= 25) {
      _unlockAchievement('gravity_master');
    }
  }

  void onPiecePlaced(String pieceType, int blockCount, bool isPerfectFit) {
    _currentGamePiecesPlaced++;
    _currentGamePieceTypes.add(blockCount == 1 ? 'single' : 'multi');
    
    if (isPerfectFit) {
      _unlockAchievement('perfect_placement');
    }
    
    // Check for minimalist progress
    if (blockCount == 1) {
      final achievement = _getAchievementById('minimalist');
      if (achievement != null && !achievement.isUnlocked) {
        // Track single-block piece usage in game service
      }
    }
  }

  void onGravityTriggered() {
    _currentGameGravityTriggers++;
  }

  void onTutorialCompleted() {
    _unlockAchievement('tutorial_complete');
  }

  void onRewardedAdUsed(int currentScore) {
    _hasUsedRewardedAd = true;
    _scoreBeforeRewardedAd = currentScore;
  }

  void onMinimalistScoreReached(int score) {
    // Check if player reached 1000 points using only single blocks
    final onlySingleBlocks = _currentGamePieceTypes.every((type) => type == 'single');
    if (onlySingleBlocks && score >= 1000) {
      _unlockAchievement('minimalist');
    }
  }

  // Internal methods
  void _updateProgress(String achievementId, int value) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;
    
    final achievement = _achievements[index];
    if (achievement.isUnlocked) return;
    
    final newProgress = value.clamp(0, achievement.targetValue);
    if (newProgress <= achievement.currentProgress) return;
    
    _achievements[index] = achievement.copyWith(currentProgress: newProgress);
    
    // Check if achievement should be unlocked
    if (newProgress >= achievement.targetValue) {
      _unlockAchievement(achievementId);
    } else {
      notifyListeners();
      _saveAchievementProgress();
    }
  }

  void _unlockAchievement(String achievementId) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) return;
    
    final achievement = _achievements[index];
    if (achievement.isUnlocked) return;
    
    final now = DateTime.now();
    _achievements[index] = achievement.copyWith(
      isUnlocked: true,
      currentProgress: achievement.targetValue,
      unlockedAt: now,
    );
    
    final unlockedAchievement = UnlockedAchievement(
      achievement: _achievements[index],
      unlockedAt: now,
    );
    
    _recentlyUnlocked.add(unlockedAchievement);
    
    // Limit recently unlocked list
    if (_recentlyUnlocked.length > 10) {
      _recentlyUnlocked.removeAt(0);
    }
    
    // Play achievement sound
    _audioService.playUIClick(); // You might want to add a specific achievement sound
    
    // Notify listeners
    _achievementUnlockedController.add(unlockedAchievement);
    notifyListeners();
    _saveAchievementProgress();
    
    if (kDebugMode) {
      print('🏆 Achievement Unlocked: ${achievement.title}');
    }
  }

  Achievement? _getAchievementById(String id) {
    try {
      return _achievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Public utility methods
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  List<Achievement> getLockedAchievements() {
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  List<Achievement> getSecretAchievements() {
    return _achievements.where((a) => a.isSecret).toList();
  }

  void clearRecentlyUnlocked() {
    _recentlyUnlocked.clear();
    notifyListeners();
  }

  // Reset achievements (for testing or fresh start)
  Future<void> resetAllAchievements() async {
    for (int i = 0; i < _achievements.length; i++) {
      final achievement = _achievements[i];
      _achievements[i] = achievement.copyWith(
        isUnlocked: false,
        currentProgress: 0,
        unlockedAt: null,
      );
    }
    
    _recentlyUnlocked.clear();
    await _saveAchievementProgress();
    notifyListeners();
  }

  @override
  void dispose() {
    _achievementUnlockedController.close();
    super.dispose();
  }
}