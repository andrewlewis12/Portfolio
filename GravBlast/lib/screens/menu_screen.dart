// Updated menu_screen.dart
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../main.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';
import '../utils/theme.dart';
import 'game_screen.dart';
import '../widgets/settings_popup.dart';
import 'splash_screen.dart';
import '../widgets/tutorial_overlay.dart';
import 'trailer_screen.dart';
import '../screens/achievement_screen.dart';
import '../services/achievement_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _menuController;
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Refresh banner ad when menu screen loads with a slight delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          if (kDebugMode) {
            print('Menu screen: Refreshing banner ad...');
          }
          context.read<AdService>().refreshBannerAd();
        }
      });
    });
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();

    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _menuController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated futuristic background
          _buildAnimatedBackground(),
          
          // Main content with proper scrolling
          SafeArea(
            child: Column(
              children: [
                // Main scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 
                                   MediaQuery.of(context).padding.top - 
                                   MediaQuery.of(context).padding.bottom - 100,
                      ),
                      child: _buildMainContent(),
                    ),
                  ),
                ),
                
                // Fixed banner ad space at bottom
                _buildBannerAdSpace(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAchievements() {
    final audioService = context.read<AudioService>();
    audioService.playUIClick();
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AchievementsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundController, _particleController]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.grey.shade900,
                Colors.cyan.shade900.withOpacity(0.3),
                Colors.black,
              ],
              stops: [
                0.0,
                0.3 + _backgroundController.value * 0.1,
                0.7 + _backgroundController.value * 0.1,
                1.0,
              ],
            ),
          ),
          child: CustomPaint(
            painter: FuturisticMenuPainter(
              backgroundAnimation: _backgroundController,
              particleAnimation: _particleController,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Game logo
          _buildGameLogo(),

          const SizedBox(height: 40),

          // Menu buttons
          _buildMenuButtons(),

          const SizedBox(height: 40),

          // Game stats
          _buildGameStats(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameLogo() {
    return Column(
      children: [
         Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.cyan.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: Colors.cyan.withOpacity(0.6),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: CustomPaint(
              painter: GravBlastLogoPainter(),
              size: const Size(80, 80),
            ),
          ).animate(controller: _menuController)
          .scale(
            delay: 200.ms,
            duration: 800.ms,
            curve: Curves.elasticOut,
          )
          .then()
          .shimmer(
            duration: 2000.ms,
            color: Colors.cyan.withOpacity(0.5),
          ),

        const SizedBox(height: 24),

        const Text(
          'GRAV BLAST',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: Colors.cyan,
                offset: Offset(0, 0),
                blurRadius: 10,
              ),
              Shadow(
                color: Colors.cyan,
                offset: Offset(2, 2),
                blurRadius: 5,
              ),
            ],
          ),
        ).animate(controller: _menuController)
          .fadeIn(delay: 600.ms, duration: 600.ms)
          .slideY(begin: 0.3, end: 0)
          .then()
          .shimmer(
            duration: 3000.ms,
            color: Colors.cyan.withOpacity(0.3),
          ),

        const SizedBox(height: 8),

        const Text(
          'Clear • Blast • Dominate',
          style: TextStyle(
            fontSize: 16,
            color: Colors.cyanAccent,
            letterSpacing: 1,
            fontWeight: FontWeight.w300,
          ),
        ).animate(controller: _menuController)
          .fadeIn(delay: 800.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildMenuButtons() {
    return Column(
      children: [
        _buildMenuButton(
          'PLAY',
          Icons.play_arrow,
          LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
          ),
          () => _startGame(),
          1000,
        ),

        const SizedBox(height: 16),

        _buildMenuButton(
          'CONTINUE',
          Icons.play_circle_outline,
          LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          () => _continueGame(),
          1200,
        ),

        const SizedBox(height: 16),

        // NEW: Achievements button
        _buildAchievementsButton(),

        const SizedBox(height: 16),

        _buildMenuButton(
          'SETTINGS',
          Icons.settings,
          LinearGradient(
            colors: [Colors.orange.shade600, Colors.orange.shade800],
          ),
          () => _showSettings(),
          1600,
        ),

        const SizedBox(height: 16),

        _buildMenuButton(
          'TUTORIAL',
          Icons.school,
          LinearGradient(
            colors: [Colors.purple.shade600, Colors.purple.shade800],
          ),
          () => _showTutorial(),
          1800,
        ),
      ],
    );
  }

  Widget _buildAchievementsButton() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final hasRecentUnlocked = achievementService.recentlyUnlocked.isNotEmpty;
        final unlockedCount = achievementService.unlockedCount;
        final totalCount = achievementService.totalCount;
        
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade600, Colors.amber.shade800],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _showAchievements(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 24),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ACHIEVEMENTS',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '$unlockedCount/$totalCount unlocked',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Notification badge for recent achievements
              if (hasRecentUnlocked)
                Positioned(
                  top: 8,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${achievementService.recentlyUnlocked.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate(autoPlay: true)
                    .scale(
                      duration: 300.ms,
                      curve: Curves.elasticOut,
                    )
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
                ),
            ],
          ),
        ).animate(controller: _menuController) // FIXED: Use _menuController instead of _heroController
          .fadeIn(delay: 1400.ms, duration: 400.ms)
          .slideX(begin: -0.3, end: 0)
          .then()
          .shimmer(
            delay: 1400.ms + 2000.ms,
            duration: 1000.ms,
            color: Colors.white.withOpacity(0.2),
          );
      },
    );
  }

  void _showTrailerOptions() {
    context.read<AudioService>().playUIClick();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5), width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.videocam, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Trailer Recording Mode',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose a scene type for trailer recording:',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            _buildTrailerModeButton(
              'Piece Placement',
              'Show pieces being placed strategically',
              Icons.extension,
              () => _startTrailerMode('piece_placement'),
            ),
            
            const SizedBox(height: 12),
            
            _buildTrailerModeButton(
              'Line Clearing',
              'Demonstrate line clearing and gravity',
              Icons.view_headline,
              () => _startTrailerMode('line_clear'),
            ),
            
            const SizedBox(height: 12),
            
            _buildTrailerModeButton(
              'Combo System',
              'Show explosive combo chains',
              Icons.local_fire_department,
              () => _startTrailerMode('combo'),
            ),
            
            const SizedBox(height: 12),
            
            _buildTrailerModeButton(
              'Full Gameplay',
              'Complete gameplay with UI',
              Icons.games,
              () => _startTrailerMode('full_gameplay'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailerModeButton(
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.play_arrow, color: Colors.red),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _startTrailerMode(String sceneType) {
    final gameService = context.read<GravBlastService>();
    context.read<AudioService>().playUIClick();
    
    gameService.startTrailerMode(sceneType);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            TrailerGameScreen(sceneType: sceneType),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  Widget _buildMenuButton(
    String text,
    IconData icon,
    Gradient gradient,
    VoidCallback onPressed,
    int delay,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    ).animate(controller: _menuController)
      .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
      .slideX(begin: -0.3, end: 0)
      .then()
      .shimmer(
        delay: Duration(milliseconds: delay + 2000),
        duration: 1000.ms,
        color: Colors.white.withOpacity(0.2),
      );
  }

  Widget _buildGameStats() {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.cyan.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('High Score', _formatScore(gameService.highScore), Icons.emoji_events, Colors.amber),
              Container(
                width: 1,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.cyan.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _buildStatItem('Level', gameService.level.toString(), Icons.trending_up, Colors.purple),
              Container(
                width: 1,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.cyan.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              _buildStatItem('Lines', gameService.linesCleared.toString(), Icons.view_headline, Colors.green),
            ],
          ),
        ).animate(controller: _menuController)
          .fadeIn(delay: 1800.ms, duration: 600.ms)
          .slideY(begin: 0.3, end: 0);
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerAdSpace() {
    return Consumer<AdService>(
      builder: (context, adService, child) {
        final bannerAd = adService.bannerAd;
        
        // Debug information
        if (kDebugMode) {
          print('Banner Ad Debug:');
          print('  bannerAd != null: ${bannerAd != null}');
          print('  isBannerAdReady: ${adService.isBannerAdReady}');
          print('  isLoadingBannerAd: ${adService.isLoadingBannerAd}');
        }
        
        if (bannerAd != null && adService.isBannerAdReady) {
          return Container(
            height: bannerAd.size.height.toDouble(),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              border: Border(
                top: BorderSide(
                  color: Colors.cyan.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: AdWidget(ad: bannerAd),
          );
        }
        
        // Show different states
        return Container(
          height: 60,
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (adService.isLoadingBannerAd) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Loading ad...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () => adService.refreshBannerAd(),
                    child: const Text(
                      'Tap to reload ad',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Debug: Ready=${adService.isBannerAdReady}, Ad=${bannerAd != null}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _startGame() {
    final gameService = context.read<GravBlastService>();
    final adService = context.read<AdService>();
    final audioService = context.read<AudioService>(); // ADD THIS
    
    audioService.playUIClick(); // ADD THIS
    
    // Show interstitial ad every time main menu hits play
    adService.showInterstitialAd();
    gameService.resetGame();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GravBlastScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _continueGame() {
    context.read<AudioService>().playUIClick(); // ADD THIS
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const GravBlastScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showSettings() {
    context.read<AudioService>().playUIClick();
    showDialog(
      context: context,
      builder: (context) => const SettingsPopup(),
    );
  }

   void _showTutorial() {
    final gameService = context.read<GravBlastService>();
    final audioService = context.read<AudioService>(); // ADD THIS
    
    audioService.playUIClick(); // ADD THIS
    
    gameService.resetGame();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TutorialGameScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
  
  void onlyClick()
  {
    final audioService = context.read<AudioService>();
    audioService.playUIClick();
    Navigator.of(context).pop();
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

class FuturisticMenuPainter extends CustomPainter {
  final Animation<double> backgroundAnimation;
  final Animation<double> particleAnimation;

  FuturisticMenuPainter({
    required this.backgroundAnimation,
    required this.particleAnimation,
  }) : super(repaint: Listenable.merge([backgroundAnimation, particleAnimation]));

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final time = backgroundAnimation.value * 2 * pi;
    final particleTime = particleAnimation.value * 2 * pi;

    // Draw animated grid lines
    _drawGrid(canvas, size, time);
    
    // Draw floating particles
    _drawParticles(canvas, size, particleTime);
    
    // Draw central energy rings
    _drawEnergyRings(canvas, centerX, centerY, time);
  }

  void _drawGrid(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final spacing = 50.0;
    final offset = (time * 10) % spacing;

    // Vertical lines
    for (double x = -offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = -offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawParticles(Canvas canvas, Size size, double time) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final x = (i * 73 + time * 20) % size.width;
      final y = (i * 67 + time * 15) % size.height;
      final radius = 1.0 + (i % 3) * 0.5;
      final alpha = (sin(time + i) + 1) * 0.3;

      paint.color = Colors.cyan.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawEnergyRings(Canvas canvas, double centerX, double centerY, double time) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int ring = 0; ring < 3; ring++) {
      final radius = 150 + ring * 50;
      final sides = 6 + ring * 2;
      final rotation = time / (ring + 1);
      final alpha = (sin(time + ring) + 1) * 0.2;

      paint.color = Colors.cyan.withOpacity(alpha);

      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = (i / sides) * 2 * pi + rotation;
        final x = centerX + radius * cos(angle);
        final y = centerY + radius * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}