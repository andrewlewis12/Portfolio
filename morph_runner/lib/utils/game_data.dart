import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayerShape { 
  circle, 
  square, 
  triangle, 
  diamond, 
  star,
  hexagon,
  heart,
  pentagon
}

enum GameState { 
  splash,
  menu, 
  playing, 
  paused,
  gameOver,
  tutorial 
}

class GameData {
  static SharedPreferences? _prefs;
  static int _highScore = 0;
  static bool _tutorialCompleted = false;
  static bool _soundEnabled = true;
  static bool _vibrateEnabled = true;
  static int _totalGamesPlayed = 0;
  static double _totalTimePlayed = 0.0;
  static int _totalScore = 0;

  static final _random = Random();
  
  // Game balance constants
  static const int lanesCount = 5;
  static const double baseGameSpeed = 2.3;
  static const double maxGameSpeed = 4.1;
  static const double speedIncreaseRate = 0.005;
  static const double blockXChance = 0.15;
  static const double doubleXChance = 0.05;

  
  // Update the init method to load consistency data
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _highScore = _prefs?.getInt('high_score') ?? 0;
    _totalScore = _prefs?.getInt('total_score') ?? 0;
    _tutorialCompleted = _prefs?.getBool('tutorial_completed') ?? false;
    _soundEnabled = _prefs?.getBool('sound_enabled') ?? true;
    _vibrateEnabled = _prefs?.getBool('vibrate_enabled') ?? true;
    _musicEnabled = _prefs?.getBool('music_enabled') ?? true;
    _volume = _prefs?.getDouble('volume') ?? 0.7;
    _musicVolume = _prefs?.getDouble('music_volume') ?? 0.4;
    _totalGamesPlayed = _prefs?.getInt('total_games_played') ?? 0;
    _totalTimePlayed = _prefs?.getDouble('total_time_played') ?? 0.0;
    
