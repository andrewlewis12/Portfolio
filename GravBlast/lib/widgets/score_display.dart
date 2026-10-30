import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';

class GravBlastScoreDisplay extends StatefulWidget {
  const GravBlastScoreDisplay({Key? key}) : super(key: key);

  @override
  State<GravBlastScoreDisplay> createState() => _GravBlastScoreDisplayState();
}

class _GravBlastScoreDisplayState extends State<GravBlastScoreDisplay> 
    with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _highScoreController;
  late AnimationController _pulseController;
  late AnimationController _levelController;
  late AnimationController _shareController;
  int _previousScore = 0;
  int _previousHighScore = 0;
  int _previousLevel = 1;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _highScoreController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _shareController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _scoreController.dispose();
    _highScoreController.dispose();
    _pulseController.dispose();
    _levelController.dispose();
    _shareController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        // Trigger score animation
        if (gameService.score != _previousScore) {
          _scoreController.forward().then((_) => _scoreController.reverse());
          _previousScore = gameService.score;
        }
        
        // Trigger high score animation
        if (gameService.highScore != _previousHighScore && 
            gameService.highScore > _previousHighScore) {
          _highScoreController.forward().then((_) => _highScoreController.reverse());
          _previousHighScore = gameService.highScore;
        }
        
        // Trigger level up animation
        if (gameService.level != _previousLevel) {
          _levelController.forward().then((_) => _levelController.reverse());
          _previousLevel = gameService.level;
        }
        
        return Column(
          children: [
            // High Score Display with Share Button
            _buildHighScoreDisplay(gameService),
            
            const SizedBox(height: 6),
            
            // Current Score Display (made more compact)
            _buildCurrentScoreDisplay(gameService),
          ],
        );
      },
    );
  }
  
  Widget _buildHighScoreDisplay(GravBlastService gameService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_highScoreController, _pulseController, _shareController]),
      builder: (context, child) {
        final scale = 1.0 + (_highScoreController.value * 0.15);
        final isNewHighScore = gameService.score == gameService.highScore && 
                             gameService.score > 0;
        final pulseScale = isNewHighScore 
            ? 1.0 + (_pulseController.value * 0.05)
            : 1.0;
        final shareScale = 1.0 + (_shareController.value * 0.1);
        
        return Transform.scale(
          scale: scale * pulseScale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNewHighScore 
                    ? [Colors.amber.shade600, Colors.orange.shade600]
                    : [Colors.grey.shade700, Colors.grey.shade800],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isNewHighScore 
                    ? Colors.amber.withOpacity(0.8)
                    : Colors.cyan.withOpacity(0.3),
                width: isNewHighScore ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isNewHighScore 
                      ? Colors.amber.withOpacity(0.6)
                      : Colors.cyan.withOpacity(0.2),
                  blurRadius: isNewHighScore ? 15 : 8,
                  offset: const Offset(0, 3),
                ),
                if (isNewHighScore)
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNewHighScore ? Icons.emoji_events : Icons.military_tech,
                  color: isNewHighScore ? Colors.white : Colors.cyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'HIGH SCORE: ${_formatScore(gameService.highScore)}',
                  style: TextStyle(
                    color: isNewHighScore ? Colors.white : Colors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                
                // Share button (only show if high score > 0)
                if (gameService.highScore > 0) ...[
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: shareScale,
                    child: GestureDetector(
                      onTap: () => _shareHighScore(gameService.highScore),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.share,
                          color: isNewHighScore ? Colors.white : Colors.cyan,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                
                if (isNewHighScore) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.new_releases,
                    color: Colors.white,
                    size: 14,
                  ).animate(controller: _pulseController)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
                    .then()
                    .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCurrentScoreDisplay(GravBlastService gameService) {
    return AnimatedBuilder(
      animation: _scoreController,
      builder: (context, child) {
        final scale = 1.0 + (_scoreController.value * 0.08);
        
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.cyan.shade600,
                  Colors.blue.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyan.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatScore(gameService.score),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Future<void> _shareHighScore(int highScore) async {
    // Play UI click sound
    context.read<AudioService>().playUIClick();
    
    // Animate share button
    _shareController.forward().then((_) => _shareController.reverse());
    
    // Generate the share text
    final shareText = _generateShareText(highScore);
    
    try {
      // Try to share with app store link if published
      await Share.share(
        shareText,
        subject: 'Check out my Grav Blast high score!',
      );
    } catch (e) {
      // Fallback to simple text share
      _showShareDialog(shareText);
    }
  }
  
  String _generateShareText(int highScore) {
    final formattedScore = _formatScore(highScore);
    
    // Different messages based on score level
    String message;
    String emoji;
    
    if (highScore >= 100000) {
      message = "I'm absolutely crushing it in Grav Blast! 🔥";
      emoji = "🏆";
    } else if (highScore >= 50000) {
      message = "I'm getting seriously good at Grav Blast! 💪";
      emoji = "⭐";
    } else if (highScore >= 25000) {
      message = "Check out my awesome Grav Blast skills! 🎯";
      emoji = "🚀";
    } else if (highScore >= 10000) {
      message = "I'm mastering the art of Grav Blast! 🎮";
      emoji = "⚡";
    } else {
      message = "I'm having a blast with Grav Blast! 🎲";
      emoji = "🎯";
    }
    
    // App store links (will be updated when published)
    const String appStoreLink = "https://apps.apple.com/app/grav-blast"; // Replace when published
    const String playStoreLink = "https://play.google.com/store/apps/details?id=com.paconotgames.grav_blast"; // Replace when published
    
    // Try to detect platform and use appropriate link
    final String appLink = _getAppStoreLink();
    
    return "$message\n\n"
           "$emoji My High Score: $formattedScore points!\n\n"
           "Think you can beat me? Download Grav Blast and prove it! 💪\n\n"
           "🎮 Clear • Blast • Dominate\n"
           "$appLink\n\n"
           "#GravBlast #PuzzleGame #HighScore #Challenge";
  }
  
  String _getAppStoreLink() {
    // For now, return website link. Replace with actual store links when published
    return "Early Access at: https://paconotenterprises.com/grav_blast?invite-link=true";
    
    // When published, uncomment and use:
    // if (Platform.isIOS) {
    //   return "https://apps.apple.com/app/grav-blast";
    // } else if (Platform.isAndroid) {
    //   return "https://play.google.com/store/apps/details?id=com.paconotenterprises.gravblast";
    // } else {
    //   return "https://paconotenterprises.com";
    // }
  }
  
  void _showShareDialog(String shareText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.cyan.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.cyan, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Share Your Score',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: SelectableText(
                shareText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap and hold to copy the text above, then share it wherever you want! 📱',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close, color: Colors.white70, size: 18),
            label: const Text(
              'Close',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
              
              // Try to launch website
              try {
                final Uri uri = Uri.parse('https://paconotenterprises.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                // Silently fail - user can still copy the text
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(Icons.language, size: 18),
            label: const Text(
              'Visit Website',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}