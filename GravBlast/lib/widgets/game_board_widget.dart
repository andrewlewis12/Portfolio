import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/game_models.dart';
import '../services/game_service.dart';

class GravBlastGameWidget extends StatefulWidget {
  const GravBlastGameWidget({Key? key}) : super(key: key);

  @override
  State<GravBlastGameWidget> createState() => _GravBlastGameWidgetState();
}

class _GravBlastGameWidgetState extends State<GravBlastGameWidget>
    with TickerProviderStateMixin {
  GlobalKey _gridKey = GlobalKey();
  late AnimationController _glowController;
  late AnimationController _fallController;
  late AnimationController _gameOverController;
  late AnimationController _fireController; // NEW: Fire animation controller
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }
  
  void _setupAnimations() {
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fallController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _gameOverController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // NEW: Fire animation for board edge
    _fireController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _fallController.dispose();
    _gameOverController.dispose();
    _fireController.dispose(); // NEW: Dispose fire controller
    super.dispose();
  }
  
  @override
  void didUpdateWidget(GravBlastGameWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<GravBlastService>(
      builder: (context, gameService, child) {
        final grid = gameService.currentGrid;
        
        // Trigger animations based on game state
        if (gameService.isShowingGlow) {
          _glowController.forward().then((_) => _glowController.reverse());
        }
        
        if (gameService.isFallingAnimation) {
          _fallController.forward().then((_) => _fallController.reverse());
        }
        
        if (gameService.isShowingGameOverAnimation) {
          _gameOverController.repeat(reverse: true);
        } else {
          _gameOverController.stop();
          _gameOverController.reset();
        }
        
        return Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Grid area
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight - 24;
                    final cellSize = math.min(
                      availableWidth / grid.width,
                      availableHeight / grid.height,
                    ) - 3;
                    
                    final gridWidth = grid.width * (cellSize + 2);
                    final gridHeight = grid.height * (cellSize + 2);
                    
                    return Center(
                      child: SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: Stack(
                          children: [
                            // Main grid with fire border
                            _buildGameGridWithFireBorder(grid, gameService, cellSize),
                            
                            // Falling animation overlay
                            if (gameService.isFallingAnimation)
                              _buildFallingAnimationOverlay(gameService, cellSize),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Available pieces area
              _buildPiecesArea(gameService),
            ],
          ),
        );
      },
    );
  }
  
  // NEW: Build game grid with animated fire border based on combo
  Widget _buildGameGridWithFireBorder(GameGrid grid, GravBlastService gameService, double cellSize) {
    return AnimatedBuilder(
      animation: _fireController,
      builder: (context, child) {
        return Container(
          key: _gridKey,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getFireBorderColor(gameService.combo),
              width: _getFireBorderWidth(gameService.combo),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.grey.shade900.withOpacity(0.9),
              ],
            ),
            // NEW: Fire glow effect
            boxShadow: _getFireBoxShadow(gameService.combo),
          ),
          child: Stack(
            children: [
              // Main grid content
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(4),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: grid.width,
                    childAspectRatio: 1.0,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: grid.width * grid.height,
                  itemBuilder: (context, index) {
                    final x = index % grid.width;
                    final y = index ~/ grid.width;
                    final cell = grid.getCell(x, y);
                    
                    return GestureDetector(
                      onTap: () => gameService.placePiece(x, y),
                      child: _buildGridCell(cell, gameService),
                    );
                  },
                ),
              ),
              
              // NEW: Fire edge overlay for high combos
              if (gameService.combo >= 3)
                _buildFireEdgeOverlay(gameService.combo, cellSize, grid),
            ],
          ),
        );
      },
    );
  }
  
  // NEW: Get fire border color based on combo level
  Color _getFireBorderColor(int combo) {
    if (combo >= 8) {
      // Purple fire for massive combos
      return Colors.purple.withOpacity(0.8);
    } else if (combo >= 5) {
      // Red fire for high combos  
      return Colors.red.withOpacity(0.8);
    } else if (combo >= 3) {
      // Orange fire for medium combos
      return Colors.orange.withOpacity(0.8);
    } else {
      // Normal cyan border
      return Colors.cyan.withOpacity(0.5);
    }
  }
  
  // NEW: Get fire border width based on combo level
  double _getFireBorderWidth(int combo) {
    if (combo >= 8) {
      return 5.0; // Thickest border for massive combos
    } else if (combo >= 5) {
      return 4.0; // Thick border for high combos
    } else if (combo >= 3) {
      return 3.5; // Medium border for medium combos
    } else {
      return 3.0; // Normal border
    }
  }
  
  // NEW: Get fire box shadow based on combo level
  List<BoxShadow> _getFireBoxShadow(int combo) {
    final fireIntensity = (_fireController.value * 0.5 + 0.5); // 0.5 to 1.0
    
    if (combo >= 8) {
      // Purple fire glow with intense pulsing
      return [
        BoxShadow(
          color: Colors.purple.withOpacity(0.6 * fireIntensity),
          blurRadius: 25 * fireIntensity,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.pink.withOpacity(0.4 * fireIntensity),
          blurRadius: 35 * fireIntensity,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.3 * fireIntensity),
          blurRadius: 15 * fireIntensity,
          offset: const Offset(0, 0),
        ),
      ];
    } else if (combo >= 5) {
      // Red fire glow with strong pulsing
      return [
        BoxShadow(
          color: Colors.red.withOpacity(0.6 * fireIntensity),
          blurRadius: 20 * fireIntensity,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.orange.withOpacity(0.4 * fireIntensity),
          blurRadius: 30 * fireIntensity,
          offset: const Offset(0, 0),
        ),
      ];
    } else if (combo >= 3) {
      // Orange fire glow with medium pulsing
      return [
        BoxShadow(
          color: Colors.orange.withOpacity(0.5 * fireIntensity),
          blurRadius: 15 * fireIntensity,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: Colors.yellow.withOpacity(0.3 * fireIntensity),
          blurRadius: 25 * fireIntensity,
          offset: const Offset(0, 0),
        ),
      ];
    } else {
      // Normal cyan glow
      return [
        BoxShadow(
          color: Colors.cyan.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        ),
      ];
    }
  }
  
  // NEW: Build animated fire edge overlay
  Widget _buildFireEdgeOverlay(int combo, double cellSize, GameGrid grid) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CustomPaint(
          painter: FireEdgePainter(
            animation: _fireController,
            combo: combo,
            gridWidth: grid.width,
            gridHeight: grid.height,
            cellSize: cellSize,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
  
  Widget _buildGridCell(GridCell cell, GravBlastService gameService) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _fallController]),
      builder: (context, child) {
        final glowIntensity = cell.isGlowing ? (1.0 + _glowController.value * 0.8) : 1.0;
        final glowColor = cell.isGlowing 
            ? Colors.white.withOpacity(0.4 + _glowController.value * 0.6)
            : Colors.transparent;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: _getCellColor(cell),
            border: Border.all(
              color: _getCellBorderColor(cell, gameService.isShowingGlow),
              width: cell.isGlowing ? 2.0 : 1.0,
            ),
            boxShadow: cell.isGlowing ? [
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 8 * glowIntensity,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: cell.color.withOpacity(0.6),
                blurRadius: 12 * glowIntensity,
                offset: const Offset(0, 0),
              ),
            ] : null,
          ),
          child: cell.isGlowing 
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: glowColor,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
  
  Widget _buildFallingAnimationOverlay(GravBlastService gameService, double cellSize) {
    return AnimatedBuilder(
      animation: _fallController,
      builder: (context, child) {
        final fallProgress = _fallController.value;
        
        return Stack(
          children: [
            ...gameService.fallingBlocks.expand((columnBlocks) {
              return columnBlocks.map((block) {
                final startY = block.y * (cellSize + 2) + 4;
                final endY = startY + (cellSize * 2 * fallProgress);
                
                final currentY = startY + (endY - startY) * _getCubicEaseOut(fallProgress);
                
                return Positioned(
                  left: block.x * (cellSize + 2) + 4,
                  top: currentY,
                  width: cellSize,
                  height: cellSize,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: block.color.withOpacity(0.8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: block.color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            block.color,
                            block.color.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              });
            }).toList(),
          ],
        );
      },
    );
  }
  
  double _getCubicEaseOut(double t) {
    final f = t - 1.0;
    return f * f * f + 1.0;
  }
  
  Color _getCellColor(GridCell cell) {
    switch (cell.state) {
      case CellState.empty:
        return Colors.grey.shade800.withOpacity(0.3);
      case CellState.filled:
        return cell.color;
      case CellState.preview:
        return cell.color.withOpacity(0.6);
      case CellState.falling:
        return cell.color.withOpacity(0.8);
    }
  }
  
  Color _getCellBorderColor(GridCell cell, bool isGlowActive) {
    switch (cell.state) {
      case CellState.empty:
        return Colors.cyan.withOpacity(0.1);
      case CellState.filled:
        if (cell.isGlowing && isGlowActive) {
          return Colors.white.withOpacity(0.9);
        }
        return Colors.white.withOpacity(0.4);
      case CellState.preview:
        return Colors.white.withOpacity(0.8);
      case CellState.falling:
        return Colors.white.withOpacity(0.6);
    }
  }
  
  Widget _buildPiecesArea(GravBlastService gameService) {
    final keyString = gameService.availablePieces
        .map((p) => '${p.id}_${p.name}_${p.blocks.length}')
        .join('_');
    
    return Container(
      key: ValueKey('pieces_$keyString'),
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gameService.isShowingGameOverAnimation 
              ? Colors.red.withOpacity(0.8)
              : Colors.cyan.withOpacity(0.3),
          width: gameService.isShowingGameOverAnimation ? 3 : 2,
        ),
        boxShadow: gameService.isShowingGameOverAnimation ? [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 0),
          ),
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: gameService.availablePieces.asMap().entries.map((entry) {
          final index = entry.key;
          final piece = entry.value;
          
          final isSelected = gameService.selectedPiece?.id == piece.id;
          final isDragged = gameService.draggedPiece?.id == piece.id;
          
          return _buildDraggablePieceWidget(
            piece, 
            isSelected, 
            isDragged, 
            gameService,
            index,
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildDraggablePieceWidget(
    GamePiece piece, 
    bool isSelected, 
    bool isDragged, 
    GravBlastService gameService,
    int index,
  ) {
    final bounds = piece.getBounds();
    final maxSize = math.max(bounds.width, bounds.height);
    final cellSize = 50.0 / maxSize;
    
    final uniqueKey = ValueKey('piece_${piece.id}_${index}_${piece.blocks.length}_${piece.color.value}');
    
    return AnimatedBuilder(
      animation: _gameOverController,
      builder: (context, child) {
        final isGameOverAnimation = gameService.isShowingGameOverAnimation;
        final shakeOffset = isGameOverAnimation 
            ? Offset(math.sin(_gameOverController.value * math.pi * 8) * 2, 0)
            : Offset.zero;
        
        return Transform.translate(
          offset: shakeOffset,
          child: Opacity(
            opacity: isDragged ? 0.3 : (isGameOverAnimation ? 0.7 : 1.0),
            child: GestureDetector(
              key: uniqueKey,
              onTap: () => gameService.selectPiece(piece),
              onPanStart: (details) {
                gameService.startDrag(piece, details.globalPosition);
              },
              onPanUpdate: (details) {
                gameService.updateDrag(details.globalPosition);
                
                if (_gridKey.currentContext != null) {
                  final RenderBox? gridBox = _gridKey.currentContext!.findRenderObject() as RenderBox?;
                  if (gridBox != null) {
                    try {
                      final verticalOffset = -60.0;
                      final adjustedPosition = Offset(
                        details.globalPosition.dx,
                        details.globalPosition.dy + verticalOffset,
                      );
                      
                      final gridLocalPosition = gridBox.globalToLocal(adjustedPosition);
                      final grid = gameService.currentGrid;
                      final gridSize = gridBox.size;
                      final cellSize = gridSize.width / grid.width;
                      
                      final bounds = piece.getBounds();
                      final pieceCenterX = bounds.width / 2;
                      final pieceCenterY = bounds.height / 2;
                      
                      final pieceTopLeftX = gridLocalPosition.dx - (pieceCenterX * cellSize);
                      final pieceTopLeftY = gridLocalPosition.dy - (pieceCenterY * cellSize);
                      
                      final gridX = (pieceTopLeftX / cellSize).round();
                      final gridY = (pieceTopLeftY / cellSize).round();
                      
                      if (gridX >= 0 && gridY >= 0 && gridX < grid.width && gridY < grid.height) {
                        gameService.showPreview(gridX, gridY);
                      } else {
                        gameService.clearPreview();
                      }
                    } catch (e) {
                      gameService.clearPreview();
                    }
                  }
                }
              },
              onPanEnd: (details) {
                final verticalOffset = -60.0;
                final adjustedPosition = Offset(
                  details.globalPosition.dx,
                  details.globalPosition.dy + verticalOffset,
                );
                
                final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
                gameService.endDrag(adjustedPosition, gridBox);
              },
              onPanCancel: () => gameService.cancelDrag(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.cyan.withOpacity(0.3) 
                      : (isGameOverAnimation 
                          ? Colors.red.withOpacity(0.2) 
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.cyan 
                        : (isGameOverAnimation 
                            ? Colors.red.withOpacity(0.6)
                            : Colors.white.withOpacity(0.2)),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isGameOverAnimation ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ] : null,
                ),
                child: Transform.scale(
                  scale: isSelected ? 1.1 : 1.0,
                  child: CustomPaint(
                    key: ValueKey('painter_${piece.id}_${piece.blocks.length}'),
                    painter: SimplePiecePainter(
                      piece: piece,
                      cellSize: cellSize,
                      isSelected: isSelected,
                      isGameOverAnimation: isGameOverAnimation,
                    ),
                    size: Size(bounds.width * cellSize, bounds.height * cellSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// NEW: Fire Edge Painter for animated fire effects around the board
class FireEdgePainter extends CustomPainter {
  final Animation<double> animation;
  final int combo;
  final int gridWidth;
  final int gridHeight;
  final double cellSize;
  
  FireEdgePainter({
    required this.animation,
    required this.combo,
    required this.gridWidth,
    required this.gridHeight,
    required this.cellSize,
  }) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (combo < 3) return; // No fire for low combos
    
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Get fire colors based on combo level
    final fireColors = _getFireColors(combo);
    
    // Draw fire particles around the edge
    _drawFireParticles(canvas, size, time, paint, fireColors);
  }
  
  List<Color> _getFireColors(int combo) {
    if (combo >= 8) {
      // Purple fire for massive combos
      return [
        Colors.purple,
        const Color.fromARGB(255, 233, 30, 148),
        const Color.fromARGB(255, 255, 0, 0),
        Colors.deepPurple,
      ];
    } else if (combo >= 5) {
      // Red fire for high combos
      return [
        Colors.red,
        const Color.fromARGB(255, 255, 60, 0),
        Colors.yellow,
        const Color.fromARGB(255, 255, 145, 0),
      ];
    } else {
      // Orange fire for medium combos
      return [
        Colors.orange,
        Colors.yellow,
        const Color.fromARGB(255, 255, 77, 65),
        Colors.white,
      ];
    }
  }
  
  void _drawFireParticles(Canvas canvas, Size size, double time, Paint paint, List<Color> colors) {
    final particleCount = 30 + (combo * 5); // More particles for higher combos
    final intensity = combo >= 8 ? 1.0 : combo >= 5 ? 0.8 : 0.6;
    
    for (int i = 0; i < particleCount; i++) {
      final progress = (i / particleCount) * 2 * math.pi;
      final fireWave = math.sin(time * 3 + progress * 4) * 0.5 + 0.5;
      final alpha = (math.sin(time * 2 + i * 0.5) + 1) * 0.3 * intensity;
      
      // Position particles around the perimeter
      Offset position;
      final side = i % 4;
      final sideProgress = (i / 4) / (particleCount / 4);
      
      switch (side) {
        case 0: // Top edge
          position = Offset(sideProgress * size.width, 5 + fireWave * 15);
          break;
        case 1: // Right edge
          position = Offset(size.width - 5 - fireWave * 15, sideProgress * size.height);
          break;
        case 2: // Bottom edge
          position = Offset((1 - sideProgress) * size.width, size.height - 5 - fireWave * 15);
          break;
        case 3: // Left edge
          position = Offset(5 + fireWave * 15, (1 - sideProgress) * size.height);
          break;
        default:
          position = Offset.zero;
      }
      
      final colorIndex = (i + (time * 10).round()) % colors.length;
      paint.color = colors[colorIndex].withOpacity(alpha);
      
      final radius = 2.0 + fireWave * 4 + (combo * 0.3);
      canvas.drawCircle(position, radius, paint);
      
      // Add glow effect for higher combos
      if (combo >= 5) {
        paint.color = colors[colorIndex].withOpacity(alpha * 0.3);
        canvas.drawCircle(position, radius * 2, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant FireEdgePainter oldDelegate) {
    return oldDelegate.combo != combo || 
           oldDelegate.animation.value != animation.value;
  }
}

// FIXED: Updated painter to handle piece changes properly + "No More Moves" visual feedback
class SimplePiecePainter extends CustomPainter {
  final GamePiece piece;
  final double cellSize;
  final bool isSelected;
  final bool isGameOverAnimation; // NEW: Game over animation state
  
  SimplePiecePainter({
    required this.piece,
    required this.cellSize,
    required this.isSelected,
    this.isGameOverAnimation = false, // NEW: Default to false
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Clear the canvas first to prevent ghosting
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.transparent,
    );
    
    for (final block in piece.blocks) {
      final rect = Rect.fromLTWH(
        block.x * cellSize,
        block.y * cellSize,
        cellSize - 2,
        cellSize - 2,
      );
      
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      
      // NEW: Modified colors for game over animation
      Color pieceColor = piece.color;
      if (isGameOverAnimation) {
        // Tint red during "No More Moves" animation
        pieceColor = Color.lerp(piece.color, Colors.red, 0.5) ?? piece.color;
      }
      
      // Simple gradient for better performance
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          pieceColor,
          pieceColor.withOpacity(0.8),
        ],
      );
      
      final paint = Paint()..shader = gradient.createShader(rect);
      canvas.drawRRect(rrect, paint);
      
      // Simple border - red tint during game over animation
      final borderColor = isGameOverAnimation 
          ? Colors.red.withOpacity(0.8)
          : Colors.white.withOpacity(isSelected ? 0.8 : 0.5);
      
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(rrect, borderPaint);
      
      // Simple highlight
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawRRect(rrect, highlightPaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant SimplePiecePainter oldDelegate) {
    // Repaint if any piece properties changed
    return oldDelegate.piece.id != piece.id ||
           oldDelegate.piece.color != piece.color ||
           oldDelegate.piece.blocks.length != piece.blocks.length ||
           oldDelegate.isSelected != isSelected ||
           oldDelegate.isGameOverAnimation != isGameOverAnimation || // NEW: Check game over state
           oldDelegate.cellSize != cellSize;
  }
}