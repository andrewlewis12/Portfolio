// tutorial_service.dart - FIXED gravity demonstration setup
import 'dart:math' show Random;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class TutorialService extends ChangeNotifier {
  bool _isActive = false;
  int _currentStep = 0;
  final int _totalSteps = 7;
  
  bool _isTrailerMode = false;
  // Tutorial state tracking
  bool _isWaitingForPieceSelection = false;
  bool _isWaitingForPlacement = false;
  bool _isWaitingForSpecificEvent = false; // NEW: For steps that need specific events
  GamePiece? _requiredPiece;
  int? _requiredX;
  int? _requiredY;
  
  // NEW: Callback for when step changes (used by game service)
  VoidCallback? onStepChanged;
  
  // Getters
  bool get isActive => _isActive;
  int get currentStep => _currentStep;
  int get totalSteps => _totalSteps;
  bool get isWaitingForPieceSelection => _isWaitingForPieceSelection;
  bool get isWaitingForPlacement => _isWaitingForPlacement;
  bool get isWaitingForSpecificEvent => _isWaitingForSpecificEvent; // NEW
  GamePiece? get requiredPiece => _requiredPiece;
  int? get requiredX => _requiredX;
  int? get requiredY => _requiredY;
  
  void startTutorial() {
    _isActive = true;
    _currentStep = 0;
    _resetStepState();
    notifyListeners();
  }
  
  void endTutorial() {
    _isActive = false;
    _resetStepState();
    notifyListeners();
  }
  
  void nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _currentStep++;
      _resetStepState();
      _setupCurrentStep();
      
      // NEW: Notify game service to setup grid for new step
      onStepChanged?.call();
      
      notifyListeners();
    }
  }
  
  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _resetStepState();
      _setupCurrentStep();
      notifyListeners();
    }
  }
  bool get isTrailerMode => _isTrailerMode;
  
  // NEW: Start trailer mode
  void startTrailerMode() {
    _isTrailerMode = true;
    _isActive = false; // Different from tutorial mode
    notifyListeners();
  }
  
  void endTrailerMode() {
    _isTrailerMode = false;
    notifyListeners();
  }
  
  // NEW: Setup trailer-specific game states
  void setupTrailerScene(String sceneType, GameGrid gameGrid, List<GamePiece> pieces) {
    if (!_isTrailerMode) return;
    
    // Clear the grid first
    for (int y = 0; y < gameGrid.height; y++) {
      for (int x = 0; x < gameGrid.width; x++) {
        gameGrid.setCell(x, y, GridCell(x: x, y: y));
      }
    }
    
    pieces.clear();
    
    switch (sceneType) {
      case 'piece_placement':
        _setupPiecePlacementScene(gameGrid, pieces);
        break;
      case 'line_clear':
        _setupLineClearScene(gameGrid, pieces);
        break;
      case 'combo':
        _setupComboScene(gameGrid, pieces);
        break;
      case 'full_gameplay':
        _setupFullGameplayScene(gameGrid, pieces);
        break;
    }
  }
  
  void _setupPiecePlacementScene(GameGrid gameGrid, List<GamePiece> pieces) {
    // Create a partially filled grid showing various piece shapes
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];
    
    // Add some existing pieces in interesting patterns
    // L-shape
    gameGrid.setCell(1, 5, GridCell(x: 1, y: 5, state: CellState.filled, color: colors[0]));
    gameGrid.setCell(1, 6, GridCell(x: 1, y: 6, state: CellState.filled, color: colors[0]));
    gameGrid.setCell(1, 7, GridCell(x: 1, y: 7, state: CellState.filled, color: colors[0]));
    gameGrid.setCell(2, 7, GridCell(x: 2, y: 7, state: CellState.filled, color: colors[0]));
    
    // T-shape
    gameGrid.setCell(4, 6, GridCell(x: 4, y: 6, state: CellState.filled, color: colors[1]));
    gameGrid.setCell(3, 7, GridCell(x: 3, y: 7, state: CellState.filled, color: colors[1]));
    gameGrid.setCell(4, 7, GridCell(x: 4, y: 7, state: CellState.filled, color: colors[1]));
    gameGrid.setCell(5, 7, GridCell(x: 5, y: 7, state: CellState.filled, color: colors[1]));
    
    // Generate interesting pieces to place
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0), BlockPosition(1, 0), BlockPosition(2, 0)],
      color: colors[2],
      id: 3001,
      name: 'trailer_line',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0), BlockPosition(0, 1), BlockPosition(1, 0), BlockPosition(1, 1)],
      color: colors[3],
      id: 3002,
      name: 'trailer_square',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0), BlockPosition(1, 0), BlockPosition(1, 1), BlockPosition(2, 1)],
      color: colors[4],
      id: 3003,
      name: 'trailer_z',
    ));
  }
  
  void _setupLineClearScene(GameGrid gameGrid, List<GamePiece> pieces) {
    // Fill most of row 7, leaving one gap
    for (int x = 0; x < 7; x++) {
      gameGrid.setCell(x, 7, GridCell(
        x: x, y: 7,
        state: CellState.filled,
        color: Colors.blue,
      ));
    }
    
    // Fill most of row 6, leaving two gaps
    for (int x = 0; x < 6; x++) {
      if (x != 2) { // Leave gap at position 2
        gameGrid.setCell(x, 6, GridCell(
          x: x, y: 6,
          state: CellState.filled,
          color: Colors.green,
        ));
      }
    }
    
    // Add floating blocks that will fall dramatically
    gameGrid.setCell(3, 3, GridCell(x: 3, y: 3, state: CellState.filled, color: Colors.red));
    gameGrid.setCell(4, 2, GridCell(x: 4, y: 2, state: CellState.filled, color: Colors.orange));
    gameGrid.setCell(5, 4, GridCell(x: 5, y: 4, state: CellState.filled, color: Colors.purple));
    
    // Pieces to complete the lines
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0)],
      color: Colors.blue,
      id: 3004,
      name: 'trailer_complete1',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0)],
      color: Colors.green,
      id: 3005,
      name: 'trailer_complete2',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0), BlockPosition(1, 0)],
      color: Colors.cyan,
      id: 3006,
      name: 'trailer_double',
    ));
  }
  
  void _setupComboScene(GameGrid gameGrid, List<GamePiece> pieces) {
    // Setup for multiple cascading line clears
    
    // Row 7 - almost complete
    for (int x = 0; x < 7; x++) {
      gameGrid.setCell(x, 7, GridCell(x: x, y: 7, state: CellState.filled, color: Colors.blue));
    }
    
    // Row 6 - almost complete 
    for (int x = 1; x < 8; x++) {
      gameGrid.setCell(x, 6, GridCell(x: x, y: 6, state: CellState.filled, color: Colors.green));
    }
    
    // Column 7 - almost complete (will be completed when row clears happen)
    for (int y = 0; y < 6; y++) {
      gameGrid.setCell(7, y, GridCell(x: 7, y: y, state: CellState.filled, color: Colors.red));
    }
    
    // Strategic blocks that will create the combo
    gameGrid.setCell(0, 5, GridCell(x: 0, y: 5, state: CellState.filled, color: Colors.orange));
    gameGrid.setCell(3, 4, GridCell(x: 3, y: 4, state: CellState.filled, color: Colors.purple));
    gameGrid.setCell(5, 3, GridCell(x: 5, y: 3, state: CellState.filled, color: Colors.yellow));
    
    // The piece that triggers the combo
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0)],
      color: Colors.blue,
      id: 3007,
      name: 'trailer_combo_trigger',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0), BlockPosition(0, 1)],
      color: Colors.cyan,
      id: 3008,
      name: 'trailer_vertical',
    ));
    
    pieces.add(GamePiece(
      blocks: [BlockPosition(0, 0)],
      color: Colors.pink,
      id: 3009,
      name: 'trailer_extra',
    ));
  }
  
  void _setupFullGameplayScene(GameGrid gameGrid, List<GamePiece> pieces) {
    // Create an active, engaging gameplay scene
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.cyan];
    final random = Random();
    
    // Fill about 60% of the grid with interesting patterns
    for (int y = 3; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        if (random.nextDouble() < 0.7) {
          gameGrid.setCell(x, y, GridCell(
            x: x, y: y,
            state: CellState.filled,
            color: colors[random.nextInt(colors.length)],
          ));
        }
      }
    }
    
    // Generate varied, interesting pieces
    final shapes = [
      [BlockPosition(0, 0)], // Single
      [BlockPosition(0, 0), BlockPosition(1, 0)], // Line
      [BlockPosition(0, 0), BlockPosition(0, 1), BlockPosition(1, 0), BlockPosition(1, 1)], // Square
      [BlockPosition(0, 0), BlockPosition(1, 0), BlockPosition(2, 0)], // Line 3
      [BlockPosition(0, 0), BlockPosition(1, 0), BlockPosition(1, 1)], // L
    ];
    
    for (int i = 0; i < 3; i++) {
      pieces.add(GamePiece(
        blocks: shapes[random.nextInt(shapes.length)],
        color: colors[i],
        id: 3010 + i,
        name: 'trailer_gameplay_$i',
      ));
    }
  }

  void _resetStepState() {
    _isWaitingForPieceSelection = false;
    _isWaitingForPlacement = false;
    _isWaitingForSpecificEvent = false; // NEW
    _requiredPiece = null;
    _requiredX = null;
    _requiredY = null;
  }
  
  void _setupCurrentStep() {
    switch (_currentStep) {
      case 1: // Piece selection step
        _isWaitingForPieceSelection = true;
        break;
      case 2: // Basic placement step
        _isWaitingForPlacement = true;
        break;
      case 3: // Line clear step - wait for line clear event
        _isWaitingForSpecificEvent = true;
        break;
      case 4: // Gravity step - wait for gravity event
        _isWaitingForSpecificEvent = true;
        break;
      case 5: // Combo step - wait for combo event
        _isWaitingForSpecificEvent = true;
        break;
      // Other steps don't need special setup
    }
  }
  
  // Called when player selects a piece
  void onPieceSelected(GamePiece piece) {
    if (!_isActive) return;
    
    if (_isWaitingForPieceSelection) {
      _isWaitingForPieceSelection = false;
      nextStep(); // Auto-advance to placement step
    }
  }
  
  // Called when player places a piece
  void onPiecePlaced(int x, int y) {
    if (!_isActive) return;
    
    // Only advance for general placement steps, not specific event steps
    if (_isWaitingForPlacement && !_isWaitingForSpecificEvent) {
      _isWaitingForPlacement = false;
      
      // Small delay then advance to next step
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_isActive) {
          nextStep();
        }
      });
    }
    
    // For steps 3, 4, 5 - piece placement doesn't advance the tutorial
    // Only the specific events (line clear, gravity, combo) will advance
  }
  
  // Called when lines are cleared
  void onLinesCleared(int count) {
    if (!_isActive) return;
    
    if (_currentStep == 3 && _isWaitingForSpecificEvent && count > 0) {
      // Line clear demonstration successful - mark as completed
      _isWaitingForSpecificEvent = false;
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_isActive) {
          nextStep();
        }
      });
    }
  }
  
  // Called when gravity happens
  void onGravityApplied() {
    if (!_isActive) return;
    
    if (_currentStep == 4 && _isWaitingForSpecificEvent) {
      // Gravity demonstration successful - mark as completed
      _isWaitingForSpecificEvent = false;
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_isActive) {
          nextStep();
        }
      });
    }
  }
  
  // Called when combo happens
  void onComboAchieved(int combo) {
    if (!_isActive) return;
    
    if (_currentStep == 5 && _isWaitingForSpecificEvent && combo > 1) {
      // Combo demonstration successful - mark as completed
      _isWaitingForSpecificEvent = false;
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (_isActive) {
          nextStep();
        }
      });
    }
  }
  
  // Check if a piece selection is allowed in tutorial mode
  bool canSelectPiece(GamePiece piece) {
    if (!_isActive) return true;
    
    // During tutorial, any piece can be selected
    return true;
  }
  
  // Check if a piece placement is allowed in tutorial mode
  bool canPlacePiece(GamePiece piece, int x, int y) {
    if (!_isActive) return true;
    
    // During tutorial, allow any valid placement
    // Could add specific restrictions for certain steps if needed
    return true;
  }
  
  // FIXED: Setup tutorial grid states AND generate appropriate pieces
  void setupTutorialStep(int step, GameGrid gameGrid, List<GamePiece> pieces) {
    if (!_isActive) return;
    
    // Clear the grid first for clean setup
    for (int y = 0; y < gameGrid.height; y++) {
      for (int x = 0; x < gameGrid.width; x++) {
        gameGrid.setCell(x, y, GridCell(x: x, y: y));
      }
    }
    
    // Clear existing pieces and generate tutorial-specific pieces
    pieces.clear();
    
    switch (step) {
      case 3: // Line clear demonstration
        // Pre-fill most of a row to demonstrate line clearing (leave one gap)
        for (int x = 0; x < 7; x++) {
          gameGrid.setCell(x, 7, GridCell(
            x: x, y: 7,
            state: CellState.filled,
            color: Colors.blue,
          ));
        }
        
        // Generate a single 1x1 piece to complete the row
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.blue,
          id: 1001,
          name: 'tutorial_single',
          texture: 'solid',
        ));
        
        // Add two other simple pieces for variety
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0), BlockPosition(1, 0)],
          color: Colors.green,
          id: 1002,
          name: 'tutorial_double',
          texture: 'solid',
        ));
        
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.red,
          id: 1003,
          name: 'tutorial_single2',
          texture: 'solid',
        ));
        break;
        
      case 4: // FIXED: Gravity demonstration with proper setup
        // Create floating blocks that will fall when the bottom row is cleared
        gameGrid.setCell(2, 2, GridCell(
          x: 2, y: 2,
          state: CellState.filled,
          color: Colors.orange,
        ));
        gameGrid.setCell(3, 3, GridCell(
          x: 3, y: 3,
          state: CellState.filled,
          color: Colors.purple,
        ));
        gameGrid.setCell(5, 1, GridCell(
          x: 5, y: 1,
          state: CellState.filled,
          color: Colors.green,
        ));
        gameGrid.setCell(1, 4, GridCell(
          x: 1, y: 4,
          state: CellState.filled,
          color: Colors.red,
        ));
        gameGrid.setCell(6, 3, GridCell(
          x: 6, y: 3,
          state: CellState.filled,
          color: Colors.cyan,
        ));
        
        // Add a complete row at the bottom that will be cleared to trigger gravity
        for (int x = 0; x < 7; x++) { // Leave one gap for player to fill
          gameGrid.setCell(x, 7, GridCell(
            x: x, y: 7,
            state: CellState.filled,
            color: Colors.blue,
          ));
        }
        
        // Add some blocks right above the complete row so they fall dramatically
        gameGrid.setCell(2, 6, GridCell(
          x: 2, y: 6,
          state: CellState.filled,
          color: Colors.yellow,
        ));
        gameGrid.setCell(4, 5, GridCell(
          x: 4, y: 5,
          state: CellState.filled,
          color: Colors.pink,
        ));
        gameGrid.setCell(6, 6, GridCell(
          x: 6, y: 6,
          state: CellState.filled,
          color: Colors.amber,
        ));
        
        // FIXED: Generate pieces including the needed 1x1 to complete the row
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.blue,
          id: 1004,
          name: 'tutorial_gravity_single',
          texture: 'solid',
        ));
        
        // Add other simple pieces
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0), BlockPosition(0, 1)],
          color: Colors.orange,
          id: 1005,
          name: 'tutorial_vertical',
          texture: 'solid',
        ));
        
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.green,
          id: 1006,
          name: 'tutorial_single3',
          texture: 'solid',
        ));
        break;
        
      case 5: // Combo demonstration
        // Set up for combo opportunity
        // First row (will be cleared first) - leave one gap
        for (int x = 0; x < 7; x++) {
          gameGrid.setCell(x, 7, GridCell(
            x: x, y: 7,
            state: CellState.filled,
            color: Colors.blue,
          ));
        }
        
        // Add a column that will be completed when blocks fall
        for (int y = 0; y < 7; y++) {
          gameGrid.setCell(7, y, GridCell(
            x: 7, y: y,
            state: CellState.filled,
            color: Colors.green,
          ));
        }
        
        // Add one more block that will help create the combo
        gameGrid.setCell(3, 6, GridCell(
          x: 3, y: 6,
          state: CellState.filled,
          color: Colors.purple,
        ));
        
        // Generate pieces including single block to trigger combo
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.blue,
          id: 1007,
          name: 'tutorial_combo_single',
          texture: 'solid',
        ));
        
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0), BlockPosition(1, 0)],
          color: Colors.green,
          id: 1008,
          name: 'tutorial_combo_double',
          texture: 'solid',
        ));
        
        pieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: Colors.red,
          id: 1009,
          name: 'tutorial_combo_single2',
          texture: 'solid',
        ));
        break;
        
      default:
        // For other steps, generate normal random pieces
        _generateNormalPieces(pieces);
        break;
    }
  }
  
  // Helper method to generate normal pieces for non-special tutorial steps
  void _generateNormalPieces(List<GamePiece> pieces) {
    final random = Random();
    final availableColors = [Colors.cyan, Colors.red, Colors.green, Colors.orange, Colors.purple];
    
    for (int i = 0; i < 3; i++) {
      final shapeIndex = random.nextInt(PieceTemplates.shapes.length);
      final shape = PieceTemplates.shapes[shapeIndex];
      final color = availableColors[i % availableColors.length];
      
      final blocks = <BlockPosition>[];
      for (int y = 0; y < shape.length; y++) {
        for (int x = 0; x < shape[y].length; x++) {
          if (shape[y][x] == 1) {
            blocks.add(BlockPosition(x, y));
          }
        }
      }
      
      pieces.add(GamePiece(
        blocks: blocks,
        color: color,
        id: 2000 + i,
        name: 'tutorial_normal_$i',
        texture: 'solid',
      ));
    }
  }
  
  // This method is kept for compatibility but now calls setupTutorialStep
  void setupTutorialGame(GameGrid grid, List<GamePiece> pieces) {
    // This method is called during game initialization
    // We'll set up the grid when we advance to specific steps
  }
}