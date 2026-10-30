import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/audio_service.dart';
import '../services/game_service.dart';
import '../services/ad_service.dart';
import '../services/tutorial_service.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/score_display.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/ui_overlay.dart';
import 'menu_screen.dart';
import '../widgets/achievement_notification.dart';

class GravBlastScreen extends StatefulWidget {
  final bool isTutorialMode; // NEW: Add tutorial mode flag
  
  const GravBlastScreen({
    Key? key, 
    this.isTutorialMode = false, // NEW: Default to false
  }) : super(key: key);

  @override
  State<GravBlastScreen> createState() => _GravBlastScreenState();
}

class _GravBlastScreenState extends State<GravBlastScreen> {
  
  @override
  void initState() {
    super.initState();
    _loadGame();
  }
  
  @override
  void dispose() {
    // Reset banner ad state when leaving game screen
    try {
      context.read<AdService>().resetBannerAdState();
    } catch (e) {
      // Handle case where context might not be available
      print('Could not reset banner ad state: $e');
    }
    super.dispose();
  }
  
  void _loadGame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isTutorialMode) { // NEW: Only load progress if not tutorial
        context.read<GravBlastService>().loadProgress();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Simple gradient background for better performance
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
            ),
            
            // Main game layout
            Column(
              children: [
                // Top UI - Modified for tutorial mode
                _buildTopUI(),
                
                // Game area
                Expanded(
                  child: Column(
                    children: [
                      // Game grid area
                      Expanded(
                        child: const GravBlastGameWidget(),
                      ),
                      
                      // Bottom stats area - Hide in tutorial mode
                      if (!widget.isTutorialMode)
                        Consumer<GravBlastService>(
                          builder: (context, gameService, child) {
                            return Container(
                              height: 97,
                              margin: const EdgeInsets.all(8),
                              child: _buildBottomStats(gameService),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Global drag overlay - Same as before
            Consumer<GravBlastService>(
              builder: (context, gameService, child) {
                if (gameService.isDragging && gameService.draggedPiece != null && gameService.dragPosition != null) {
                  return _buildGlobalDragOverlay(gameService);
                }
                return const SizedBox.shrink();
              },
            ),
            
            // Game overlays (includes existing overlays)
            const GravBlastUIOverlay(),
            
            // NEW: Achievement notification overlay (only if not in tutorial mode)
            if (!widget.isTutorialMode)
              const AchievementNotificationOverlay(),
            
            // Tutorial overlay (only in tutorial mode)
            if (widget.isTutorialMode)
              const TutorialOverlay(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlobalDragOverlay(GravBlastService gameService) {
    // Same as existing implementation
    final piece = gameService.draggedPiece!;
    final dragPosition = gameService.dragPosition!;
    final bounds = piece.getBounds();
    
    final cellSize = 30.0;
    final pieceWidth = bounds.width * cellSize;
    final pieceHeight = bounds.height * cellSize;
    final verticalOffset = -60.0;
    final horizontalOffset = 0.0;
    
    return Positioned(
      left: dragPosition.dx - (pieceWidth / 2) + horizontalOffset,
      top: dragPosition.dy - (pieceHeight / 2) + verticalOffset,
      child: IgnorePointer(
        child: Transform.scale(
          scale: 1.0,
          child: Opacity(
            opacity: 0.8,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                  BoxShadow(
                    color: piece.color.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: DragPiecePainter(
                  piece: piece,
                  cellSize: cellSize,
                ),
                size: Size(pieceWidth, pieceHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopUI() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Menu button - Modified for tutorial
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
            ),
            child: IconButton(
              onPressed: widget.isTutorialMode ? null : () { // NEW: Disable in tutorial
                final audioService = context.read<AudioService>();
                audioService.playUIClick();
                _showPauseMenu();
              },
              icon: Icon(
                widget.isTutorialMode ? Icons.school : Icons.menu, // NEW: Different icon
                color: widget.isTutorialMode ? Colors.grey : Colors.cyan, // NEW: Greyed out
                size: 24,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Score display - Only show if not tutorial mode
          if (!widget.isTutorialMode)
            const GravBlastScoreDisplay(),
          
          // NEW: Tutorial progress indicator (only in tutorial mode)
          if (widget.isTutorialMode)
            Consumer<TutorialService>(
              builder: (context, tutorialService, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.school, color: Colors.cyan, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tutorial ${tutorialService.currentStep + 1}/${tutorialService.totalSteps}',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          const Spacer(),
          
          // Info button - Disabled in tutorial mode
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
            ),
            child: IconButton(
              onPressed: widget.isTutorialMode ? null : () { // NEW: Disable in tutorial
                final audioService = context.read<AudioService>();
                audioService.playUIClick();
                _showGameInfo();
              },
              icon: Icon(
                Icons.info_outline, 
                color: widget.isTutorialMode ? Colors.grey : Colors.cyan, // NEW: Greyed out
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomStats(GravBlastService gameService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          // Level progress bar
          Row(
            children: [
              Text(
                'LEVEL ${gameService.level}',
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: LinearProgressIndicator(
                  value: gameService.getLevelProgress(),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${gameService.getPointsToNextLevel()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Lines', gameService.linesCleared.toString(), Icons.view_headline, Colors.green),
              _buildVerticalDivider(),
              if (gameService.combo > 1) ...[
                _buildComboItem(gameService.combo),
                _buildVerticalDivider(),
              ],
              _buildActionButton('Reset', Icons.refresh, () { context.read<AudioService>().playUIClick; _showResetDialog(); }, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildComboItem(int combo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
        const SizedBox(height: 2),
        Text(
          'x$combo',
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'COMBO',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.cyan.withOpacity(0.3),
    );
  }
  
  void _showPauseMenu() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          'Game Paused',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuButton('Resume', Icons.play_arrow, Colors.green, () => _navigatorPop()),
            const SizedBox(height: 12),
            _buildMenuButton('How to Play', Icons.help_outline, Colors.blue, () {
              _navigatorPop();
              _showHowToPlay();
            }),
            const SizedBox(height: 12),
            _buildMenuButton('Main Menu', Icons.home, Colors.orange, () {
              _navigatorPop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MenuScreen()),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _navigatorPop()
  {
    final audioService = context.read<AudioService>();
    audioService.playUIClick();
    Navigator.of(context).pop();
  }

  void _showGameInfo() {
    final gameService = context.read<GravBlastService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          'Game Stats',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Current Score', gameService.score.toString()),
            _buildStatRow('High Score', gameService.highScore.toString()),
            _buildStatRow('Level', gameService.level.toString()),
            _buildStatRow('Lines Cleared', gameService.linesCleared.toString()),
            _buildStatRow('Available Pieces', gameService.availablePieces.length.toString()),
            if (gameService.combo > 1)
              _buildStatRow('Current Combo', '${gameService.combo}x'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _navigatorPop(),
            child: const Text('Close', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }
  
  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          'How to Play Grav Blast',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 Drag and drop pieces onto the grid', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Text('📏 Fill complete rows or columns to clear them', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Text('⬇️ Blocks fall down after clearing lines', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Text('🔥 Chain clears for combo bonuses', style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Text('📈 Level up every 5000 points', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _navigatorPop(),
            child: const Text('Got it!', style: TextStyle(color: Colors.cyan)),
          ),
        ],
      ),
    );
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        title: const Text(
          'Reset Game?',
          style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This will start a new game and reset your current progress.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => _navigatorPop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              _navigatorPop();
              context.read<GravBlastService>().resetGame();
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildMenuButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// Optimized drag piece painter with smaller size
class DragPiecePainter extends CustomPainter {
  final GamePiece piece;
  final double cellSize;
  
  DragPiecePainter({
    required this.piece,
    required this.cellSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (final block in piece.blocks) {
      final rect = Rect.fromLTWH(
        block.x * cellSize,
        block.y * cellSize,
        cellSize - 1, // Slightly smaller gap
        cellSize - 1,
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4)); // Smaller radius
      
      // Simple solid color for performance
      final paint = Paint()
        ..color = piece.color
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(rrect, paint);
      
      // White border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5; // Thinner border
      
      canvas.drawRRect(rrect, borderPaint);
      
      // Simple highlight - smaller
      final highlightRect = Rect.fromLTWH(
        block.x * cellSize + 3,
        block.y * cellSize + 3,
        cellSize - 7, // Smaller highlight
        cellSize - 7,
      );
      
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.3) // Less intense
        ..style = PaintingStyle.fill;
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, const Radius.circular(2)),
        highlightPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}