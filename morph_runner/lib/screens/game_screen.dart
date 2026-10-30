import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;
import 'dart:async';
import 'dart:math';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../utils/game_data.dart';
import '../utils/rank_system.dart';
import '../widgets/shape_widget.dart';
import '../services/ad_service.dart';
import '../widgets/game_popups.dart';
import '../services/achievements_service.dart';
import '../widgets/achievements_widget.dart';
import '../utils/screen_transitions.dart';
import 'home_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  GameState gameState = GameState.playing;
  double _lastSpawnCameraY = double.infinity;
  bool _gameStarted = false;
  bool _hasUsedRevive = false;

  RankInfo _currentRank = RankSystem.getRankForScore(GameData.highScore);
  bool _showRankOutline = true;
  
  // Game variables
  int score = 0;
  double gameSpeed = GameData.baseGameSpeed;
  late DateTime gameStartTime;
  
  // Player variables
  PlayerShape currentShape = GameData.getNextShape();
  int playerLane = 2;
  static const double dashDistance = 250.0; // Fixed distance to dash
  double dashStartCameraY = 0.0;
  bool isDashing = false;
  bool isDead = false;
  String deathReason = "";
  
  // Gesture tracking - IMPROVED SENSITIVITY
  bool _hasMovedThisGesture = false;
  double _swipeThreshold = 4.0; // REDUCED from default ~15
  double _dashThreshold = 8.0; // REDUCED for easier dash
  
  // Powerup system
  Map<String, Powerup> activePowerups = {};
  List<PowerupRow> powerupRows = [];
  
  // Animation controllers
  late AnimationController _shapeController;
  late AnimationController _dashController;
  late AnimationController _deathController;
  late Animation<double> _dashSpeedAnimation;
  late Animation<double> _dashGlowAnimation;
  late Animation<double> _dashBlurAnimation;
  late Animation<double> _deathAnimation;
  late Animation<double> _deathRotationAnimation;
  
  // Game loop and timers
  Timer? gameTimer;
  
  // Obstacles - Fixed distance-based spawning
  List<ObstacleRow> obstacleRows = [];
  double cameraY = 0;
  static const double obstacleSpacing = 375.0;
  int nextObstacleId = 0;
  
  // Achievement tracking
  int _powerupsCollected = 0;
  Map<PowerupType, int> _powerupUsage = {};
  int _bonusPointsFromMultipliers = 0;
  Set<PowerupType> _powerupTypesUsedThisGame = {};
  int _invincibleObstaclesPassed = 0;
  int _shapeMorphCount = 0;
  int _dashCount = 0;
  int _obstaclesPassed = 0;
  int _xObstaclesSeen = 0;
  int _xObstaclesHit = 0;
  double _maxSpeedReached = 0.0;
  Map<PlayerShape, int> _shapeUsageCount = {};
  List<Widget> _achievementOverlays = [];

  @override
  void initState() {
    super.initState();
    gameStartTime = DateTime.now();
    _initializeAnimations();
    
    for (final type in PowerupType.values) {
      _powerupUsage[type] = 0;
    }

    for (final shape in PlayerShape.values) {
      _shapeUsageCount[shape] = 0;
    }

    _loadRankSettings();

    // FIXED: Initialize the game banner ad properly
    AdService.instance.onGameScreenCreated();
    
    // Delay game start to ensure ads are handled properly
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeGame();
      }
    });
  }

  Future<void> _loadRankSettings() async {
    await RankDisplaySettings.initialize();
    setState(() {
      _showRankOutline = RankDisplaySettings.showRankOutline;
      _currentRank = RankSystem.getRankForScore(GameData.highScore);
    });
  }

  void _initializeGame() {
    if (obstacleRows.isEmpty) {
      _initializeObstacles();
      // Switch to game music
      AudioService.instance.crossfadeToGameMusic();
      _startGame();
    }
  }
  
  void _initializeAnimations() {
    _shapeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _dashController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _deathController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _dashSpeedAnimation = Tween<double>(begin: 1.0, end: 4.0).animate(
      CurvedAnimation(parent: _dashController, curve: Curves.easeOutCubic),
    );
    
    _dashGlowAnimation = Tween<double>(begin: 1.0, end: 3.0).animate(
      CurvedAnimation(parent: _dashController, curve: Curves.easeInOut),
    );
    
    _dashBlurAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _dashController, curve: Curves.easeInOut),
    );
    
    _deathAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _deathController, curve: Curves.easeOutCubic),
    );
    
    _deathRotationAnimation = Tween<double>(begin: 0.0, end: 4 * pi).animate(
      CurvedAnimation(parent: _deathController, curve: Curves.easeOutCubic),
    );
  }
  
  void _initializeObstacles() {
    final screenHeight = MediaQuery.of(context).size.height;
    
    for (int i = 0; i < 4; i++) {
      final obstacleY = screenHeight - (i * obstacleSpacing) - 600;
      final row = ObstacleRow(
        y: obstacleY, 
        id: nextObstacleId++,
        cameraY: obstacleY - cameraY,
      );
      _generateObstacle(row);
      obstacleRows.add(row);
    }
  }
  
  void _startGame() {
    AchievementsService.instance.onGameStarted();
    _gameStarted = true;
    gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
  }
  
  void _spawnObstacleRow() {
    if (gameState != GameState.playing || isDead || !_gameStarted) return;

    final lastObstacleY = obstacleRows.isEmpty 
        ? MediaQuery.of(context).size.height - 600
        : obstacleRows.last.y;

    final nextY = lastObstacleY - obstacleSpacing;

    final row = ObstacleRow(
      y: nextY,
      id: nextObstacleId++,
      cameraY: nextY - cameraY,
    );

    _generateObstacle(row);
    obstacleRows.add(row);
    
    // POWERUP SPAWNING - occasional powerups
    if (Random().nextDouble() < 0.1 && score > 500) { // 10% chance after score 500
      _spawnPowerup(nextY - 100); // Spawn before obstacle
    }
  }

  void _generateObstacle(ObstacleRow row) {
    final random = Random();
    final xProbability = GameData.getXProbabilityForScore(score);
    
    final possibleContent = <dynamic>[
      ...PlayerShape.values,
      ObstacleContent.x,
    ];
    
    final usedContent = <dynamic>{};
    
    for (int i = 0; i < GameData.lanesCount; i++) {
      if (random.nextDouble() < xProbability && !usedContent.contains(ObstacleContent.x)) {
        row.lanes[i] = ObstacleContent.x;
        usedContent.add(ObstacleContent.x);
      } else {
        final availableShapes = PlayerShape.values.where((shape) => !usedContent.contains(shape)).toList();
        if (availableShapes.isNotEmpty) {
          final shape = availableShapes[random.nextInt(availableShapes.length)];
          row.lanes[i] = shape;
          usedContent.add(shape);
        } else {
          row.lanes[i] = PlayerShape.values[random.nextInt(PlayerShape.values.length)];
        }
      }
    }
  }
  
  // POWERUP SYSTEM
  void _spawnPowerup(double y) {
    final lane = Random().nextInt(GameData.lanesCount);
    final powerupType = PowerupType.values[Random().nextInt(PowerupType.values.length)];
    
    powerupRows.add(PowerupRow(
      y: y,
      lane: lane,
      type: powerupType,
      cameraY: y - cameraY,
    ));
  }
  
  int _getPowerupBaseDuration(PowerupType type) {
    switch (type) {
      case PowerupType.slowMotion:
        return 5;
      case PowerupType.scoreMultiplier:
        return 8;
      case PowerupType.shapeFreeze:
        return 10;
      case PowerupType.invincibility:
        return 3;
      case PowerupType.speedBoost:
        return 6;
    }
  }

  void _activatePowerup(PowerupType type) {
    _powerupsCollected++;
    _powerupUsage[type] = (_powerupUsage[type] ?? 0) + 1;
    _powerupTypesUsedThisGame.add(type);
    
    // Track achievement
    AchievementsService.instance.onPowerupCollected(type);

    // --- NEW STACKING LOGIC ---
    final powerupId = type.toString();
    final newDuration = _getPowerupBaseDuration(type); // Get the base duration for stacking
    
    if (activePowerups.containsKey(powerupId)) {
      // POWERUP IS ALREADY ACTIVE: Extend duration
      final existingPowerup = activePowerups[powerupId]!;
      existingPowerup.extendDuration(newDuration);
      
      // Check for multiple active powerups (must check unique *types*)
      if (activePowerups.length > 1) { 
        AchievementsService.instance.onMultiplePowerupsActive(activePowerups.length);
      }
      
    } else {
      // POWERUP IS NEW: Create and activate
      final powerup = _createPowerup(type);
      activePowerups[powerupId] = powerup;
      
      // Check for multiple active powerups
      if (activePowerups.length > 1) { 
        AchievementsService.instance.onMultiplePowerupsActive(activePowerups.length);
      }

      // Since the powerup is new, we need a periodic check to remove it when it expires
      Timer.periodic(Duration(milliseconds: 500), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        
        final currentPowerup = activePowerups[powerupId];
        if (currentPowerup == null || currentPowerup.isExpired) {
          setState(() {
            activePowerups.remove(powerupId);
          });
          timer.cancel();
        }
      });
    }
    
    // Apply powerup effect (effects are handled in _updateGame or _checkCollisions)
    switch (type) {
      case PowerupType.slowMotion:
      case PowerupType.scoreMultiplier:
      case PowerupType.shapeFreeze:
      case PowerupType.invincibility:
      case PowerupType.speedBoost:
        // No immediate state change needed here, just the duration management above
        break;
    }
    
    // Visual/audio feedback
    AudioService.instance.playPowerUp();
    if (GameData.vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }
}

  Powerup _createPowerup(PowerupType type) {
    final duration = _getPowerupBaseDuration(type);
    final id = type.toString(); // Use the type name as the ID

    switch (type) {
      case PowerupType.slowMotion:
        return Powerup(
          id: id,
          type: type,
          duration: duration,
          multiplier: 0.5,
        );
      case PowerupType.scoreMultiplier:
        return Powerup(
          id: id,
          type: type,
          duration: duration,
          multiplier: 2.0,
        );
      case PowerupType.shapeFreeze:
        return Powerup(
          id: id,
          type: type,
          duration: duration,
          multiplier: 1.0,
        );
      case PowerupType.invincibility:
        return Powerup(
          id: id,
          type: type,
          duration: duration,
          multiplier: 1.0,
        );
      case PowerupType.speedBoost:
        return Powerup(
          id: id,
          type: type,
          duration: duration,
          multiplier: 1.5,
        );
    }
  }

  void _updateGame() {
    if (gameState != GameState.playing || isDead || !_gameStarted) return;
    
    _maxSpeedReached = math.max(_maxSpeedReached, gameSpeed);

    setState(() {
      // Calculate score with powerup multipliers
      double scoreMultiplier = 1.0;
      for (final powerup in activePowerups.values) {
        if (powerup.type == PowerupType.scoreMultiplier) {
          scoreMultiplier *= powerup.multiplier;
        }
      }

      double dashMultiplier = 1.0;
      if (isDashing)
      {
        dashMultiplier *= _dashSpeedAnimation.value * 2.0;
      }

      score += (gameSpeed * 3 * scoreMultiplier * dashMultiplier).round();

      if (scoreMultiplier > 1.0) {
        int baseScore = (gameSpeed * 3).round();
        int bonusScore = (baseScore * (scoreMultiplier - 1.0)).round();
        _bonusPointsFromMultipliers += bonusScore;
      }

      final newRank = RankSystem.getRankForScore(score);
      if (newRank.tier.index > _currentRank.tier.index) {
        _currentRank = newRank;
        // Optional: Play rank up sound/effect
        AudioService.instance.playPowerUp();
        if (GameData.vibrateEnabled) {
          HapticFeedback.mediumImpact();
        }
      }

      // Calculate game speed with powerup effects
      double baseSpeed = GameData.getGameSpeedForScore(score);
      double speedMultiplier = 1.0;
      
      // Apply powerup effects
      for (final powerup in activePowerups.values) {
          switch (powerup.type) {
              case PowerupType.slowMotion:
                  speedMultiplier *= powerup.multiplier;
                  break;
              case PowerupType.speedBoost:
                  speedMultiplier *= powerup.multiplier;
                  break;
              default:
                  break;
          }
      }
      
      gameSpeed = baseSpeed * speedMultiplier;
      
      // NEW CODE: Update music playback rate based on game speed
      double playbackRate = gameSpeed / 2.3;
      // Clamp the rate to a reasonable range (e.g., 0.5 to 3.0) 
      // to prevent extreme, unusable speeds.
      playbackRate = playbackRate.clamp(0.5, 3.0); 
      AudioService.instance.setGameMusicPlaybackRate(playbackRate); 
      

      // UPDATED: Dash speed calculation - much more dramatic
      double currentSpeed = gameSpeed;
      if (isDashing) {
        // During dash, speed is boosted significantly
        currentSpeed = gameSpeed * _dashSpeedAnimation.value * 2.0; // 2x multiplier for more dramatic effect
      }
      
      cameraY += currentSpeed;
      
      // Update obstacle positions
      for (final row in obstacleRows) {
        row.y = row.cameraY + cameraY;
      }
      
      // Update powerup positions
      for (final powerupRow in powerupRows) {
        powerupRow.y = powerupRow.cameraY + cameraY;
      }
      
      final screenHeight = MediaQuery.of(context).size.height;
      if (obstacleRows.length < 4 ||
        (obstacleRows.last.cameraY <= -obstacleSpacing && 
        obstacleRows.last.cameraY < _lastSpawnCameraY - obstacleSpacing)) {
      
        _spawnObstacleRow();
        _lastSpawnCameraY = obstacleRows.last.cameraY;
      }
      
      // Clean up old obstacles
      obstacleRows.removeWhere((row) {
        if (row.y > screenHeight + 100) {
          return true;
        }
        return false;
      });
      
      // Clean up old powerups
      powerupRows.removeWhere((powerupRow) {
        if (powerupRow.y > screenHeight + 100) {
          return true;
        }
        return false;
      });

      _checkCollisions();
      _checkPowerupCollisions();
    });
  }
  
  void _checkPowerupCollisions() {
    // Player center Y is the same as calculated for obstacle collisions
    final playerCenterY = MediaQuery.of(context).size.height - 250;
    // Powerup row height is 60
    const powerupRowHeight = 60.0;
    // Player shape widget size is 60
    const playerHeight = 60.0; 
    
    // The maximum distance between the center of the powerup and the center of the player 
    final collisionMargin = (powerupRowHeight / 2) + (playerHeight / 2); // 30 + 30 = 60.0
    
    powerupRows.removeWhere((powerupRow) {
      // Calculate the center Y of the powerup row
      final powerupCenterY = powerupRow.y + (powerupRowHeight / 2);
      
      // Check for vertical overlap (collision)
      if ((powerupCenterY - playerCenterY).abs() < collisionMargin) {
        if (powerupRow.lane == playerLane && !powerupRow.collected) {
          powerupRow.collected = true;
          _activatePowerup(powerupRow.type);
          return true; // Remove collected powerup
        }
      }
      return false;
    });
  }
  
  void _checkCollisions() {
    // 1. Calculate Player Collision Center and Margin
    final screenHeight = MediaQuery.of(context).size.height;
    
    // --- FIX: Add a positive offset to playerCenterY to effectively lower the collision zone ---
    // If collision is too early, we need to push the detection point down.
    const double collisionAdjustment = 20.0; // Adjust this value (e.g., 10.0 to 30.0) based on testing
    
    // Original player center: screenHeight - 250.0
    final playerCenterY = screenHeight - 250.0 + collisionAdjustment; 
    
    const obstacleRowHeight = 80.0;
    const playerHeight = 60.0; 
    // This remains 70.0 (40 + 30)
    final collisionMargin = (obstacleRowHeight / 2) + (playerHeight / 2); 

    for (final row in obstacleRows) {
      if (row.passed) continue;
      
      final obstacleCenterY = row.y + (obstacleRowHeight / 2);
      
      // 2. Check for Vertical Overlap (Collision)
      if ((obstacleCenterY - playerCenterY).abs() < collisionMargin) {
        
        // --- CRITICAL STEP: BYPASS NORMAL COLLISION WHILE DASHING ---
        if (isDashing) {
          row.passed = true;
          _obstaclesPassed++;
          continue; 
        }
        // -----------------------------------------------------------

        // 3. Normal Collision Logic (Only when NOT Dashing)
        final playerLaneContent = row.lanes[playerLane];
        
        // A. Check for Invincibility
        bool isInvincible = activePowerups.values.any((p) => p.type == PowerupType.invincibility);
        if (isInvincible) {
          AchievementsService.instance.onObstaclePassedWhileInvincible();
          AudioService.instance.playSuccessSequence(); 
          row.passed = true;
          _obstaclesPassed++;
          continue; // Use continue to skip to the next row
        }
        
        // B. Check for Match/Mismatch
        if (playerLaneContent == currentShape) {
          // SUCCESS: Correct shape match
          AudioService.instance.playSuccessSequence();
          row.passed = true;
          _obstaclesPassed++;
          
          // Morph logic
          bool canMorph = !activePowerups.values.any((p) => p.type == PowerupType.shapeFreeze);
          if (canMorph && Random().nextBool()) {
            _morphToNextShape();
          }
          
        } else {
          // FAILURE: Wrong shape or Red skull 
          if (playerLaneContent == ObstacleContent.x) {
            _xObstaclesHit++;
            AudioService.instance.playCollisionWithHaptics(isX: true);
            _triggerDeath("You hit a Red skull!");
          } else {
            AudioService.instance.playCollisionWithHaptics(isX: false);
            _triggerDeath("Wrong shape! You needed ${GameData.getShapeName(currentShape)}");
          }
          // Death is final, exit immediately.
          return;
        }
      }
    }
  }
  
  void _morphToNextShape() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _shapeMorphCount++;
    _shapeUsageCount[currentShape] = (_shapeUsageCount[currentShape] ?? 0) + 1;
    if (gameState == GameState.playing && !isDead && _gameStarted) {
      setState(() {
        currentShape = GameData.getNextShape(currentShape);
      });
      
      // Play morph sound
      AudioService.instance.playShapeMorph();
      
      _shapeController.forward().then((_) => _shapeController.reset());
    }
  }

  void _handleObstacleInteraction(ObstacleRow row) {
    final playerLaneContent = row.lanes[playerLane];
    
    _obstaclesPassed++;
    
    if (playerLaneContent == currentShape) {
      // Play success sound
      AudioService.instance.playSuccessSequence();
      return;
    } else {
      // Check if invincibility is active
      bool isInvincible = activePowerups.values.any((p) => p.type == PowerupType.invincibility);
      if (isInvincible) {
        AchievementsService.instance.onObstaclePassedWhileInvincible();
        AudioService.instance.playSuccessSequence(); // Play success sound instead
        return; // Don't die while invincible
      }
      
      if (playerLaneContent == ObstacleContent.x) {
        _xObstaclesHit++;
        // Play X collision sound with haptics
        AudioService.instance.playCollisionWithHaptics(isX: true);
        _triggerDeath("You hit a Red skull!");
      } else {
        // Play shape collision sound with haptics
        AudioService.instance.playCollisionWithHaptics(isX: false);
        _triggerDeath("Wrong shape! You needed ${GameData.getShapeName(currentShape)}");
      }
      return;
    }
  }
  
  void _checkDashCollision() {
    final playerY = MediaQuery.of(context).size.height - 250;
    
    bool isInvincible = activePowerups.values.any((p) => p.type == PowerupType.invincibility);
    if(isInvincible)
    {
      return;
    }
    
    for (final row in obstacleRows) {
      if (row.y > playerY - 350 && row.y < playerY) {
        if (!row.passed) {
          // First check if there's a Red skull in the player's current lane
          if (row.lanes[playerLane] == ObstacleContent.x) {
            _xObstaclesHit++;
            _triggerDeath("You can't dash over a Red skull! Move to a different lane first!");
            return;
          }
          
          // UPDATED LOGIC: Dashing through your shape lane is now allowed
          // Only die if your shape is present in the row AND you're not in any of those lanes while dashing
          if (row.containsShape(currentShape)) {
            bool dashingThroughCorrectShape = row.lanes[playerLane] == currentShape;
            if (!dashingThroughCorrectShape) {
              // Find which lanes have the correct shape
              List<int> correctLanes = [];
              for (int i = 0; i < row.lanes.length; i++) {
                if (row.lanes[i] == currentShape) {
                  correctLanes.add(i + 1); // Convert to 1-based for user display
                }
              }
              _triggerDeath("You dashed but your shape was available in lane${correctLanes.length > 1 ? 's' : ''} ${correctLanes.join(' and ')}! You must go through it!");
              return;
            }
          }
        }
      }
    }
  }
  
  void _triggerDeath(String reason) {
    if (isDead) return;
    
    AudioService.instance.setGameMusicPlaybackRate(1.0); 

    if (GameData.vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      isDead = true;
      deathReason = reason;
      _gameStarted = false;
    });
    
    gameTimer?.cancel();
    
    if (_deathController.status == AnimationStatus.dismissed) {
      _deathController.forward().then((_) {
        _gameOver(reason);
      });
    } else {
      _gameOver(reason);
    }
  }
  
  void _gameOver(String reason) {
    final gameTime = DateTime.now().difference(gameStartTime).inSeconds.toDouble();
    GameData.addTimePlayed(gameTime);
    GameData.incrementGamesPlayed();
    
    final wasHighScore = score > GameData.highScore;
    GameData.setHighScore(score);
    
    // Track achievements
    AchievementsService.instance.onGameCompleted(
      score: score,
      gameTimeSeconds: gameTime,
      shapeMorphs: _shapeMorphCount,
      dashesUsed: _dashCount,
      obstaclesPassed: _obstaclesPassed,
      xObstaclesSeen: _xObstaclesSeen,
      xObstaclesHit: _xObstaclesHit,
      maxSpeed: _maxSpeedReached,
      wasNewHighScore: wasHighScore,
      shapeUsage: _shapeUsageCount,
      powerupsCollected: _powerupsCollected,
      powerupUsage: _powerupUsage,
      bonusPointsFromMultipliers: _bonusPointsFromMultipliers,
      usedAllPowerupTypes: _powerupTypesUsedThisGame.length == PowerupType.values.length,
      invincibleObstaclesPassed: _invincibleObstaclesPassed,
    );
    
    if (wasHighScore) {
      AudioService.instance.playNewHighScore();
    } else {
      AudioService.instance.playGameOver();
    }
    
    AdService.instance.onGameEnd();
    
    setState(() {
      gameState = GameState.gameOver;
    });
    
    _showGameOverDialog(reason, wasHighScore);
    
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _listenForAchievementNotifications();
      }
    });
  }
  
  // Update the _listenForAchievementNotifications method
  void _listenForAchievementNotifications() {
    final recentNotifications = AchievementsService.instance.recentNotifications;
    
    // FIXED: Show ALL new notifications with staggered timing
    int delayMultiplier = 0;
    for (final notification in recentNotifications) {
      if (notification.isNew) {
        // Show each notification with a staggered delay
        Future.delayed(Duration(milliseconds: 500 + (delayMultiplier * 1000)), () {
          if (mounted) {
            _showAchievementNotificationOverlay(notification.achievement);
          }
        });
        
        notification.isNew = false; // Mark as seen
        delayMultiplier++; // Increase delay for next notification
      }
    }
  }

  void _showAchievementNotificationOverlay(Achievement achievement) {
    // Create overlay entry that appears above all dialogs
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AchievementNotificationOverlay(
            achievement: achievement,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Play achievement sound
    AudioService.instance.playPowerUp();
    
    // Haptic feedback
    if (GameData.vibrateEnabled) {
      HapticFeedback.mediumImpact();
    }
    
    // Auto-remove after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showPauseDialog() {
    GameDialogs.showPauseDialog(
      context: context,
      score: score,
      gameSpeed: gameSpeed,
      currentShape: currentShape,
      onResume: () {
        AudioService.instance.playUIClick();
        setState(() {
          gameState = GameState.playing;
          _gameStarted = true;
        });
        _startGame();
      },
      onExitToHome: () {
        AudioService.instance.playUIClick();
        ScreenTransitions.replaceTo(
          context, 
          HomeScreen(), 
          type: TransitionType.slideFromLeft
        );
      },
    );
  }

  void _showGameOverDialog(String reason, bool wasHighScore) {
    GameDialogs.showGameOverDialog(
      context: context,
      reason: reason,
      score: score,
      wasHighScore: wasHighScore,
      onPlayAgain: () {
        _maybeShowInterstitialThenRestart();
      },
      onExitToHome: () {
        ScreenTransitions.replaceTo(
          context, 
          HomeScreen(), 
          type: TransitionType.slideFromLeft
        );
      },
      onWatchAd: (AdService.instance.isRewardedAdReady && score > 100 && !_hasUsedRevive) 
          ? () => _showReviveAd() 
          : null,
    );
  }

  void _showReviveAd() {
    AdService.instance.showRewardedAd(
      onUserEarnedReward: () {
        // Mark revive as used
        _hasUsedRevive = true;
      },
      onAdDismissed: () {
        // If user didn't complete the ad, show game over again
        if (!_hasUsedRevive) {
          final wasHighScore = score > GameData.highScore;
          AudioService.instance.startGameMusic();
          Navigator.of(context).pop();
          _showGameOverDialog(deathReason, wasHighScore);
        } else {
          // Show countdown overlay
          _showReviveCountdown();
        }
      },
    );
  }

  void _showReviveCountdown() {
    
    // Show countdown overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => _ReviveCountdownDialog(
        onComplete: () {
          Navigator.of(context).pop();
          _revivePlayer();
        },
      ),
    );
  }

  void _revivePlayer() {
    setState(() {
      // Reset death state
      isDead = false;
      deathReason = "";
      gameState = GameState.playing;
      
      // Reset death animation
      _deathController.reset();
      
      // Clear the obstacle that killed the player
      obstacleRows.removeWhere((row) {
        final playerY = MediaQuery.of(context).size.height - 250;
        return (row.y - playerY).abs() < 100;
      });
      
      // Give temporary invincibility (3 seconds)
      _activatePowerup(PowerupType.invincibility);
      
      // Resume game
      _gameStarted = true;
    });
    
    // Restart the game loop
    gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
    
    // Resume music
    AudioService.instance.startGameMusic();
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Revived! You have 3 seconds of invincibility!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _maybeShowInterstitialThenRestart() async {
    AdService.instance.onGameEnd(); // Set the flag for next interstitial

    bool adCompleted = await AdService.instance.showInterstitialAd();

    // Now restart the game
    if (mounted) {
      AudioService.instance.startGameMusic();
      _restartGame();
    }
  }

  void _restartGame() {
    setState(() {
      gameState = GameState.playing;
      score = 0;
      gameSpeed = GameData.baseGameSpeed;
      playerLane = 2;
      currentShape = GameData.getNextShape();
      obstacleRows.clear();
      powerupRows.clear();
      activePowerups.clear();
      cameraY = 0;
      nextObstacleId = 0;
      isDashing = false;
      isDead = false;
      deathReason = "";
      gameStartTime = DateTime.now();
      _gameStarted = false;
      _hasUsedRevive = false; // Reset revive flag
    
      // Reset achievement tracking
      _shapeMorphCount = 0;
      _dashCount = 0;
      _obstaclesPassed = 0;
      _xObstaclesSeen = 0;
      _xObstaclesHit = 0;
      _maxSpeedReached = 0.0;
      _achievementOverlays.clear();
      _powerupsCollected = 0;
      _powerupUsage.clear();
      for (final type in PowerupType.values) {
        _powerupUsage[type] = 0;
      }
      _bonusPointsFromMultipliers = 0;
      _powerupTypesUsedThisGame.clear();
      _invincibleObstaclesPassed = 0;
      for (final shape in PlayerShape.values) {
        _shapeUsageCount[shape] = 0;
      }
    });
    
    _dashController.reset();
    _deathController.reset();
    _shapeController.reset();
    
    // Delay initialization to ensure proper restart
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _initializeObstacles();
        _startGame();
      }
    });
  }

  // IMPROVED MOVEMENT - More sensitive gestures
  void _moveLeft() {
    if (playerLane > 0 && !isDashing && !isDead && !_hasMovedThisGesture && _gameStarted) {
      setState(() {
        playerLane--;
        _hasMovedThisGesture = true;
      });
      
      // Play movement sound
      AudioService.instance.playPlayerMove();
      
      if (GameData.vibrateEnabled) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _moveRight() {
    if (playerLane < GameData.lanesCount - 1 && !isDashing && !isDead && !_hasMovedThisGesture && _gameStarted) {
      setState(() {
        playerLane++;
        _hasMovedThisGesture = true;
      });
      
      // Play movement sound
      AudioService.instance.playPlayerMove();
      
      if (GameData.vibrateEnabled) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _dash() {
    if (!isDashing && !isDead && _gameStarted) {
      _dashCount++;
      
      // Calculate dash duration based on current speed
      final currentSpeed = gameSpeed * (isDashing ? _dashSpeedAnimation.value : 1.0);
      final dashDuration = (dashDistance / currentSpeed * 16).round(); // 16ms per frame
      final clampedDuration = dashDuration.clamp(100, 800); // Min 100ms, max 800ms
      
      setState(() {
        isDashing = true;
        dashStartCameraY = cameraY; // Record where dash started
      });
      
      // Play dash sound
      AudioService.instance.playPlayerDash();
      
      if (GameData.vibrateEnabled) {
        HapticFeedback.mediumImpact();
      }
      
      _checkDashCollision();
      
      // Update animation controller duration based on speed
      _dashController.duration = Duration(milliseconds: clampedDuration);

      // NEW LOGIC: Only morph if dashing through an available shape lane (optional dash)
      // Don't morph if there's no shape in the row (forced dash)
      bool shouldMorph = _shouldMorphOnDash();
      bool canMorph = !activePowerups.values.any((p) => p.type == PowerupType.shapeFreeze);
      
      if (shouldMorph && canMorph && Random().nextBool()) {
        _morphToNextShape();
      }

      // Start dash animation
      _dashController.forward().then((_) {
        _dashController.reverse().then((_) {
          if (mounted) {
            setState(() {
              isDashing = false;
            });
          }
        });
      });
      
      // IMPORTANT: End dash when distance is covered, not just animation
      _endDashWhenDistanceCovered();
    }
  }
  
  // Helper method to determine if we should morph after dashing
  bool _shouldMorphOnDash() {
    // Check upcoming obstacles to see if player's shape is available
    final playerY = MediaQuery.of(context).size.height - 250;
    
    for (final row in obstacleRows) {
      // Look at obstacles in the dash range
      if (row.y > playerY - 350 && row.y < playerY) {
        if (!row.passed && row.containsShape(currentShape)) {
          // Player's shape is available in this row, so this was an optional dash
          return true;
        }
      }
    }
    
    // No shape available means this was a forced dash, don't morph
    return false;
  }

  void _endDashWhenDistanceCovered() {
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!isDashing || isDead || !_gameStarted) {
        timer.cancel();
        return;
      }
      
      final distanceCovered = cameraY - dashStartCameraY;
      
      if (distanceCovered >= dashDistance) {
        timer.cancel();
        
        // End dash immediately regardless of animation state
        if (mounted) {
          setState(() {
            isDashing = false;
          });
          
          // Reset animations if they're still running
          if (_dashController.isAnimating) {
            _dashController.reset();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: GestureDetector(
          onPanStart: (details) {
            _hasMovedThisGesture = false;
          },
          onPanUpdate: (details) {
            if (!_hasMovedThisGesture && _gameStarted) {
              // IMPROVED: More sensitive horizontal movement
              if (details.delta.dx.abs() > details.delta.dy.abs()) {
                if (details.delta.dx > _swipeThreshold) {
                  _moveRight();
                } else if (details.delta.dx < -_swipeThreshold) {
                  _moveLeft();
                }
              } 
              // IMPROVED: More sensitive dash
              else if (details.delta.dy < -_dashThreshold) {
                _dash();
                _hasMovedThisGesture = true;
              }
            }
          },
          child: Stack(
            children: [
              _buildGameLanes(),
              ...obstacleRows.map((row) => _buildObstacleRow(row)),
              ...powerupRows.map((powerupRow) => _buildPowerupRow(powerupRow)),
              _buildPlayer(),
              _buildGameUI(),
              _buildPowerupIndicators(),
              ..._achievementOverlays,
              
              // Banner ad at bottom - always visible during gameplay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: AdService.instance.isGameBannerAdReady ? 50 : 0,
                  color: Colors.black87.withOpacity(0.8),
                  child: AdService.instance.isGameBannerAdReady 
                      ? Center(child: AdService.instance.getGameBannerAdWidget() ?? SizedBox.shrink())
                      : SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // POWERUP UI METHODS
  Widget _buildPowerupRow(PowerupRow powerupRow) {
    final screenWidth = MediaQuery.of(context).size.width;
    final laneWidth = screenWidth / GameData.lanesCount;
    
    return Positioned(
      top: powerupRow.y,
      left: laneWidth * powerupRow.lane,
      child: Container(
        width: laneWidth,
        height: 60,
        child: Center(
          child: _buildPowerupIcon(powerupRow.type),
        ),
      ),
    );
  }
  
  Widget _buildPowerupIcon(PowerupType type) {
    final powerupInfo = _getPowerupInfo(type);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: powerupInfo['color'].withOpacity(0.9),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: powerupInfo['color'].withOpacity(0.6),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          powerupInfo['icon'],
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Map<String, dynamic> _getPowerupInfo(PowerupType type) {
    switch (type) {
      case PowerupType.slowMotion:
        return {
          'icon': Icons.slow_motion_video,
          'color': Colors.blue,
          'name': 'Slow Motion',
          'description': 'Slows down time',
        };
      case PowerupType.scoreMultiplier:
        return {
          'icon': Icons.star,
          'color': Colors.yellow,
          'name': 'Score Boost',
          'description': '2x score for 8 seconds',
        };
      case PowerupType.shapeFreeze:
        return {
          'icon': Icons.lock,
          'color': Colors.cyan,
          'name': 'Shape Lock',
          'description': 'Prevents shape morphing',
        };
      case PowerupType.invincibility:
        return {
          'icon': Icons.shield,
          'color': Colors.green,
          'name': 'Shield',
          'description': 'Temporary invincibility',
        };
      case PowerupType.speedBoost:
        return {
          'icon': Icons.flash_on,
          'color': Colors.orange,
          'name': 'Speed Boost',
          'description': 'Increases game speed',
        };
    }
  }
  
  Widget _buildPowerupIndicators() {
    if (activePowerups.isEmpty) return SizedBox.shrink();
    
    return Positioned(
      top: 100,
      right: 20,
      child: Column(
        children: activePowerups.values.map((powerup) {
          final info = _getPowerupInfo(powerup.type);
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info['color'].withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  info['icon'],
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  '${powerup.getRemainingTime()}s',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildGameLanes() {
    final screenWidth = MediaQuery.of(context).size.width;
    final laneWidth = screenWidth / GameData.lanesCount;
    
    return Positioned.fill(
      child: Row(
        children: List.generate(GameData.lanesCount, (index) {
          return Container(
            width: laneWidth,
            decoration: BoxDecoration(
              border: Border(
                left: index > 0 ? BorderSide(color: Colors.white24, width: 1) : BorderSide.none,
                right: index < GameData.lanesCount - 1 ? BorderSide(color: Colors.white24, width: 1) : BorderSide.none,
              ),
            ),
            child: Container(
              color: index == playerLane ? Colors.white.withOpacity(0.05) : Colors.transparent,
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildObstacleRow(ObstacleRow row) {
    final screenWidth = MediaQuery.of(context).size.width;
    final laneWidth = screenWidth / GameData.lanesCount;
    
    return Positioned(
      top: row.y,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        child: Row(
          children: List.generate(GameData.lanesCount, (laneIndex) {
            return Container(
              width: laneWidth,
              child: _buildObstacleLane(row.lanes[laneIndex]),
            );
          }),
        ),
      ),
    );
  }
  
  Widget _buildObstacleLane(dynamic content) {
    final isHighlighted = isDead;
    
    if (content == ObstacleContent.x) {
      _xObstaclesSeen++;
      return AnimatedBuilder(
        animation: _deathAnimation,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlighted ? 
                Colors.black.withOpacity(0.3 + 0.7 * (1 - _deathAnimation.value)) : 
                Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              border: isHighlighted ? Border.all(
                color: Colors.white.withOpacity(_deathAnimation.value), 
                width: 4 * _deathAnimation.value
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(isHighlighted ? 0.8 * _deathAnimation.value : 0.5),
                  blurRadius: isHighlighted ? 20 * _deathAnimation.value : 8,
                  spreadRadius: isHighlighted ? 6 * _deathAnimation.value : 2,
                ),
              ],
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.skull,
                color: const Color.fromARGB(255, 133, 0, 0),
                size: 35,
              ),
            ),
          );
        },
      );
    } else if (content is PlayerShape) {
      final color = GameData.getShapeColor(content);
      return AnimatedBuilder(
        animation: _deathAnimation,
        builder: (context, child) {
          return Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isHighlighted ? 
                  Colors.white.withOpacity(_deathAnimation.value) : 
                  color, 
                width: isHighlighted ? 5 * _deathAnimation.value : 3
              ),
              borderRadius: BorderRadius.circular(15),
              color: isHighlighted ? 
                color.withOpacity(0.15 + 0.65 * (1 - _deathAnimation.value)) : 
                color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isHighlighted ? 0.7 * _deathAnimation.value : 0.4),
                  blurRadius: isHighlighted ? 20 * _deathAnimation.value : 8,
                  spreadRadius: isHighlighted ? 5 * _deathAnimation.value : 1,
                ),
              ],
            ),
            child: Center(
              child: ShapeWidget(
                shape: content,
                size: 35,
                animate: false,
              ),
            ),
          );
        },
      );
    }
    
    return Container();
  }
  
  Widget _buildPlayer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final laneWidth = screenWidth / GameData.lanesCount;
    final playerX = laneWidth * playerLane + laneWidth / 2 - 30;

    bool isInvincible = activePowerups.values.any((p) => p.type == PowerupType.invincibility);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _dashSpeedAnimation, 
        _dashGlowAnimation, 
        _dashBlurAnimation,
        _deathAnimation,
        _deathRotationAnimation
      ]),
      builder: (context, child) {
        return Positioned(
          left: playerX,
          bottom: AdService.instance.isBannerAdReady ? 250 : 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              
              // THE PLAYER SHAPE
              Transform.scale(
                scale: isDead ? _deathAnimation.value : 1.0,
                child: Transform.rotate(
                  angle: isDead ? _deathRotationAnimation.value : 0.0,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      boxShadow: [
                        if (isDashing) ...[
                          BoxShadow(
                            color: GameData.getShapeColor(currentShape).withOpacity(0.9),
                            blurRadius: _dashBlurAnimation.value * (gameSpeed / GameData.baseGameSpeed),
                            spreadRadius: _dashGlowAnimation.value * 12 * (gameSpeed / GameData.baseGameSpeed),
                          ),
                          BoxShadow(
                            color: GameData.getShapeColor(currentShape).withOpacity(0.6),
                            blurRadius: _dashBlurAnimation.value * 3 * (gameSpeed / GameData.baseGameSpeed),
                            spreadRadius: _dashGlowAnimation.value * 20 * (gameSpeed / GameData.baseGameSpeed),
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: _dashBlurAnimation.value * 2,
                            spreadRadius: _dashGlowAnimation.value * 8,
                          ),
                        ],
                      ],
                    ),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.3).animate(_shapeController),
                      child: ShapeWidget(
                        shape: currentShape,
                        size: 60,
                        animate: false,
                        customColor: null,
                      ),
                    ),
                  ),
                ),
              ),
              
              // RANK INFO BELOW PLAYER
              if (!isDead && _showRankOutline)
                Positioned(
                  left: -20, // Center it (60 width player + padding)
                  top: 65, // Position above player
                  child: Container(
                    width: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rank badge and title
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: _currentRank.color.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _currentRank.glowColor, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: _currentRank.glowColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentRank.emblem,
                                color: Colors.white,
                                size: 14,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              SizedBox(width: 3),
                              Text(
                                _currentRank.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // POWER-UP ICONS OVERLAY
              if (activePowerups.isNotEmpty && !isDead) 
                Positioned(
                  left: 15,
                  top: -30,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: activePowerups.values.map((powerup) {
                      final info = _getPowerupInfo(powerup.type);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Container(
                          width: 30, 
                          height: 30, 
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: info['color'].withOpacity(0.8),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: info['color'].withOpacity(0.9),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              info['icon'],
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildGameUI() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score: $score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'Shape: ',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        ShapeWidget(
                          shape: currentShape,
                          size: 25,
                          animate: false,
                        ),
                      ],
                    ),
                  ],
                ),
                if (!isDead && _gameStarted)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        gameState = GameState.paused;
                        _gameStarted = false;
                      });
                      gameTimer?.cancel();
                      _showPauseDialog();
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _shapeController.dispose();
    _dashController.dispose();
    _deathController.dispose();
    
    // Switch back to menu music when leaving game
    AudioService.instance.crossfadeToMenuMusic();
    
    // FIXED: Proper game screen disposal
    AdService.instance.onGameScreenDisposed();
    super.dispose();
  }
}

class _ReviveCountdownDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const _ReviveCountdownDialog({
    required this.onComplete,
  });
  
  @override
  _ReviveCountdownDialogState createState() => _ReviveCountdownDialogState();
}

class _ReviveCountdownDialogState extends State<_ReviveCountdownDialog> 
    with SingleTickerProviderStateMixin {
  int _countdown = 3;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _startCountdown();
  }
  
  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
        AudioService.instance.playUIClick();
        if (GameData.vibrateEnabled) {
          HapticFeedback.lightImpact();
        }
      } else {
        timer.cancel();
        AudioService.instance.playPowerUp();
        if (GameData.vibrateEnabled) {
          HapticFeedback.mediumImpact();
        }
        Future.delayed(Duration(milliseconds: 500), () {
          widget.onComplete();
        });
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 300,
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade800.withOpacity(0.95),
              Colors.green.shade600.withOpacity(0.95),
              Colors.lightGreen.shade400.withOpacity(0.95),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.lightGreen.shade300,
                    Colors.green.shade500,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.lightGreen.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              'REVIVING!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30),
            
            // Countdown number
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            Text(
              '+ 3s Invincibility',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// POWERUP CLASSES
enum PowerupType {
  slowMotion,
  scoreMultiplier,
  shapeFreeze,
  invincibility,
  speedBoost,
}

// POWERUP CLASSES
// ... (other enums and classes)

class Powerup {
  final PowerupType type;
  final double multiplier;
  
  // Use a map key that is the type itself, not a unique ID
  final String id; // Keeping this for consistency, but its value is now predictable (e.g., type.toString())

  DateTime _expirationTime; // Changed to be mutable
  
  Powerup({
    required this.id, // e.g., PowerupType.slowMotion.toString()
    required this.type,
    required int duration, // initial duration in seconds
    required this.multiplier,
  }) : _expirationTime = DateTime.now().add(Duration(seconds: duration));

  // New method to extend the powerup duration
  void extendDuration(int seconds) {
    // If the powerup is already expired, reset the start time to now.
    // Otherwise, add the seconds to the current expiration time.
    if (DateTime.now().isAfter(_expirationTime)) {
      _expirationTime = DateTime.now().add(Duration(seconds: seconds));
    } else {
      _expirationTime = _expirationTime.add(Duration(seconds: seconds));
    }
  }

  int getRemainingTime() {
    return math.max(0, _expirationTime.difference(DateTime.now()).inSeconds);
  }

  bool get isExpired => getRemainingTime() <= 0;
}

class PowerupRow {
  double y;
  double cameraY;
  int lane;
  PowerupType type;
  bool collected = false;

  PowerupRow({
    required this.y,
    required this.lane,
    required this.type,
    required this.cameraY,
  });
}

class ObstacleRow {
  double y;
  double cameraY;
  int id;
  List<dynamic> lanes;
  bool passed = false;
  
  ObstacleRow({required this.y, required this.id, required this.cameraY}) 
    : lanes = List.filled(GameData.lanesCount, null);
  
  bool containsShape(PlayerShape shape) {
    return lanes.contains(shape);
  }
}

enum ObstacleContent { x }

class RankDisplaySettings {
  static bool _showRankOutline = true;
  
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _showRankOutline = prefs.getBool('show_rank_outline') ?? true;
  }
  
  static bool get showRankOutline => _showRankOutline;
  
  static Future<void> setShowRankOutline(bool value) async {
    _showRankOutline = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_rank_outline', value);
  }
}