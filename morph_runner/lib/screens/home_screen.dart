import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';
import '../utils/screen_transitions.dart';
import '../widgets/shape_widget.dart';
import '../services/ad_service.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../services/leaderboard_service.dart';
import '../widgets/leaderboard_widget.dart';
import '../widgets/achievements_widget.dart';
import '../services/achievements_service.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _shapeController;
  late Animation<double> _backgroundAnimation;
  
  int _currentShapeIndex = 0;
  final List<PlayerShape> _shapes = PlayerShape.values;

  
@override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    );
    
    _shapeController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
    
    _backgroundController.repeat();
    
    // Initialize services
    _initializeServices();
    
    // FIXED: Proper home screen lifecycle management
    AdService.instance.onHomeScreenCreated();
    
    // Start menu music
    AudioService.instance.startMenuMusic();
    _startShapeRotation();
    
    // ADDED: Check for achievement notifications when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForAchievementNotifications();
      
      // ADDED: Force a rebuild after a short delay to ensure banner ad is shown
      Future.delayed(Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() {}); // Trigger rebuild to show banner ad
        }
      });
    });
  }
  
  Future<void> _initializeServices() async {
    // Initialize leaderboard service
    await LeaderboardService.instance.initialize();
  }

  // ADDED: Check for achievement notifications
  void _checkForAchievementNotifications() {
    final recentNotifications = AchievementsService.instance.recentNotifications;
    
    for (final notification in recentNotifications) {
      if (notification.isNew) {
        _showAchievementNotificationOverlay(notification.achievement);
        notification.isNew = false; // Mark as seen
      }
    }
  }

  void _showChangeUsernameDialog() {
    final controller = TextEditingController(
      text: LeaderboardService.instance.hasValidUsername 
          ? LeaderboardService.instance.playerName 
          : ''
    );
    bool isChecking = false;
    bool isAvailable = true;
    String? availabilityMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.deepPurple.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Change Username', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: Colors.white),
                maxLength: 20,
                onChanged: (value) async {
                  if (value.trim().length >= 3) {
                    setDialogState(() {
                      isChecking = true;
                      availabilityMessage = 'Checking...';
                    });
                    
                    final available = await LeaderboardService.instance.isUsernameAvailable(value.trim());
                    
                    setDialogState(() {
                      isChecking = false;
                      isAvailable = available;
                      availabilityMessage = available ? '✓ Available' : '✗ Taken';
                    });
                  } else {
                    setDialogState(() {
                      isChecking = false;
                      isAvailable = false;
                      availabilityMessage = value.trim().isEmpty ? null : 'Min 3 chars';
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: 'New username',
                  hintStyle: TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  counterStyle: TextStyle(color: Colors.white60),
                ),
              ),
              if (availabilityMessage != null)
                Text(
                  availabilityMessage!,
                  style: TextStyle(
                    color: isAvailable ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                AudioService.instance.playUIClick();
                await LeaderboardService.instance.setAnonymousMode();
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Set to anonymous mode'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text('Go Anonymous', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () {
                AudioService.instance.playUIClick();
                Navigator.pop(context);
              },
              child: Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: (!isChecking && isAvailable && controller.text.trim().length >= 3)
                  ? () async {
                      AudioService.instance.playUIClick();
                      final success = await LeaderboardService.instance.setPlayerName(controller.text.trim());
                      Navigator.pop(context);
                      
                      if (success) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Username updated!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update username'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  : null,
              child: Text('Save', style: TextStyle(color: Colors.cyan)),
            ),
          ],
        ),
      ),
    );
  }

  // ADDED: Show achievement notification overlay
  void _showAchievementNotificationOverlay(Achievement achievement) {
    // Create overlay entry that appears above all content
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

  void _startShapeRotation() {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentShapeIndex = (_currentShapeIndex + 1) % _shapes.length;
        });
        _shapeController.forward().then((_) {
          _shapeController.reset();
          _startShapeRotation();
        });
      }
    });
  }

  // Updated method to show interstitial before starting game
  void _startGame() async {
    // Play UI sound
    AudioService.instance.playUIClick();
    // Notify ad service that game is starting from home
    AdService.instance.onGameStartFromHome();
    
    // Show interstitial ad first
    bool adShown = await AdService.instance.showInterstitialAd();
    
    // Navigate to game screen
    if (mounted) {
      AudioService.instance.startGameMusic();
      ScreenTransitions.navigateTo(
        context, 
        GameScreen(), 
        type: TransitionType.scaleUp
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        body: Stack( // CHANGED: Use Stack to overlay banner ad
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade900,
                    Colors.deepPurple.shade600,
                    Colors.purple.shade400,
                    Colors.pink.shade300,
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Animated background particles
                      ...List.generate(15, (index) {
                        final offset = _backgroundAnimation.value * 2 * pi + index;
                        return Positioned(
                          left: 30 + (index % 3) * 120 + 20 * sin(offset),
                          top: 80 + (index ~/ 3) * 120 + 15 * cos(offset * 1.5),
                          child: Opacity(
                            opacity: 0.1 + 0.05 * sin(offset),
                            child: ShapeWidget(
                              shape: _shapes[index % _shapes.length],
                              size: 15 + 8 * sin(offset * 2),
                              animate: false,
                              showGlow: false,
                            ),
                          ),
                        );
                      }),
                      
                      // Main content
                      SafeArea(
                        child: SingleChildScrollView(
                          // CHANGED: Add bottom padding to account for banner ad
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: AdService.instance.isHomeBannerAdReady ? 60 : 0
                            ),
                            child: Column(
                              children: [
                                SizedBox(height: 40),
                                
                                // Title
                                Column(
                                  children: [
                                    Text(
                                      'MORPH',
                                      style: TextStyle(
                                        fontSize: 52,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 6,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 20.0,
                                            color: Colors.purple.shade300,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'RUNNER',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                        letterSpacing: 4,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 15.0,
                                            color: Colors.purple.shade300,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 15),
                                
                                // Subtitle
                                Text(
                                  'Master the art of timing and transformation!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                SizedBox(height: 40),
                                
                                // Shape showcase
                                Container(
                                  height: 80,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _shapeController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: 1.0 + _shapeController.value * 0.2,
                                            child: ShapeWidget(
                                              shape: _shapes[_currentShapeIndex],
                                              size: 50,
                                              animate: true,
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(width: 15),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                      SizedBox(width: 15),
                                      ShapeWidget(
                                        shape: _shapes[(_currentShapeIndex + 1) % _shapes.length],
                                        size: 35,
                                        animate: false,
                                      ),
                                    ],
                                  ),
                                ),
                                
                                SizedBox(height: 30),
                                
                                // All shapes preview
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _shapes.map((shape) {
                                    return ShapeWidget(
                                      shape: shape,
                                      size: 22,
                                      animate: false,
                                    );
                                  }).toList(),
                                ),
                                
                                SizedBox(height: 40),
                                
                                // Main buttons
                                Column(
                                  children: [
                                    _buildMenuButton(
                                      'START GAME',
                                      Icons.play_arrow,
                                      Colors.green,
                                      _startGame,
                                    ),
                                    
                                    SizedBox(height: 12),
                                    
                                    _buildMenuButton(
                                      'TUTORIAL',
                                      Icons.school,
                                      Colors.blue,
                                      () => 
                                      ScreenTransitions.navigateTo(
                                        context, 
                                        TutorialScreen(), 
                                        type: TransitionType.slideFromRight
                                      ),
                                    ),
                                      
                                    SizedBox(height: 12),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildSmallButton(
                                          'Settings',
                                          Icons.settings,
                                          () => _showSettingsDialog(),
                                        ),
                                        _buildSmallButton(
                                          'Stats',
                                          Icons.bar_chart,
                                          () => _showStatsDialog(),
                                        ),
                                        _buildSmallButton(
                                          'Share',
                                          Icons.share,
                                          () => _shareGame(),
                                        ),
                                        _buildSmallButton(
                                          'About',
                                          Icons.info,
                                          () => _showAboutDialog(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 25),
                                
                                // High score
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    'HIGH SCORE: ${GameData.highScore}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                                
                                LeaderboardWidget(isCompact: true),
                                
                                AchievementsWidget(isCompact: true),

                                SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            _buildBannerAdSection(),
          ],
        ),
      ),
    );
  }
  
  // Replace your existing banner ad section with this:
  Widget _buildBannerAdSection() {
    // Only build if ad is ready and home screen is active
    final adWidget = AdService.instance.getHomeBannerAdWidget();
    final isReady = AdService.instance.isHomeBannerAdReady;
    
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        height: isReady ? 50 : 0,
        decoration: BoxDecoration(
          color: isReady ? Colors.black87 : Colors.transparent,
          boxShadow: isReady ? [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ] : null,
        ),
        child: isReady && adWidget != null
            ? adWidget  // Don't wrap in another container with key
            : SizedBox.shrink(),
      ),
    );
  }

  void _shareGame() {
    final shareText = 'Check out Morph Runner! Master the art of timing and transformation. '
        'Join me: https://paconotenterprises.com/morph-runner?invite=true';

    Share.share(shareText);

    AudioService.instance.playUIClick();
  }

  Widget _buildMenuButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 220,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          AudioService.instance.playUIClick();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(String text, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: () {
        AudioService.instance.playUIClick();
        onPressed();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.deepPurple.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView( // ADDED: Make scrollable for more content
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sound Effects
                    SwitchListTile(
                      title: Text('Sound Effects', style: TextStyle(color: Colors.white)),
                      value: AudioService.instance.soundEnabled,
                      onChanged: (bool value) async {
                        await AudioService.instance.setSoundEnabled(value);
                        setDialogState(() {});
                        setState(() {});
                      },
                      activeColor: Colors.green,
                    ),
                    
                    // Music
                    SwitchListTile(
                      title: Text('Music', style: TextStyle(color: Colors.white)),
                      value: AudioService.instance.musicEnabled,
                      onChanged: (bool value) async {
                        await AudioService.instance.setMusicEnabled(value);
                        setDialogState(() {});
                        setState(() {});
                      },
                      activeColor: Colors.green,
                    ),
                    
                    // Vibration
                    SwitchListTile(
                      title: Text('Vibration', style: TextStyle(color: Colors.white)),
                      value: GameData.vibrateEnabled,
                      onChanged: (bool value) async {
                        await GameData.setVibrateEnabled(value);
                        setDialogState(() {});
                        setState(() {});
                      },
                      activeColor: Colors.green,
                    ),
                    
                    // NEW: Rank Outline Toggle
                    FutureBuilder<bool>(
                      future: _getRankOutlineSetting(),
                      builder: (context, snapshot) {
                        final showOutline = snapshot.data ?? true;
                        return SwitchListTile(
                          title: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.yellow.shade600,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Show Rank In-Game',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Display rank below your shape',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                          value: showOutline,
                          onChanged: (bool value) async {
                            await RankDisplaySettings.setShowRankOutline(value);
                            setDialogState(() {});
                            setState(() {});
                          },
                          activeColor: Colors.cyan,
                        );
                      },
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Username management section
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.deepPurple.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Display Name',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Current: ${LeaderboardService.instance.playerName}',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              AudioService.instance.playUIClick();
                              Navigator.pop(context);
                              _showChangeUsernameDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Change Username'),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Sound volume slider
                    Text('Sound Volume', style: TextStyle(color: Colors.white)),
                    Slider(
                      value: AudioService.instance.volume,
                      onChanged: (double value) async {
                        await AudioService.instance.setVolume(value);
                        setDialogState(() {});
                        setState(() {});
                      },
                      activeColor: Colors.cyan,
                    ),
                    Text(
                      '${(AudioService.instance.volume * 100).round()}%',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Music volume slider
                    Text('Music Volume', style: TextStyle(color: Colors.white)),
                    Slider(
                      value: AudioService.instance.musicVolume,
                      onChanged: (double value) async {
                        await AudioService.instance.setMusicVolume(value);
                        setDialogState(() {});
                        setState(() {});
                      },
                      activeColor: Colors.cyan,
                    ),
                    Text(
                      '${(AudioService.instance.musicVolume * 100).round()}%',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    
                    SizedBox(height: 8),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            AudioService.instance.playUIClick();
                            ScreenTransitions.navigateTo(
                              context,
                              TutorialScreen(),
                              type: TransitionType.slideFromRight,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Tutorial'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            AudioService.instance.playUIClick();
                            _resetGameData(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Reset Data'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    AudioService.instance.playUIClick();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Close',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _getRankOutlineSetting() async {
    await RankDisplaySettings.initialize();
    return RankDisplaySettings.showRankOutline;
  }

  void _resetGameData(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade800,
          title: Text(
            'Reset Game Data?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'This will reset your high score, statistics, and tutorial progress. This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () { 
                AudioService.instance.playUIClick();
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                AudioService.instance.playUIClick();
                await GameData.resetAllData();
                Navigator.of(context).pop();
                Navigator.of(dialogContext).pop();
                setState(() {}); // Refresh the home screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Game data reset successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Reset', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Statistics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('High Score:', '${GameData.highScore}'),
              _buildStatRow('Games Played:', '${GameData.totalGamesPlayed}'),
              _buildStatRow('Time Played:', '${(GameData.totalTimePlayed / 60).toStringAsFixed(1)} min'),
              _buildStatRow('Tutorial:', GameData.tutorialCompleted ? 'Completed' : 'Not Completed'),
              
              // Add consistency tracking information
              _buildStatRow('Consistent Streak:', '${GameData.consistentGamesStreak} games'),
              _buildStatRow('Last Score:', '${GameData.lastGameScore}'),
              
              if (GameData.totalGamesPlayed > 0)
                _buildStatRow('Total Score:', '${GameData.totalScore}'),
                _buildStatRow('Avg Score:', '${(GameData.totalScore / GameData.totalGamesPlayed).toStringAsFixed(0)}'),
              
              // Show consistency progress toward achievement
              if (GameData.consistentGamesStreak > 0 && 
                (AchievementsService.instance.getAchievement('consistency') == null || !AchievementsService.instance.getAchievement('consistency')!.isUnlocked)) ...[
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consistency Achievement Progress:',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (GameData.consistentGamesStreak / 10).clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${GameData.consistentGamesStreak}/10 consecutive 1000+ scores',
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playUIClick();
                Navigator.of(context).pop(); 
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }
  
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.deepPurple.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'About Morph Runner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Master the art of timing and transformation in this fast-paced, shape-shifting endless runner!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Version: ${GameData.appVersion}',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                SizedBox(height: 4),
                Text(
                  'Developed by: ${GameData.companyName}',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _launchURL(GameData.companyWebsite),
                  child: Text(
                    'Website: ${GameData.companyWebsite}',
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.pinkAccent),
                      tooltip: 'Instagram',
                      onPressed: () => _launchURL('https://instagram.com/paconotenterprises'),
                    ),
                    IconButton(
                      icon: Icon(Icons.music_note, color: Colors.lightBlueAccent),
                      tooltip: 'TikTok',
                      onPressed: () => _launchURL('https://tiktok.com/@lil_paconot'),
                    ),
                    IconButton(
                      icon: Icon(Icons.ondemand_video, color: Colors.redAccent),
                      tooltip: 'YouTube',
                      onPressed: () => _launchURL('https://youtube.com/lilpaconot'),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/privacy'),
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.blue.shade300, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/terms'),
                      child: Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.blue.shade300, fontSize: 12),
                      ),
                    ),
                    
                  ],
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Paconot Technologies. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioService.instance.playUIClick();
                Navigator.of(context).pop(); 
              },
              child: Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

   @override
  void dispose() {
    _backgroundController.dispose();
    _shapeController.dispose();
    
    // FIXED: Proper home screen disposal
    AdService.instance.onHomeScreenDisposed();
    
    super.dispose();
  }

  // ADDED: Method to rebuild widget when returning from game screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Small delay to ensure clean widget tree state
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {}); // Trigger rebuild
      }
    });
  }
}
