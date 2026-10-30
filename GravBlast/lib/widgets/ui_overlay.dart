import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../screens/menu_screen.dart';

class GravBlastUIOverlay extends StatelessWidget {
  const GravBlastUIOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        // NEW: Show "No More Moves" animation first
        if (gameService.isShowingGameOverAnimation) {
          return _buildNoMoreMovesOverlay(context, gameService);
        }
        
        if (gameService.isGameOver) {
          if (gameService.shouldShowRewardedAdOnDeath) {
            return _buildRewardedAdOverlay(context, gameService);
          } else {
            return _buildGameOverOverlay(context, gameService);
          }
        }
        
        if (gameService.isAnimating) {
          return _buildAnimatingOverlay();
        }
        
        // Show combo overlay if combo > 1 and should show
        if (gameService.shouldShowCombo && gameService.combo > 1) {
          return _buildComboOverlay(gameService.combo, context);
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  // NEW: "No More Moves" animation overlay
  Widget _buildNoMoreMovesOverlay(BuildContext context, GravBlastService gameService) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B0000), // Dark red
                Color(0xFFFF4500), // Orange red
                Color(0xFFDC143C), // Crimson
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withOpacity(0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon with pulsing animation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: const Icon(
                  Icons.warning,
                  color: Colors.white,
                  size: 48,
                ),
              ).animate(autoPlay: true)
                .scale(duration: 400.ms, curve: Curves.easeOut)
                .then()
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.2, 1.2),
                  duration: 500.ms,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                )
                .animate(onComplete: (controller) => controller.repeat()),
              
              const SizedBox(height: 24),
              
              // Title with dramatic animation
              const Text(
                'NO MORE MOVES!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ).animate(autoPlay: true)
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.3, end: 0)
                .then()
                .shimmer(
                  duration: 800.ms,
                  color: Colors.red.withOpacity(0.5),
                ),
              
              const SizedBox(height: 16),
              
              // Explanation text
              const Text(
                'None of your pieces can be placed on the grid.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ).animate(autoPlay: true)
                .fadeIn(delay: 500.ms, duration: 400.ms),
              
              const SizedBox(height: 24),
              
              // Animated pieces indication
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.extension,
                      color: Colors.red,
                      size: 24,
                    ).animate(autoPlay: true)
                      .scale(
                        duration: 600.ms,
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.2, 1.2),
                      )
                      .then()
                      .scale(
                        duration: 600.ms,
                        begin: const Offset(1.2, 1.2),
                        end: const Offset(0.8, 0.8),
                      )
                      .animate(onComplete: (controller) => controller.repeat()),
                    
                    const SizedBox(width: 12),
                    
                    Text(
                      '${gameService.availablePieces.length} pieces blocked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate(autoPlay: true)
                .fadeIn(delay: 800.ms, duration: 400.ms)
                .slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComboOverlay(int combo, BuildContext context) {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        final comboText = gameService.getComboText();
        final isCascade = gameService.lastCascadeCycles > 1;
        
        // FIXED: Make combo more prominent and colorful
        Color primaryColor;
        Color secondaryColor;
        double scale;
        
        if (combo >= 10) {
          primaryColor = Colors.purple;
          secondaryColor = Colors.pink;
          scale = 1.4;
        } else if (combo >= 7) {
          primaryColor = Colors.red;
          secondaryColor = Colors.orange;
          scale = 1.3;
        } else if (combo >= 5) {
          primaryColor = Colors.orange;
          secondaryColor = Colors.yellow;
          scale = 1.2;
        } else {
          primaryColor = Colors.blue;
          secondaryColor = Colors.cyan;
          scale = 1.1;
        }
        
        return Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCascade ? [
                      primaryColor.withOpacity(0.95),
                      secondaryColor.withOpacity(0.95),
                      Colors.white.withOpacity(0.9),
                    ] : [
                      primaryColor.withOpacity(0.95),
                      secondaryColor.withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.8),
                      blurRadius: 25,
                      offset: const Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.6),
                      blurRadius: 35,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FIXED: Much more prominent combo text
                    Text(
                      'COMBO x$combo!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32 + (combo * 1.5).clamp(0, 16), // Gets bigger with higher combo
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: primaryColor,
                            offset: Offset(0, 0),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                    ),
                    
                    // FIXED: Show bonus points if combo is high enough
                    if (combo >= 5) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${combo * 50} BONUS!',
                        style: TextStyle(
                          color: Colors.yellow.shade200,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                    
                    if (isCascade) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${gameService.lastCascadeClears} LINES',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${gameService.lastCascadeCycles} CASCADE${gameService.lastCascadeCycles > 1 ? 'S' : ''}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: Offset(scale, scale), // Dynamic scale based on combo level
                  duration: 300.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .scale(
                  begin: Offset(scale, scale),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                )
                // FIXED: Much longer hold time
                .then(delay: 1000.ms) 
                .fadeOut(duration: 500.ms)
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(0.7, 0.7),
                  duration: 500.ms,
                )
                // FIXED: Add a pulsing effect for high combos
                .animate(
                  onComplete: (controller) {
                    if (combo >= 8) {
                      // Add extra shimmer for high combos
                      controller.repeat(reverse: true);
                    }
                  },
                )
                .shimmer(
                  duration: combo >= 8 ? 1000.ms : 0.ms,
                  color: Colors.white.withOpacity(0.4),
                ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardedAdOverlay(BuildContext context, GravBlastService gameService) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF8E24AA),
                Color(0xFFAB47BC),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.purple.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.6),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reward Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withOpacity(0.2),
                  border: Border.all(color: Colors.amber, width: 2),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.amber,
                  size: 48,
                ),
              ).animate()
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 2000.ms, color: Colors.amber.withOpacity(0.5)),
              
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'CONTINUE PLAYING?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 16),
              
              const Text(
                'Watch a quick video to get:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 600.ms, duration: 400.ms),
              
              const SizedBox(height: 20),
              
              // Rewards List
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildRewardItem('1000 Bonus Points', Icons.stars, Colors.amber),
                    const SizedBox(height: 8),
                    _buildRewardItem('New Pieces', Icons.extension, Colors.cyan),
                    const SizedBox(height: 8),
                    _buildRewardItem('Continue Game', Icons.play_circle_outline, Colors.green),
                  ],
                ),
              ).animate()
                .fadeIn(delay: 800.ms, duration: 600.ms)
                .slideY(begin: 0.3),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildRewardButton(
                      context,
                      'Nuh uh',
                      Icons.close,
                      Colors.grey.shade600,
                      () {
                        context.read<AudioService>().playUIClick();
                        gameService.onRewardedAdDeclined();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: Consumer<AdService>(
                      builder: (context, adService, child) {
                        return _buildRewardButton(
                          context,
                          adService.isRewardedAdReady ? 'Watch Ad' : 'Loading...',
                          Icons.play_arrow,
                          adService.isRewardedAdReady ? Colors.purple.shade600 : Colors.grey,
                          adService.isRewardedAdReady ? () {
                            final audioService = context.read<AudioService>();
                            audioService.playUIClick();
                            // UPDATED: Pass context to showRewardedAd for confirmation dialog       
                            audioService.pauseMusic();
                            adService.showRewardedAd(() {
                              gameService.onRewardedAdCompleted();
                            }, context); // Pass context here
                          } : null,
                        );
                      },
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRewardItem(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRewardButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5,
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, GravBlastService gameService) {
    final isNewHighScore = gameService.score == gameService.highScore && gameService.score > 0;
    
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNewHighScore 
                  ? [
                      Colors.amber.shade800,
                      Colors.orange.shade900,
                    ]
                  : [
                      Colors.cyan.shade800,
                      Colors.blue.shade900,
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isNewHighScore 
                    ? Colors.amber.withOpacity(0.5)
                    : Colors.cyan.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Game Over Icon
              Icon(
                isNewHighScore ? Icons.emoji_events : Icons.extension_off,
                color: Colors.white,
                size: 64,
              ).animate()
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shake(duration: 1000.ms),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                isNewHighScore ? 'NEW HIGH SCORE!' : 'GAME OVER',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 400.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
              
              const SizedBox(height: 8),
              
              Text(
                isNewHighScore 
                    ? 'Blast mastery achieved!'
                    : 'No more moves available!',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ).animate()
                .fadeIn(delay: 600.ms, duration: 400.ms),
              
              const SizedBox(height: 24),
              
              // Stats Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Final Score', _formatScore(gameService.score), 
                        isHighlight: isNewHighScore),
                    _buildStatRow('High Score', _formatScore(gameService.highScore)),
                    _buildStatRow('Level Reached', gameService.level.toString()),
                    _buildStatRow('Lines Cleared', gameService.linesCleared.toString()),
                    if (gameService.combo > 0)
                      _buildStatRow('Max Combo', '${gameService.combo}x'),
                  ],
                ),
              ).animate()
                .fadeIn(delay: 800.ms, duration: 600.ms)
                .slideY(begin: 0.3),
              
              const SizedBox(height: 32),
              
              // Action Buttons with Audio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    'Replay',
                    Icons.refresh,
                    Colors.green.shade600,
                    () {
                      context.read<AudioService>().playUIClick();
                      gameService.resetGame();
                    },
                  ),
                  _buildActionButton(
                    context,
                    'Menu',
                    Icons.home,
                    Colors.blue.shade600,
                    () {
                      context.read<AudioService>().playUIClick();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MenuScreen()),
                      );
                    },
                  ),
                ],
              ).animate()
                .fadeIn(delay: 1000.ms, duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.amber.shade200 : Colors.white70,
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Row(
            children: [
              if (isHighlight)
                Icon(
                  Icons.star,
                  color: Colors.amber.shade200,
                  size: 16,
                ),
              if (isHighlight) const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? Colors.amber.shade100 : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5,
      ),
    );
  }

  Widget _buildAnimatingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
        ),
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