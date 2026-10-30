// tutorial_overlay.dart - FIXED skip button issue
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../screens/menu_screen.dart';
import '../services/tutorial_service.dart';

class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({Key? key}) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _arrowController;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialService>(
      builder: (context, tutorialService, child) {
        if (!tutorialService.isActive) return const SizedBox.shrink();
        
        return Stack(
          children: [
            // FIXED: Conditional pointer handling - only ignore for game area
            _buildConditionalOverlay(tutorialService),
            
            // Tutorial content based on current step
            _buildTutorialStep(tutorialService),
            
            // FIXED: Tutorial header and skip button with SEPARATE pointer handling
            _buildTutorialUIElements(tutorialService),
          ],
        );
      },
    );
  }
  
  // FIXED: Separate the game area overlay from UI elements
  Widget _buildConditionalOverlay(TutorialService tutorialService) {
    final shouldAllowGameInteraction = _shouldAllowGameInteraction(tutorialService.currentStep);
    
    return IgnorePointer(
      ignoring: shouldAllowGameInteraction, // Only affects game interactions
      child: _buildSelectiveOverlay(tutorialService),
    );
  }
  
  // FIXED: UI elements (header and skip) with independent pointer handling
  Widget _buildTutorialUIElements(TutorialService tutorialService) {
    return Stack(
      children: [
        // Tutorial header (always clickable)
        _buildTutorialHeader(tutorialService),
        
        // FIXED: Skip button (ALWAYS clickable - no IgnorePointer wrapper)
        _buildSkipButton(tutorialService),
      ],
    );
  }
  
  // NEW: Create selective overlay that allows interaction with game elements
  Widget _buildSelectiveOverlay(TutorialService tutorialService) {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        return CustomPaint(
          painter: TutorialOverlayPainter(
            step: tutorialService.currentStep,
            screenSize: MediaQuery.of(context).size,
            allowGameInteraction: _shouldAllowGameInteraction(tutorialService.currentStep),
          ),
          size: Size.infinite,
        );
      },
    );
  }
  
  // Determine which steps should allow game interaction
  bool _shouldAllowGameInteraction(int step) {
    switch (step) {
      case 1: // Piece selection
      case 2: // Piece placement
      case 3: // Line clearing
      case 4: // Gravity
      case 5: // Combo
        return true;
      default:
        return false; // Welcome and completion steps block interaction
    }
  }
  
  Widget _buildTutorialHeader(TutorialService tutorialService) {
    return Positioned(
      top: 70, // Moved down to avoid skip button
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.school, color: Colors.cyan, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'TUTORIAL',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Step ${tutorialService.currentStep + 1}/${tutorialService.totalSteps}',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (tutorialService.currentStep + 1) / tutorialService.totalSteps,
              backgroundColor: Colors.cyan.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
            ),
          ],
        ),
      ),
    );
  }
  
  // FIXED: Skip button without any IgnorePointer wrapper
  Widget _buildSkipButton(TutorialService tutorialService) {
    return Positioned(
      top: 10, // Positioned above the header
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
        ),
        child: TextButton(
          onPressed: () {
            print('Skip button pressed!'); // DEBUG: Verify button works
            _showSkipConfirmation(tutorialService);
          },
          child: const Text(
            'SKIP',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTutorialStep(TutorialService tutorialService) {
    switch (tutorialService.currentStep) {
      case 0:
        return _buildWelcomeStep(tutorialService);
      case 1:
        return _buildPieceSelectionStep(tutorialService);
      case 2:
        return _buildPlacementStep(tutorialService);
      case 3:
        return _buildLineClearStep(tutorialService);
      case 4:
        return _buildGravityStep(tutorialService);
      case 5:
        return _buildComboStep(tutorialService);
      case 6:
        return _buildCompletionStep(tutorialService);
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildWelcomeStep(TutorialService tutorialService) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apps, color: Colors.cyan, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Grav Blast!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Let\'s learn how to play this puzzle game step by step.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                print('Tutorial: Welcome button pressed, advancing to step 1'); // DEBUG
                context.read<AudioService>().playUIClick();
                tutorialService.nextStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('Let\'s Start!'),
            ),
          ],
        ),
      ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );
  }
  
  Widget _buildPieceSelectionStep(TutorialService tutorialService) {
    return Positioned(
      bottom: 200,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Arrow pointing to pieces
          AnimatedBuilder(
            animation: _arrowController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _arrowController.value * 10),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.cyan,
                  size: 48,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'Step 1: Select a Piece',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap on any piece below to select it.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (tutorialService.isWaitingForPieceSelection) ...[
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2 + _pulseController.value * 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '👆 Tap a piece to continue',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlacementStep(TutorialService tutorialService) {
    return Positioned(
      top: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        child: Column(
          children: [
            const Text(
              'Step 2: Place the Piece',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Now tap anywhere on the grid to place your selected piece.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (tutorialService.isWaitingForPlacement) ...[
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2 + _pulseController.value * 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '👆 Tap the grid to place it',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLineClearStep(TutorialService tutorialService) {
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
        ),
        child: const Column(
          children: [
            Text(
              'Step 3: Clear Lines',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Complete full rows or columns to clear them and score points!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Try to complete the row that\'s almost full.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGravityStep(TutorialService tutorialService) {
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
        ),
        child: const Column(
          children: [
            Text(
              'Step 4: Gravity Effect',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Watch how blocks fall down when lines are cleared!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_downward, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Text(
                  'Gravity pulls everything down',
                  style: TextStyle(
                    color: Colors.purple,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildComboStep(TutorialService tutorialService) {
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.5), width: 2),
        ),
        child: const Column(
          children: [
            Text(
              'Step 5: Combos!',
              style: TextStyle(
                color: Colors.red,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Clear multiple lines in a row for combo bonuses!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Chain reactions = Big points!',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompletionStep(TutorialService tutorialService) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Tutorial Complete!',
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'You\'re ready to master Grav Blast!\n\nRemember: Place pieces, clear lines, build combos!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _completeTutorial(tutorialService),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Playing!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ).animate()
        .scale(duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms),
    );
  }
  
  void _showSkipConfirmation(TutorialService tutorialService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          'Skip Tutorial?',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to skip the tutorial? You can always access it later from the main menu.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            child: const Text('Continue Tutorial', style: TextStyle(color: Colors.cyan)),
          ),
          TextButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
              _completeTutorial(tutorialService);
            },
            child: const Text('Skip', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _completeTutorial(TutorialService tutorialService) async {
    final gameService = context.read<GravBlastService>();
    context.read<AudioService>().playUIClick();
    
    // Mark tutorial as completed
    final storageService = context.read<StorageService>();
    await storageService.setTutorialCompleted();
    
    // Track tutorial completion achievement
    gameService.onTutorialCompleted();
    
    // End tutorial mode
    tutorialService.endTutorial();
    
    // Show completion message briefly then go to menu
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
      }
    });
  }
}

// Custom painter for selective overlay that allows game interaction
class TutorialOverlayPainter extends CustomPainter {
  final int step;
  final Size screenSize;
  final bool allowGameInteraction;

  TutorialOverlayPainter({
    required this.step,
    required this.screenSize,
    required this.allowGameInteraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!allowGameInteraction) {
      // Full overlay for welcome and completion steps
      final paint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
      return;
    }

    // Create overlay with holes for interactive areas
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Create path for overlay
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Define interactive areas based on step
    final interactiveAreas = _getInteractiveAreas(size);
    
    for (final area in interactiveAreas) {
      overlayPath.addRRect(RRect.fromRectAndRadius(area, const Radius.circular(8)));
    }

    // Fill overlay with holes
    overlayPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Draw highlights around interactive areas
    final highlightPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final area in interactiveAreas) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(area, const Radius.circular(8)),
        highlightPaint,
      );
    }
  }

  List<Rect> _getInteractiveAreas(Size size) {
    switch (step) {
      case 1: // Piece selection - highlight piece area
        return [
          Rect.fromLTWH(
            20,
            size.height - 140, // Piece area at bottom
            size.width - 40,
            120,
          ),
        ];
      case 2: // Piece placement - highlight grid area
      case 3: // Line clearing
      case 4: // Gravity
      case 5: // Combo
        return [
          // Grid area
          Rect.fromLTWH(
            20,
            100, // Below header
            size.width - 40,
            size.height - 300, // Above pieces
          ),
          // Piece area
          Rect.fromLTWH(
            20,
            size.height - 140,
            size.width - 40,
            120,
          ),
        ];
      default:
        return [];
    }
  }

  @override
  bool shouldRepaint(covariant TutorialOverlayPainter oldDelegate) {
    return oldDelegate.step != step ||
           oldDelegate.allowGameInteraction != allowGameInteraction;
  }
}