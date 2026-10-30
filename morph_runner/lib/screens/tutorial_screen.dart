import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';
import '../widgets/shape_widget.dart';
import '../services/achievements_service.dart';
import '../utils/screen_transitions.dart';
import 'home_screen.dart';

class TutorialScreen extends StatefulWidget {
  @override
  _TutorialScreenState createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> 
    with TickerProviderStateMixin {
  int currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<TutorialStep> tutorialSteps = [
    TutorialStep(
      title: "Welcome to Morph Runner!",
      description: "Learn the basics of shape-shifting survival",
      instruction: "Tap 'Next' to begin the tutorial",
      visualType: TutorialVisualType.welcome,
    ),
    TutorialStep(
      title: "Movement",
      description: "Swipe left and right to move between lanes",
      instruction: "Quick swipes work best - you only need small movements!",
      visualType: TutorialVisualType.movement,
    ),
    TutorialStep(
      title: "Shape Matching",
      description: "You can ONLY pass through obstacles that match your current shape",
      instruction: "Look at your shape in the top-left corner",
      visualType: TutorialVisualType.shapeMatching,
    ),
    TutorialStep(
      title: "Phase Dash",
      description: "When your shape ISN'T available, swipe UP to phase through",
      instruction: "You can also dash THROUGH your matching shape if you want!",
      visualType: TutorialVisualType.phaseDash,
    ),
    TutorialStep(
      title: "Dash Strategy",
      description: "Smart dashing gives you more options",
      instruction: "Can ONLY dash through your matching shape lane!",
      visualType: TutorialVisualType.dashStrategy,
    ),
    TutorialStep(
      title: "Deadly Obstacles",
      description: "Red skull marks are always deadly - avoid them completely!",
      instruction: "You cannot dash over them - move to a different lane!",
      visualType: TutorialVisualType.deadlyObstacles,
    ),
    TutorialStep(
      title: "Powerups",
      description: "Collect glowing powerups for special abilities!",
      instruction: "Slow motion, score multipliers, shields, and more!",
      visualType: TutorialVisualType.powerups,
    ),
    TutorialStep(
      title: "Shape Morphing",
      description: "Your shape changes randomly after passing obstacles",
      instruction: "Stay alert - your strategy must adapt!",
      visualType: TutorialVisualType.morphing,
    ),
    TutorialStep(
      title: "Ready to Play!",
      description: "Master timing and transformation to achieve high scores",
      instruction: "Good luck, shape-shifter!",
      visualType: TutorialVisualType.ready,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  void _nextStep() {
    if (currentStep < tutorialSteps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _completeTutorial();
    }
  }

  void _previousStep() {
    if (currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() {
          currentStep--;
        });
        _animationController.forward();
      });
    }
  }

