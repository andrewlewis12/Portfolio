import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/ad_service.dart';
import '../utils/game_data.dart';
import '../widgets/shape_widget.dart';

class GameDialogs {
  
  /// Modern pause dialog with glassmorphism effects
  static void showPauseDialog({
    required BuildContext context,
    required int score,
    required double gameSpeed,
    required PlayerShape currentShape,
    required VoidCallback onResume,
    required VoidCallback onExitToHome,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade800.withOpacity(0.95),
                  Colors.purple.shade600.withOpacity(0.95),
                  Colors.pink.shade400.withOpacity(0.95),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with animated icon
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Animated pause icon with glow
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyan.shade300,
                              Colors.blue.shade400,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyan.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'GAME PAUSED',
                        style: TextStyle(
                          fontSize: 24,
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
                    ],
                  ),
                ),
                
                // Content section
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Current stats with modern cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'SCORE',
                              '$score',
                              Icons.stars,
                              Colors.yellow.shade600,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'SPEED',
                              '${gameSpeed.toStringAsFixed(1)}x',
                              Icons.speed,
                              Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Current shape display
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(
                            color: GameData.getShapeColor(currentShape).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShapeWidget(
                              shape: currentShape,
                              size: 35,
                              animate: true,
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Shape',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  GameData.getShapeName(currentShape),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Action buttons with modern design
                      Column(
                        children: [
                          _buildModernButton(
                            'RESUME GAME',
                            Icons.play_arrow,
                            Colors.green,
                            () {
                              AudioService.instance.playUIClick();
                              Navigator.of(context).pop();
                              onResume();
                            },
                            isPrimary: true,
                          ),
                          
                          SizedBox(height: 12),
                          
                          _buildModernButton(
                            'EXIT TO HOME',
                            Icons.home,
                            Colors.red.shade400,
                            () { 
                              AudioService.instance.playUIClick();
                              Navigator.of(context).pop();
                              onExitToHome();
                            },
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modern game over dialog with dramatic effects - Fixed overflow
  static void showGameOverDialog({
    required BuildContext context,
    required String reason,
    required int score,
    required bool wasHighScore,
    required VoidCallback onPlayAgain,
    required VoidCallback onExitToHome,
    VoidCallback? onWatchAd,
  }) {
    final wouldMakeLeaderboard = LeaderboardService.instance.wouldMakeLeaderboard(score);
    final wouldImprove = LeaderboardService.instance.wouldImproveLeaderboard(score);
    final canSubmit = LeaderboardService.instance.canSubmitScore();
    final showRewardAd = AdService.instance.isRewardedAdReady && score > 100 && onWatchAd != null;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 340,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900.withOpacity(0.98),
                  Colors.deepPurple.shade700.withOpacity(0.98),
                  Colors.purple.shade500.withOpacity(0.98),
                ],
              ),
              border: Border.all(
                color: wasHighScore 
                    ? Colors.yellow.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: wasHighScore 
                      ? Colors.yellow.withOpacity(0.3)
                      : Colors.purple.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 8,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dramatic header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          wasHighScore 
                              ? Colors.yellow.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated icon with dramatic effect
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: wasHighScore
                                  ? [
                                      Colors.yellow.shade300,
                                      Colors.orange.shade500,
                                    ]
                                  : [
                                      Colors.red.shade400,
                                      Colors.red.shade700,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: wasHighScore 
                                    ? Colors.yellow.withOpacity(0.8)
                                    : Colors.red.withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            wasHighScore ? Icons.emoji_events : Icons.close,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Title with dramatic typography
                        Text(
                          wasHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: wasHighScore ? Colors.yellow.shade300 : Colors.red.shade300,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        
                        if (wasHighScore) ...[
                          SizedBox(height: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.yellow.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.yellow.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              '🎉 AMAZING! 🎉',
                              style: TextStyle(
                                color: Colors.yellow.shade200,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Content section
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Death reason with stylized container
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.3),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Score display with modern cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildGameOverStatCard(
                                'FINAL SCORE',
                                '$score',
                                Icons.stars,
                                wasHighScore ? Colors.yellow.shade600 : Colors.cyan,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildGameOverStatCard(
                                'HIGH SCORE',
                                '${GameData.highScore}',
                                Icons.emoji_events,
                                Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Leaderboard status - only show most relevant
                        if (canSubmit && (wouldMakeLeaderboard || wouldImprove))
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.cyan.withOpacity(0.2),
                                  Colors.blue.withOpacity(0.2),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.cyan.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.leaderboard, color: Colors.cyan, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wouldImprove ? 'Leaderboard Improvement!' : 'Leaderboard Eligible!',
                                        style: TextStyle(
                                          color: Colors.cyan,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Submit from home screen',
                                        style: TextStyle(
                                          color: Colors.cyan.shade300,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (!canSubmit)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.orange.withOpacity(0.15),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.schedule, color: Colors.orange, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Already submitted today',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Come back tomorrow',
                                        style: TextStyle(
                                          color: Colors.orange.shade300,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Revive ad section - compact
                        if (AdService.instance.isRewardedAdReady && score > 100) ...[
                          SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: onWatchAd != null
                                    ? [
                                        Colors.green.shade800.withOpacity(0.3),
                                        Colors.green.shade600.withOpacity(0.3),
                                      ]
                                    : [
                                        Colors.grey.shade800.withOpacity(0.3),
                                        Colors.grey.shade600.withOpacity(0.3),
                                      ],
                              ),
                              border: Border.all(
                                color: onWatchAd != null
                                    ? Colors.green.shade600.withOpacity(0.6)
                                    : Colors.grey.shade600.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  onWatchAd != null ? Icons.favorite : Icons.check_circle,
                                  color: onWatchAd != null ? Colors.green.shade300 : Colors.grey.shade400,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        onWatchAd != null ? 'REVIVE AVAILABLE!' : 'REVIVE USED',
                                        style: TextStyle(
                                          color: onWatchAd != null ? Colors.green.shade300 : Colors.grey.shade400,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        onWatchAd != null ? 'Continue from death' : 'One per game',
                                        style: TextStyle(
                                          color: onWatchAd != null ? Colors.green.shade200 : Colors.grey.shade500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 18),
                        
                        // Action buttons - compact spacing
                        Column(
                          children: [
                            if (showRewardAd)
                              _buildModernButton(
                                'REVIVE (WATCH AD)',
                                Icons.favorite,
                                Colors.green.shade700,
                                () { 
                                  AudioService.instance.playUIClick();
                                  Navigator.of(context).pop();
                                  onWatchAd();
                                },
                                isPrimary: true,
                              )
                            else if (AdService.instance.isRewardedAdReady && score > 100)
                              _buildModernButton(
                                'REVIVE USED',
                                Icons.check_circle,
                                Colors.grey.shade600,
                                () {}, // Disabled
                                isPrimary: false,
                                isDisabled: true,
                              ),
                            
                            if (AdService.instance.isRewardedAdReady && score > 100)
                              SizedBox(height: 10),
                            
                            _buildModernButton(
                              'PLAY AGAIN',
                              Icons.refresh,
                              Colors.green,
                              () { 
                                AudioService.instance.playUIClick();
                                Navigator.of(context).pop();
                                onPlayAgain();
                              },
                              isPrimary: !showRewardAd,
                            ),
                            
                            SizedBox(height: 10),
                            
                            _buildModernButton(
                              'HOME',
                              Icons.home,
                              Colors.grey.shade600,
                              () { 
                                AudioService.instance.playUIClick();
                                Navigator.of(context).pop();
                                onExitToHome();
                              },
                              isPrimary: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for stat cards in pause dialog
  static Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for stat cards in game over dialog - more compact
  static Widget _buildGameOverStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildModernButton(
    String text, 
    IconData icon, 
    Color color, 
    VoidCallback onPressed,
    {bool isPrimary = false, bool isDisabled = false}
  ) {
    return Container(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled 
              ? Colors.grey.shade800.withOpacity(0.3)
              : (isPrimary ? color : color.withOpacity(0.1)),
          foregroundColor: isDisabled 
              ? Colors.grey.shade600
              : (isPrimary ? Colors.white : color),
          elevation: isDisabled ? 0 : (isPrimary ? 6 : 3),
          shadowColor: isPrimary ? color.withOpacity(0.5) : color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary 
                ? BorderSide.none 
                : BorderSide(
                    color: isDisabled ? Colors.grey.shade700 : color.withOpacity(0.7), 
                    width: 1.5,
                  ),
          ),
          disabledBackgroundColor: Colors.grey.shade800.withOpacity(0.3),
          disabledForegroundColor: Colors.grey.shade600,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}