    // Load consistency tracking data
    _consistentGamesStreak = _prefs?.getInt('consistent_games_streak') ?? 0;
    _lastGameScore = _prefs?.getInt('last_game_score') ?? 0;
    _lastGameWasConsistent = _prefs?.getBool('last_game_was_consistent') ?? false;
  }

  static int get highScore => _highScore;
  static int get totalScore => _totalScore;
  static bool get tutorialCompleted => _tutorialCompleted;
  static bool get soundEnabled => _soundEnabled;
  static bool get vibrateEnabled => _vibrateEnabled;
  static int get totalGamesPlayed => _totalGamesPlayed;
  static double get totalTimePlayed => _totalTimePlayed;
  static int _consistentGamesStreak = 0;
  static int _lastGameScore = 0;
  static bool _lastGameWasConsistent = false;

  // Add getters
  static int get consistentGamesStreak => _consistentGamesStreak;
  static int get lastGameScore => _lastGameScore;
  static bool get lastGameWasConsistent => _lastGameWasConsistent;

  // New method to track game completion for consistency
  static Future<void> recordGameCompletion(int finalScore) async {
    _lastGameScore = finalScore;
    _totalScore += finalScore;

    if (finalScore >= 1000) {
      // Game was consistent (scored 1000+)
      if (_lastGameWasConsistent) {
        // Previous game was also consistent, continue streak
        _consistentGamesStreak++;
      } else {
        // First consistent game in a new streak
        _consistentGamesStreak = 1;
      }
      _lastGameWasConsistent = true;
    } else {
      // Game was not consistent, break the streak
      _consistentGamesStreak = 0;
      _lastGameWasConsistent = false;
    }
    
    // Save to preferences
    await _prefs?.setInt('consistent_games_streak', _consistentGamesStreak);
    await _prefs?.setInt('last_game_score', _lastGameScore);
    await _prefs?.setBool('last_game_was_consistent', _lastGameWasConsistent);
    await _prefs?.setInt('total_score', _totalScore);
  }

  // Update resetAllData to include consistency data
  static Future<void> resetAllData() async {
    _highScore = 0;
    _totalScore = 0;
    _tutorialCompleted = false;
    _totalGamesPlayed = 0;
    _totalTimePlayed = 0.0;
    _consistentGamesStreak = 0;
    _lastGameScore = 0;
    _lastGameWasConsistent = false;
    
    await _prefs?.setInt('high_score', 0);
    await _prefs?.setInt('total_score', 0);
    await _prefs?.setBool('tutorial_completed', false);
    await _prefs?.setInt('total_games_played', 0);
    await _prefs?.setDouble('total_time_played', 0.0);
    await _prefs?.setInt('consistent_games_streak', 0);
    await _prefs?.setInt('last_game_score', 0);
    await _prefs?.setBool('last_game_was_consistent', false);
  }

  static Future<void> setHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      await _prefs?.setInt('high_score', _highScore);
    }
  }

  static Future<void> incrementGamesPlayed() async {
    _totalGamesPlayed++;
    await _prefs?.setInt('total_games_played', _totalGamesPlayed);
  }

  static Future<void> addTimePlayed(double seconds) async {
    _totalTimePlayed += seconds;
    await _prefs?.setDouble('total_time_played', _totalTimePlayed);
  }

  static Future<void> setTutorialCompleted() async {
    _tutorialCompleted = true;
    await _prefs?.setBool('tutorial_completed', true);
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs?.setBool('sound_enabled', enabled);
  }

  static Future<void> setVibrateEnabled(bool enabled) async {
    _vibrateEnabled = enabled;
    await _prefs?.setBool('vibrate_enabled', enabled);
  }

  static Color getShapeColor(PlayerShape shape) {
    switch (shape) {
      case PlayerShape.circle:
        return const Color.fromARGB(255, 0, 255, 255);
      case PlayerShape.square:
        return Colors.orange;
      case PlayerShape.triangle:
        return const Color.fromARGB(255, 255, 0, 183);
      case PlayerShape.diamond:
        return const Color.fromARGB(255, 0, 255, 8);
      case PlayerShape.star:
        return const Color.fromARGB(255, 255, 230, 0);
      case PlayerShape.hexagon:
        return const Color.fromARGB(255, 105, 30, 255);
      case PlayerShape.heart:
        return const Color.fromARGB(255, 255, 17, 0);
      case PlayerShape.pentagon:
        return const Color.fromARGB(255, 42, 98, 255);
    }
  }

  static String getShapeName(PlayerShape shape) {
    switch (shape) {
      case PlayerShape.circle:
        return 'Circle';
      case PlayerShape.square:
        return 'Square';
      case PlayerShape.triangle:
        return 'Triangle';
      case PlayerShape.diamond:
        return 'Diamond';
      case PlayerShape.star:
        return 'Star';
      case PlayerShape.hexagon:
        return 'Hexagon';
      case PlayerShape.heart:
        return 'Heart';
      case PlayerShape.pentagon:
        return 'Pentagon';
    }
  }

  static PlayerShape getNextShape([PlayerShape? currentShape]) {
    final shapes = PlayerShape.values;
    
    if (currentShape == null) {
      return shapes[_random.nextInt(shapes.length)];
    }

    PlayerShape nextShape;
    do {
      nextShape = shapes[_random.nextInt(shapes.length)];
    } while (nextShape == currentShape);

    return nextShape;
  }

  static double getGameSpeedForScore(int score) {
    return clampDouble(baseGameSpeed + (score / 1000) * speedIncreaseRate, baseGameSpeed, maxGameSpeed) ;
  }


  static double getDifficultyMultiplier(int score) {
    return 1.0 + (score / 5000) * 0.5;
  }

  // X probability starts at 1/9 (8 shapes + X) and progresses to 1/5 (max 20%)
  static double getXProbabilityForScore(int score) {
    const double startProbability = 1.0 / 9.0; // ~11.1%
    const double maxProbability = 1.0 / 5.0;   // 20%
    const double scoreToMaxDifficulty = 10000.0; // Score at which max probability is reached
    
    double progress = (score / scoreToMaxDifficulty).clamp(0.0, 1.0);
    return startProbability + (maxProbability - startProbability) * progress;
  }

  // Add these variables
  static bool _musicEnabled = true;
  static double _volume = 0.7;
  static double _musicVolume = 0.4;

  // Add getters
  static bool get musicEnabled => _musicEnabled;
  static double get volume => _volume;
  static double get musicVolume => _musicVolume;

  // Add setters
  static Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await _prefs?.setBool('music_enabled', enabled);
  }

  static Future<void> setVolume(double volume) async {
    _volume = volume;
    await _prefs?.setDouble('volume', volume);
  }

  static Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume;
    await _prefs?.setDouble('music_volume', volume);
  }

  static const String companyName = 'Paconot Technologies';
  static const String companyEmail = 'support@paconotenterprises.com';
  static const String companyWebsite = 'paconotenterprises.com';
  static const String appVersion = '1.1.3';
}