  void _completeTutorial() {
    GameData.setTutorialCompleted();
    AchievementsService.instance.onTutorialCompleted();
    ScreenTransitions.replaceTo(
      context, 
      HomeScreen(), 
      type: TransitionType.slideFromLeft
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final step = tutorialSteps[currentStep];
    
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () { 
                        AudioService.instance.playUIClick();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Tutorial',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Text(
                      '${currentStep + 1}/${tutorialSteps.length}',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              // Progress indicator
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / tutorialSteps.length,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
              
              SizedBox(height: 30),
              
              // Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Title
                            Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Visual demonstration
                            Expanded(
                              flex: 3,
                              child: _buildTutorialVisual(step.visualType),
                            ),
                            
                            SizedBox(height: 20),
                            
                            // Description and instruction
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    step.description,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    step.instruction,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    currentStep > 0
                        ? ElevatedButton(
                            onPressed: () { 
                              AudioService.instance.playUIClick();
                              _previousStep();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back, size: 18),
                                SizedBox(width: 5),
                                Text('Previous'),
                              ],
                            ),
                          )
                        : SizedBox(width: 100),
                    
                    // Skip button
                    TextButton(
                      onPressed: () { 
                        AudioService.instance.playUIClick();
                        _completeTutorial();
                      },
                      child: Text(
                        'Skip Tutorial',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    
                    // Next button
                    ElevatedButton(
                      onPressed: () { 
                        AudioService.instance.playUIClick();
                        _nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStep == tutorialSteps.length - 1
                            ? Colors.green
                            : Colors.cyan,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentStep == tutorialSteps.length - 1 ? 'Finish' : 'Next'),
                          SizedBox(width: 5),
                          Icon(
                            currentStep == tutorialSteps.length - 1 
                                ? Icons.check 
                                : Icons.arrow_forward, 
                            size: 18
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
    );
  }

  Widget _buildTutorialVisual(TutorialVisualType type) {
    switch (type) {
      case TutorialVisualType.welcome:
        return _buildWelcomeVisual();
      case TutorialVisualType.movement:
        return _buildMovementVisual();
      case TutorialVisualType.shapeMatching:
        return _buildShapeMatchingVisual();
      case TutorialVisualType.phaseDash:
        return _buildPhaseDashVisual();
      case TutorialVisualType.dashStrategy:
        return _buildDashStrategyVisual();
      case TutorialVisualType.deadlyObstacles:
        return _buildDeadlyObstaclesVisual();
      case TutorialVisualType.powerups:
        return _buildPowerupsVisual();
      case TutorialVisualType.morphing:
        return _buildMorphingVisual();
      case TutorialVisualType.ready:
        return _buildReadyVisual();
    }
  }

  Widget _buildWelcomeVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MORPH',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          Text(
            'RUNNER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 30),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: PlayerShape.values.map((shape) => 
              ShapeWidget(shape: shape, size: 30, animate: true)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lane representation
          Container(
            height: 100,
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      color: index == 2 ? Colors.cyan.withOpacity(0.3) : Colors.transparent,
                    ),
                    child: index == 2 
                        ? Center(
                            child: ShapeWidget(
                              shape: PlayerShape.circle,
                              size: 30,
                              animate: true,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, color: Colors.white, size: 30),
              SizedBox(width: 20),
              Text('Quick Swipe', style: TextStyle(color: Colors.white, fontSize: 16)),
              SizedBox(width: 20),
              Icon(Icons.arrow_forward, color: Colors.white, size: 30),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Small movements work!',
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeMatchingVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player shape
          Text('Your Shape:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          ShapeWidget(shape: PlayerShape.triangle, size: 40),
          SizedBox(height: 30),
          
          // Obstacle row
          Text('Obstacle Row:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildObstacleSlot(PlayerShape.circle, false),
              _buildObstacleSlot(PlayerShape.square, false),
              _buildObstacleSlot(PlayerShape.triangle, true), // Correct match
              _buildObstacleSlot(PlayerShape.diamond, false),
              _buildObstacleSlot(PlayerShape.star, false),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '✓ Go through matching shape',
            style: TextStyle(color: Colors.green, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDashVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Player shape
          Text('Your Shape:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          ShapeWidget(shape: PlayerShape.heart, size: 40),
          SizedBox(height: 30),
          
          // Obstacle row without player's shape
          Text('No matching shape available:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildObstacleSlot(PlayerShape.circle, false),
              _buildObstacleSlot(PlayerShape.square, false),
              _buildObstacleSlot(PlayerShape.triangle, false),
              _buildObstacleSlot(PlayerShape.diamond, false),
              _buildObstacleSlot(PlayerShape.star, false),
            ],
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Icon(Icons.arrow_upward, color: Colors.cyan, size: 30),
              Text(
                'Swipe UP to phase through',
                style: TextStyle(color: Colors.cyan, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashStrategyVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Your Shape:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          ShapeWidget(shape: PlayerShape.triangle, size: 40),
          SizedBox(height: 20),
          
          Text('Obstacle Row:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildObstacleSlot(PlayerShape.circle, false),
              _buildObstacleSlot(PlayerShape.triangle, true), // Player's shape
              _buildObstacleSlot(PlayerShape.square, false),
              _buildObstacleSlot(PlayerShape.diamond, false),
              _buildObstacleSlot(PlayerShape.star, false),
            ],
          ),
          SizedBox(height: 20),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Icon(Icons.touch_app, color: Colors.green, size: 25),
                      Text('Go through', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                  SizedBox(width: 40),
                  Text('OR', style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(width: 40),
                  Column(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.cyan, size: 25),
                      Text('Dash through', style: TextStyle(color: Colors.cyan, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Both options work!',
                style: TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlyObstaclesVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Deadly Red skull:', style: TextStyle(color: Colors.white, fontSize: 16)),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildObstacleSlot(PlayerShape.circle, false),
              _buildObstacleSlot(null, false, isX: true), // Red skull in lane 2
              _buildObstacleSlot(PlayerShape.triangle, false),
              _buildObstacleSlot(PlayerShape.diamond, false),
              _buildObstacleSlot(PlayerShape.star, false),
            ],
          ),
          SizedBox(height: 20),
          Text(
            '⚠️ Cannot dash over Red skull!',
            style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Move to a different lane to avoid',
            style: TextStyle(color: Colors.red.shade300, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerupsVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Powerups:', style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 30),
          
          // Show different powerup types
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildPowerupExample(Icons.slow_motion_video, Colors.blue, 'Slow Motion'),
              _buildPowerupExample(Icons.star, Colors.yellow, 'Score Boost'),
              _buildPowerupExample(Icons.shield, Colors.green, 'Shield'),
              _buildPowerupExample(Icons.flash_on, Colors.orange, 'Speed Boost'),
              _buildPowerupExample(Icons.lock, Colors.cyan, 'Shape Lock'),
            ],
          ),
          
          SizedBox(height: 30),
          Text(
            'Move into the same lane to collect!',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPowerupExample(IconData icon, Color color, String name) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.9),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        SizedBox(height: 5),
        Text(
          name,
          style: TextStyle(color: Colors.white, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMorphingVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Shape Morphing:', style: TextStyle(color: Colors.white, fontSize: 18)),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShapeWidget(shape: PlayerShape.circle, size: 35),
              SizedBox(width: 20),
              Icon(Icons.arrow_forward, color: Colors.white, size: 25),
              SizedBox(width: 20),
              ShapeWidget(shape: PlayerShape.star, size: 35, animate: true),
            ],
          ),
          SizedBox(height: 30),
          Text(
            'Your shape changes randomly\nafter passing obstacles',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyVisual() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),
          SizedBox(height: 20),
          Text(
            'You\'re Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: PlayerShape.values.map((shape) => 
              ShapeWidget(shape: shape, size: 25, animate: true)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildObstacleSlot(PlayerShape? shape, bool isCorrect, {bool isX = false}) {
    return Container(
      width: 50,
      height: 50,
      margin: EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isX 
            ? const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8)
            : (isCorrect 
                ? Colors.green.withOpacity(0.3) 
                : Colors.white.withOpacity(0.1)),
        border: Border.all(
          color: isX 
              ? const Color.fromARGB(255, 0, 0, 0) 
              : (isCorrect ? Colors.green : Colors.white24),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: isX
            ? FaIcon(FontAwesomeIcons.skull, color: const Color.fromARGB(255, 133, 0, 0), size: 30)
            : (shape != null 
                ? ShapeWidget(shape: shape, size: 25) 
                : null),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class TutorialStep {
  final String title;
  final String description;
  final String instruction;
  final TutorialVisualType visualType;

  TutorialStep({
    required this.title,
    required this.description,
    required this.instruction,
    required this.visualType,
  });
}

enum TutorialVisualType {
  welcome,
  movement,
  shapeMatching,
  phaseDash,
  dashStrategy,
  deadlyObstacles,
  powerups,
  morphing,
  ready,
}