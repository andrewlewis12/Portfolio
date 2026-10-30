import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../utils/game_data.dart';
import '../widgets/shape_widget.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../services/ad_service.dart';
import '../services/achievements_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _logoController;
  late AnimationController _shapeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _shapeAnimation;
  
  String _loadingText = 'Initializing...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _shapeController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _shapeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shapeController, curve: Curves.easeInOut),
    );

    _startAnimationsAndInitialization();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (AudioService.instance.isInitialized) {
      if (state == AppLifecycleState.paused) {
        AudioService.instance.pauseMusic();
      } else if (state == AppLifecycleState.resumed) {
        AudioService.instance.resumeMusic();
      }
    }
  }

  void _startAnimationsAndInitialization() async {
    await Future.delayed(Duration(milliseconds: 300));
    if (mounted) _logoController.forward();
    
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) _shapeController.forward();

    await Future.delayed(Duration(milliseconds: 800));
    await _initializeAllServices();
  }

  Future<void> _initializeAllServices() async {
    try {
      _updateLoadingText('Loading game data...');
      await GameData.init();
      
      _updateLoadingText('Setting up audio...');
      await AudioService.instance.init();
      
      _updateLoadingText('Connecting to leaderboard...');
      await LeaderboardService.instance.initialize();
      
      _updateLoadingText('Loading ads...');
      await AdService.instance.initialize();

      _updateLoadingText('Loading achievements...');
      await AchievementsService.instance.initialize();
      
      _updateLoadingText('Ready to play!');
      await Future.delayed(Duration(milliseconds: 500));
      
      await _checkLegalAcceptanceAndNavigate();
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Initialization failed: $e';
        _loadingText = 'Error occurred';
      });
      
      await Future.delayed(Duration(seconds: 3));
      if (mounted) {
        await _checkLegalAcceptanceAndNavigate();
      }
    }
  }

  void _updateLoadingText(String text) {
    if (mounted) {
      setState(() {
        _loadingText = text;
      });
    }
  }

  Future<void> _checkLegalAcceptanceAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legalAccepted = prefs.getBool('legal_accepted') ?? false;
      final hasCompletedUsernameSetup = prefs.getBool('username_setup_completed') ?? false;
      
      if (mounted) {
        if (!legalAccepted) {
          // Legal not accepted yet - go to legal screen
          Navigator.pushReplacementNamed(context, '/legal');
        } else if (!hasCompletedUsernameSetup) {
          // Legal accepted but username not set up yet - go to username setup
          Navigator.pushReplacementNamed(context, '/username_setup');
        } else {
          // Both legal and username setup completed - go to home
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/legal');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _logoAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoAnimation.value,
                    child: Column(
                      children: [
                        Text(
                          'MORPH',
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 8,
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
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.purple.shade300,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 60),

              AnimatedBuilder(
                animation: _shapeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _shapeAnimation.value,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: PlayerShape.values.map((shape) {
                        return ShapeWidget(
                          shape: shape,
                          size: 35,
                          animate: true,
                        );
                      }).toList(),
                    ),
                  );
                },
              ),

              SizedBox(height: 100),

              AnimatedBuilder(
                animation: _shapeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _shapeAnimation.value,
                    child: Column(
                      children: [
                        if (!_hasError) ...[
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 20),
                          Container(
                            height: 50,
                            child: Center(
                              child: Text(
                                _loadingText,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.warning,
                            color: Colors.orange,
                            size: 40,
                          ),
                          SizedBox(height: 20),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Continuing with limited functionality...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              SizedBox(height: 80),

              AnimatedBuilder(
                animation: _shapeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _shapeAnimation.value * 0.7,
                    child: Column(
                      children: [
                        Text(
                          GameData.companyName,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'v${GameData.appVersion}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shapeController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}