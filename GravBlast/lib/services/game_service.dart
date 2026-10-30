import 'dart:convert';
import 'dart:math';
import 'dart:async'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'achievement_service.dart';
import 'audio_service.dart';
import 'storage_service.dart';
import 'ad_service.dart';
import 'tutorial_service.dart';

class GravBlastService extends ChangeNotifier {
  final StorageService _storageService;
  final AudioService _audioService;
  final AdService _adService;
  final TutorialService _tutorialService; 
  final AchievementService _achievementService; 
  
  // Add this property to GravBlastService class:
  bool _shouldShowCombo = false;
  
  // NEW: Add combo timer
  Timer? _comboResetTimer;
  Timer? _comboDisplayTimer;
  
  // FIXED: Add deferred game over check
  Timer? _deferredGameOverTimer;

  // Add this getter:
  bool get shouldShowCombo => _shouldShowCombo && _combo >= 2;

  GameGrid _currentGrid = GameGrid.empty(8, 8);
  List<GamePiece> _availablePieces = [];
  GamePiece? _selectedPiece;
  GamePiece? _draggedPiece;
  bool _isDragging = false;
  Offset? _dragPosition;
  int _score = 0;
  int _highScore = 0;
  int _level = 1;
  int _linesCleared = 0;
  int _combo = 0;
  bool _isGameOver = false;
  bool _isAnimating = false;
  int _nextPieceId = 1;

  int _lastCascadeCycles = 0;
  int _lastCascadeClears = 0;

  // NEW: Achievement tracking variables
  bool _wasRewardedAdUsed = false;
  int _scoreBeforeRewardedAd = 0;
  List<String> _currentGamePieceTypes = [];
  int get lastCascadeCycles => _lastCascadeCycles;
  int get lastCascadeClears => _lastCascadeClears;

  // FIXED: Combo tracking - simplified and more responsive
  int _consecutiveClears = 0;
  bool _hasActiveCombo = false;
  bool _isShowingComboOverlay = false;
  
  // NEW: Track if this turn had any clears (for combo ending)
  bool _currentTurnHadClears = false;
  
  // NEW: Animation tracking for falling blocks
  bool _isShowingGlow = false;
  bool _isFallingAnimation = false;
  List<List<GridCell>> _fallingBlocks = [];
  
  // NEW: Game over animation state
  bool _isShowingGameOverAnimation = false;
  bool get isShowingGameOverAnimation => _isShowingGameOverAnimation;
  
  // Ad scheduling properties
  int _gamesPlayed = 0;
  bool _hasShownFirstDeathReward = false;
  bool _shouldShowRewardedAdOnDeath = false;
  
  // Game configuration
  static const int GRID_SIZE = 8;
  static const int PIECES_COUNT = 3;
  static const int BASE_LINE_SCORE = 100;
  static const int COMBO_MULTIPLIER = 50;
  
  GravBlastService({
    required StorageService storageService,
    required AudioService audioService,
    required AdService adService,
    required TutorialService tutorialService,
    required AchievementService achievementService, // NEW: Add parameter
  }) : _storageService = storageService,
      _audioService = audioService,
      _adService = adService,
      _tutorialService = tutorialService,
      _achievementService = achievementService { // NEW: Initialize
    
    // NEW: Set up tutorial callback to handle step changes
    _tutorialService.onStepChanged = _setupTutorialGridForCurrentStep;
    
    _initializeGame();
  }

  // Getters
  GameGrid get currentGrid => _currentGrid;
  List<GamePiece> get availablePieces => _availablePieces;
  GamePiece? get selectedPiece => _selectedPiece;
  GamePiece? get draggedPiece => _draggedPiece;
  bool get isDragging => _isDragging;
  Offset? get dragPosition => _dragPosition;
  int get score => _score;
  int get highScore => _highScore;
  int get level => _level;
  int get linesCleared => _linesCleared;
  int get combo => _combo;
  bool get isGameOver => _isGameOver;
  bool get isAnimating => _isAnimating;
  int get gamesPlayed => _gamesPlayed;
  bool get shouldShowRewardedAdOnDeath => _shouldShowRewardedAdOnDeath;
  AchievementService get achievementService => _achievementService;

  TutorialService get tutorialService => _tutorialService;
  // NEW: Getters for animation states
  bool get isShowingGlow => _isShowingGlow;
  bool get isFallingAnimation => _isFallingAnimation;
  List<List<GridCell>> get fallingBlocks => _fallingBlocks;
  
  void _initializeGame() {
    _currentGrid = GameGrid.empty(GRID_SIZE, GRID_SIZE);
    
    // Reset piece state first
    _resetPieceState();
    
    _score = 0;
    _level = 1;
    _linesCleared = 0;
    _combo = 0;
    _consecutiveClears = 0;
    _hasActiveCombo = false;
    _currentTurnHadClears = false;
    _isGameOver = false;
    _isAnimating = false;
    _isShowingGlow = false;
    _isFallingAnimation = false;
    _isShowingGameOverAnimation = false;
    _fallingBlocks.clear();
    _nextPieceId = 1;
    _shouldShowRewardedAdOnDeath = false;
    
    // NEW: Reset achievement tracking
    _wasRewardedAdUsed = false;
    _scoreBeforeRewardedAd = 0;
    _currentGamePieceTypes.clear();
    _achievementService.onGameStarted();
    
    // NEW: Setup tutorial-specific game state if tutorial is active
    if (_tutorialService.isActive) {
      _tutorialService.setupTutorialGame(_currentGrid, _availablePieces);
    }
    
    // Generate new pieces after state reset
    _generateNewPieces();
    notifyListeners(); // Final notification with new pieces
    
    if(shouldShowInterstitialAd() && !_tutorialService.isActive) {
      _adService.showInterstitialAd();
    }
  }

  // UPDATED: placePiece method to track achievements
  Future<void> placePiece(int gridX, int gridY) async {
    final pieceToPlace = _selectedPiece ?? _draggedPiece;
    if (pieceToPlace == null || _isAnimating || _isGameOver) return;
    
    if (!_currentGrid.canPlacePiece(pieceToPlace, gridX, gridY)) {
      return;
    }

    // NEW: Check tutorial constraints
    if (!_tutorialService.canPlacePiece(pieceToPlace, gridX, gridY)) return;

    // FIXED: Reset current turn clear flag at start of each piece placement
    _currentTurnHadClears = false;

    // NEW: Check for perfect fit achievement
    final isPerfectFit = _checkPerfectFit(pieceToPlace, gridX, gridY);
    
    // NEW: Track piece type for minimalist achievement
    final pieceType = pieceToPlace.blocks.length == 1 ? 'single' : 'multi';
    _currentGamePieceTypes.add(pieceType);

    // Place the piece immediately for responsiveness
    _currentGrid.placePiece(pieceToPlace, gridX, gridY);
    _availablePieces.removeWhere((p) => p.id == pieceToPlace.id);
    
    // Clear piece selection state immediately
    _selectedPiece = null;
    _draggedPiece = null;
    _isDragging = false;
    _dragPosition = null;
    
    _audioService.playPiecePlace();
    
    // NEW: Track achievement progress
    _achievementService.onPiecePlaced(pieceType, pieceToPlace.blocks.length, isPerfectFit);
    
    // NEW: Notify tutorial of piece placement
    _tutorialService.onPiecePlaced(gridX, gridY);
    
    notifyListeners(); // Notify immediately after placement

    // Process line clears in background
    await _processLineClears();
    
    // FIXED: Check for combo end BEFORE generating new pieces
    if (!_currentTurnHadClears && _hasActiveCombo) {
      // This turn had no clears - end the combo
      if (kDebugMode) {
        print('Ending combo - no clears this turn');
      }
      _endCombo();
    }
    
    // FIXED: Generate new pieces if needed
    if (_availablePieces.isEmpty) {
      // If combo is showing, wait for it to finish
      if (_isShowingComboOverlay) {
        // Wait for combo animation to complete
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // Small delay to prevent visual glitches
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      _generateNewPieces();
      notifyListeners(); // Ensure UI updates with new pieces
    }
    
    // FIXED: Always schedule game over check, but with appropriate timing
    _scheduleGameOverCheck();
    await saveGameState();

  }

  Future<void> saveGameState() async {
    if (_isGameOver) return; // Don't save if game is over
    
    final gameState = {
      'currentGrid': _serializeGrid(),
      'availablePieces': _serializePieces(),
      'score': _score,
      'level': _level,
      'linesCleared': _linesCleared,
      'combo': _combo,
      'isGameActive': !_isGameOver,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _storageService.saveString('game_state', jsonEncode(gameState));
  }

  Future<void> loadGameState() async {
    final savedState = await _storageService.getString('game_state');
    if (savedState == null) return;
    
    try {
      final Map<String, dynamic> gameState = jsonDecode(savedState);
      
      // Check if save is recent (within 24 hours)
      final timestamp = gameState['timestamp'] as int?;
      if (timestamp != null) {
        final saveTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        if (DateTime.now().difference(saveTime).inHours > 24) {
          // Save is too old, start fresh
          return;
        }
      }
      
      _score = gameState['score'] ?? 0;
      _level = gameState['level'] ?? 1;
      _linesCleared = gameState['linesCleared'] ?? 0;
      _combo = gameState['combo'] ?? 0;
      _isGameOver = !(gameState['isGameActive'] ?? false);
      
      _deserializeGrid(gameState['currentGrid']);
      _deserializePieces(gameState['availablePieces']);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading game state: $e');
      }
    }
  }

  Map<String, dynamic> _serializeGrid() {
    final cellsData = <List<Map<String, dynamic>>>[];
    for (final row in _currentGrid.cells) {
      final rowData = <Map<String, dynamic>>[];
      for (final cell in row) {
        rowData.add({
          'x': cell.x,
          'y': cell.y,
          'state': cell.state.index,
          'color': cell.color.value,
          'pieceId': cell.pieceId,
        });
      }
      cellsData.add(rowData);
    }
    return {
      'cells': cellsData,
      'width': _currentGrid.width,
      'height': _currentGrid.height,
    };
  }

  void _deserializeGrid(Map<String, dynamic>? gridData) {
    if (gridData == null) return;
    
    final cells = <List<GridCell>>[];
    final cellsData = gridData['cells'] as List<dynamic>;
    
    for (final rowData in cellsData) {
      final row = <GridCell>[];
      for (final cellData in rowData) {
        row.add(GridCell(
          x: cellData['x'],
          y: cellData['y'],
          state: CellState.values[cellData['state']],
          color: Color(cellData['color']),
          pieceId: cellData['pieceId'],
        ));
      }
      cells.add(row);
    }
    
    _currentGrid = GameGrid(
      cells: cells,
      width: gridData['width'],
      height: gridData['height'],
    );
  }

  List<Map<String, dynamic>> _serializePieces() {
    return _availablePieces.map((piece) => {
      'blocks': piece.blocks.map((block) => {'x': block.x, 'y': block.y}).toList(),
      'color': piece.color.value,
      'id': piece.id,
      'name': piece.name,
    }).toList();
  }

  void _deserializePieces(List<dynamic>? piecesData) {
    if (piecesData == null) return;
    
    _availablePieces.clear();
    for (final pieceData in piecesData) {
      final blocks = <BlockPosition>[];
      for (final blockData in pieceData['blocks']) {
        blocks.add(BlockPosition(blockData['x'], blockData['y']));
      }
      
      _availablePieces.add(GamePiece(
        blocks: blocks,
        color: Color(pieceData['color']),
        id: pieceData['id'],
        name: pieceData['name'],
      ));
    }
  }

  // NEW: Check if piece placement is a perfect fit
  bool _checkPerfectFit(GamePiece piece, int startX, int startY) {
    // Count empty spaces around the piece placement
    int emptySpacesAroundPiece = 0;
    int totalSpacesAroundPiece = 0;
    
    for (final block in piece.blocks) {
      final x = startX + block.x;
      final y = startY + block.y;
      
      // Check adjacent cells
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue; // Skip the piece block itself
          
          final checkX = x + dx;
          final checkY = y + dy;
          
          if (checkX >= 0 && checkX < _currentGrid.width && 
              checkY >= 0 && checkY < _currentGrid.height) {
            totalSpacesAroundPiece++;
            if (_currentGrid.getCell(checkX, checkY).state == CellState.empty) {
              emptySpacesAroundPiece++;
            }
          }
        }
      }
    }
    
    // Perfect fit if piece fills most empty adjacent spaces
    return totalSpacesAroundPiece > 0 && (emptySpacesAroundPiece / totalSpacesAroundPiece) < 0.3;
  }

  // UPDATED: _addScore method to track achievements
  void _addScore(int points, String reason) {
    final previousScore = _score;
    _score += points;
    
    // NEW: Track score achievements
    _achievementService.onScoreChanged(_score, previousScore);
    
    // NEW: Check minimalist achievement
    if (_currentGamePieceTypes.isNotEmpty && 
        _currentGamePieceTypes.every((type) => type == 'single') && 
        _score >= 1000) {
      _achievementService.onMinimalistScoreReached(_score);
    }
    
    // Update high score
    if (_score > _highScore) {
      _highScore = _score;
      _storageService.saveInt('high_score', _highScore);
    }
    
    // Level up every 5000 points
    final newLevel = (_score ~/ 5000) + 1;
    if (newLevel > _level) {
      final previousLevel = _level;
      _level = newLevel;
      _audioService.playLevelUp();
      
      // NEW: Track level achievements
      _achievementService.onLevelReached(_level);
    }
  }

  // UPDATED: _processLineClears to track achievements
  Future<void> _processLineClears() async {
    bool foundClears = true;
    int totalClearsThisMove = 0;
    int clearCycles = 0;
    bool hadSimultaneousRowColumn = false;
    
    while (foundClears) {
      foundClears = false;
      int clearsThisCycle = 0;
      
      // Check for completed rows
      final completedRows = _currentGrid.getCompletedRows();
      final completedColumns = _currentGrid.getCompletedColumns();
      
      // NEW: Check for simultaneous row and column clear
      if (completedRows.isNotEmpty && completedColumns.isNotEmpty) {
        hadSimultaneousRowColumn = true;
      }
      
      if (completedRows.isNotEmpty) {
        await _animateLineClearing(completedRows, isRow: true);
        _currentGrid.clearRows(completedRows);
        _linesCleared += completedRows.length;
        clearsThisCycle += completedRows.length;
        _addScore(completedRows.length * BASE_LINE_SCORE, 'rows');
        _audioService.playLineClear(); 
        foundClears = true;
      }
      
      if (completedColumns.isNotEmpty) {
        await _animateLineClearing(completedColumns, isRow: false);
        _currentGrid.clearColumns(completedColumns);
        _linesCleared += completedColumns.length;
        clearsThisCycle += completedColumns.length;
        _addScore(completedColumns.length * BASE_LINE_SCORE, 'columns');
        _audioService.playLineClear();
        foundClears = true;
      }
      
      if (foundClears) {
        totalClearsThisMove += clearsThisCycle;
        clearCycles++;
        
        // NEW: Notify tutorial of line clears
        _tutorialService.onLinesCleared(clearsThisCycle);
        
        // Apply gravity with animation
        await _animateGravityFall();
        
        // NEW: Track gravity for achievements
        _achievementService.onGravityTriggered();
        
        // NEW: Notify tutorial of gravity
        _tutorialService.onGravityApplied();
        
        // Short delay between clear cycles
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }
    
    // NEW: Track line clear achievements
    if (totalClearsThisMove > 0) {
      _achievementService.onLineCleared(_linesCleared, hadSimultaneousRowColumn);
    }
    
    // Update combo system with TOTAL clears from this entire move
    if (totalClearsThisMove > 0) {
      _updateComboForMove(totalClearsThisMove, clearCycles);
    }
  }

  // UPDATED: _updateComboForMove to track achievements
  void _updateComboForMove(int totalClears, int cycles) {
    if (totalClears > 0) {
      // Mark that this turn had clears
      _currentTurnHadClears = true;
      
      // Always increment combo for line clears
      _consecutiveClears += totalClears;
      _hasActiveCombo = true;
      _combo = _consecutiveClears;
      
      // NEW: Track combo achievements
      _achievementService.onComboAchieved(_combo);
      
      // NEW: Notify tutorial of combo
      _tutorialService.onComboAchieved(_combo);
      
      // Calculate bonus based on total clears AND number of cycles
      if (_consecutiveClears >= 2) {
        // Base combo bonus
        int comboBonus = _consecutiveClears * COMBO_MULTIPLIER * _level;
        
        // Additional bonus for gravity-triggered multi-cycle clears
        if (cycles > 1) {
          int gravityCascadeBonus = (cycles - 1) * 25 * _level;
          comboBonus += gravityCascadeBonus;
          
          // Extra bonus for high line counts in one move
          if (totalClears >= 4) {
            int massiveClearBonus = totalClears * 10 * _level;
            comboBonus += massiveClearBonus;
          }
        }
        
        _addScore(comboBonus, 'combo');
        _audioService.playCombo(_consecutiveClears);
        
        // Show combo display
        _shouldShowCombo = true;
        _isShowingComboOverlay = true;
        
        if (cycles > 1) {
          _lastCascadeCycles = cycles;
          _lastCascadeClears = totalClears;
        }
        
        // Cancel any existing timer
        _comboDisplayTimer?.cancel();
        
        notifyListeners();
        
        // FIXED: Use a timer that schedules game over check after combo ends
        _comboDisplayTimer = Timer(const Duration(milliseconds: 2500), () {
          _shouldShowCombo = false;
          _isShowingComboOverlay = false;
          _lastCascadeCycles = 0;
          _lastCascadeClears = 0;
          notifyListeners();
          
          // FIXED: Schedule game over check after combo animation ends
          _scheduleGameOverCheck();
        });
      }
      
      // DON'T schedule combo reset here - let it end naturally when no clears happen
    }
  }

  // UPDATED: resetGame to track achievements
  void resetGame() {
    // Clear saved game state when starting new game
    _storageService.saveString('game_state', '');
    _gamesPlayed++;
    _hasShownFirstDeathReward = false;
    _storageService.saveInt('games_played', _gamesPlayed);
    _storageService.saveBool('has_shown_first_death_reward', false);
    
    // NEW: Track game completion for achievements
    _achievementService.onGameCompleted(_gamesPlayed);
    
    // Clear piece state immediately to prevent visual glitches
    _resetPieceState();
    
    // FIXED: Reset combo and all timers properly
    _consecutiveClears = 0;
    _combo = 0;
    _hasActiveCombo = false;
    _shouldShowCombo = false;
    _isShowingComboOverlay = false;
    _currentTurnHadClears = false;
    _comboResetTimer?.cancel();
    _comboDisplayTimer?.cancel();
    _deferredGameOverTimer?.cancel(); // FIXED: Cancel deferred timer
    
    _initializeGame();
  }

  // UPDATED: onRewardedAdCompleted to track achievements
  Future<void> onRewardedAdCompleted() async {
    _shouldShowRewardedAdOnDeath = false;
    
    // NEW: Track rewarded ad usage
    _wasRewardedAdUsed = true;
    _scoreBeforeRewardedAd = _score;
    _achievementService.onRewardedAdUsed(_score);
    
    _audioService.resumeMusic();
    
    // Give player bonus points
    _addScore(1000, 'reward');
    
    // Clear game over state immediately so animations are visible
    _isGameOver = false;
    _isShowingGameOverAnimation = false;
    notifyListeners();
    
    // Small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Strategy 1: Clear some blocks to make space with animation
    await _clearRandomBlocksWithAnimation();
    
    // Clear any existing piece state
    _resetPieceState();
    
    // Strategy 2: Generate guaranteed placeable pieces
    _generatePlaceablePieces();
    
    // Strategy 3: If still no moves, clear more aggressively with animation
    if (_checkGameOverSimple()) {
      await _clearMoreBlocksWithAnimation();
      _resetPieceState();
      _generateSimplePieces();
    }
    
    notifyListeners();
  }

  // NEW: Tutorial completion achievement
  void startTutorial() {
    _tutorialService.startTutorial();
    resetGame(); // Reset game with tutorial setup
    
    // Setup initial step grid if needed
    _setupTutorialGridForCurrentStep();
  }

  // NEW: Track tutorial completion
  void onTutorialCompleted() {
    _achievementService.onTutorialCompleted();
  }

  // FIXED: New method to properly schedule game over checks
  void _scheduleGameOverCheck() {
    // Cancel any existing deferred check
    _deferredGameOverTimer?.cancel();
    
    // If combo is showing, wait for it to finish before checking game over
    final delayMs = _isShowingComboOverlay ? 2600 : 200; // Wait for combo animation
    
    _deferredGameOverTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!_isGameOver && _availablePieces.isNotEmpty) {
        _checkGameOverWithAnimation();
      }
    });
  }

  // FIXED: Enhanced game over check with proper piece validation
  Future<bool> _checkGameOverWithAnimation() async {
    // Skip check if already game over or no pieces available
    if (_isGameOver || _availablePieces.isEmpty) {
      return _isGameOver;
    }

    // FIXED: Don't check during combo animations - but ensure it gets checked later
    if (_isShowingComboOverlay) {
      if (kDebugMode) {
        print('Deferring game over check due to combo animation');
      }
      _scheduleGameOverCheck(); // Reschedule for after combo
      return false;
    }

    // Check if any available piece can be placed anywhere on the grid
    bool hasValidMove = false;
    
    for (final piece in _availablePieces) {
      bool pieceCanBePlaced = false;
      
      // Check every position on the grid for this piece
      for (int y = 0; y < _currentGrid.height && !pieceCanBePlaced; y++) {
        for (int x = 0; x < _currentGrid.width && !pieceCanBePlaced; x++) {
          if (_currentGrid.canPlacePiece(piece, x, y)) {
            pieceCanBePlaced = true;
            hasValidMove = true;
          }
        }
      }
      
      // If we found a valid move for any piece, we can continue playing
      if (hasValidMove) {
        break;
      }
    }
    
    if (!hasValidMove) {
      if (kDebugMode) {
        print('No valid moves found for any of ${_availablePieces.length} pieces');
        // Debug: Print piece information
        for (int i = 0; i < _availablePieces.length; i++) {
          final piece = _availablePieces[i];
          print('Piece $i: ${piece.blocks.length} blocks, color: ${piece.color}');
        }
      }
      
      // Show "No More Moves" animation
      await _showNoMoreMovesAnimation();
      
      // Then set game over state
      _isGameOver = true;
      
      // Check if we should show rewarded ad
      if (!_hasShownFirstDeathReward) {
        _shouldShowRewardedAdOnDeath = true;
        _hasShownFirstDeathReward = true;
        _storageService.saveBool('has_shown_first_death_reward', true);
      }
      
      _audioService.playGameOver();
      notifyListeners();
      return true;
    }
    
    return false;
  }

  // FIXED: Generate new pieces method that ensures pieces are created
  void _generateNewPieces() {
    // Don't generate immediately if combo is showing
    if (_isShowingComboOverlay) {
      // Schedule generation after combo finishes
      Timer(const Duration(milliseconds: 100), () {
        _actuallyGenerateNewPieces();
      });
      return;
    }
    
    _actuallyGenerateNewPieces();
  }
  
  // FIXED: Separate actual generation logic with validation
  void _actuallyGenerateNewPieces() {
    // Clear existing pieces first
    _availablePieces.clear();
    
    // Reset any dragging state
    _selectedPiece = null;
    _draggedPiece = null;
    _isDragging = false;
    _dragPosition = null;
    
    final random = Random();
    
    // FIXED: Get distinct colors for each piece
    final availableColors = List<Color>.from(PieceTemplates.futuristicColors);
    availableColors.shuffle(random); // Shuffle to randomize which colors we pick
    
    // Generate exactly PIECES_COUNT pieces
    for (int i = 0; i < PIECES_COUNT; i++) {
      final shapeIndex = random.nextInt(PieceTemplates.shapes.length);
      final shape = PieceTemplates.shapes[shapeIndex];
      
      // FIXED: Use distinct color for each piece (cycle through if needed)
      final color = availableColors[i % availableColors.length];
      
      final blocks = <BlockPosition>[];
      for (int y = 0; y < shape.length; y++) {
        for (int x = 0; x < shape[y].length; x++) {
          if (shape[y][x] == 1) {
            blocks.add(BlockPosition(x, y));
          }
        }
      }
      
      _availablePieces.add(GamePiece(
        blocks: blocks,
        color: color,
        id: _nextPieceId++,
        name: 'piece_${_nextPieceId}_$i',
        texture: 'solid',
      ));
    }
    
    // Validate that we actually generated pieces
    if (_availablePieces.length != PIECES_COUNT) {
      if (kDebugMode) {
        print('WARNING: Expected $PIECES_COUNT pieces, got ${_availablePieces.length}');
      }
      
      // Fallback: generate simple single-block pieces if something went wrong
      while (_availablePieces.length < PIECES_COUNT) {
        _availablePieces.add(GamePiece(
          blocks: [BlockPosition(0, 0)],
          color: availableColors[_availablePieces.length % availableColors.length],
          id: _nextPieceId++,
          name: 'fallback_piece_${_availablePieces.length}',
          texture: 'solid',
        ));
      }
    }
    
    if (kDebugMode) {
      print('Generated ${_availablePieces.length} new pieces');
    }
    
    // Only notify after pieces are fully generated and validated
    notifyListeners();
  }

  // NEW: End combo immediately (called when no clears happen)
  void _endCombo() {
    if (_hasActiveCombo) {
      if (kDebugMode) {
        print('Combo ended: ${_consecutiveClears} total clears');
      }
      _consecutiveClears = 0;
      _combo = 0;
      _hasActiveCombo = false;
      _comboResetTimer?.cancel();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _comboResetTimer?.cancel();
    _comboDisplayTimer?.cancel();
    _deferredGameOverTimer?.cancel(); // FIXED: Cancel deferred timer
    super.dispose();
  }

  void startTrailerMode(String sceneType) {
    _tutorialService.startTrailerMode();
    resetGame();
    
    // Setup the specific scene
    Future.delayed(const Duration(milliseconds: 100), () {
      _tutorialService.setupTrailerScene(sceneType, _currentGrid, _availablePieces);
      notifyListeners();
    });
  }
  
  void endTrailerMode() {
    _tutorialService.endTrailerMode();
    resetGame();
  }
  
  bool get isTrailerMode => _tutorialService.isTrailerMode;

  void _setupTutorialGridForCurrentStep() {
    if (!_tutorialService.isActive) return;
    
    final currentStep = _tutorialService.currentStep;
    
    // Setup specific grids for steps that need pre-configured boards
    if (currentStep == 3 || currentStep == 4 || currentStep == 5) {
      // Clear existing pieces first
      _availablePieces.clear();
      
      // Setup both grid and pieces for tutorial step
      _tutorialService.setupTutorialStep(currentStep, _currentGrid, _availablePieces);
      
      notifyListeners(); // Update UI to show the new grid state and pieces
    }
  }

  void onTutorialStepChanged() {
    _setupTutorialGridForCurrentStep();
  }

  bool shouldShowInterstitialAd() {
    // Show ad every other game (every 2nd game)
    return _gamesPlayed > 0 && _gamesPlayed % 3 == 0;
  }
  
  void selectPiece(GamePiece piece) {
    if (_isAnimating || _isGameOver) return;
    
    // NEW: Check tutorial constraints
    if (!_tutorialService.canSelectPiece(piece)) return;
    
    _selectedPiece = _selectedPiece?.id == piece.id ? null : piece;
    _audioService.playUIClick();
    
    // NEW: Notify tutorial of piece selection
    if (_selectedPiece != null) {
      _tutorialService.onPieceSelected(_selectedPiece!);
    }
    
    notifyListeners();
  }

  // Global drag functionality - now works across entire screen
  void startDrag(GamePiece piece, Offset globalPosition) {
    if (_isAnimating || _isGameOver) return;
    
    _draggedPiece = piece;
    _selectedPiece = piece;
    
    if (_selectedPiece != null) {
      _tutorialService.onPieceSelected(_selectedPiece!);
    }

    _isDragging = true;
    _dragPosition = globalPosition;
    notifyListeners();
  }
  
  void updateDrag(Offset globalPosition) {
    if (!_isDragging || _draggedPiece == null) return;
    
    _dragPosition = globalPosition;
    notifyListeners();
  }
  
  Future<void> endDrag(Offset globalPosition, RenderBox? gridRenderBox) async {
    if (!_isDragging || _draggedPiece == null) return;
    
    _isDragging = false;
    
    if (gridRenderBox != null) {
      try {
        // Convert global position to grid local position
        final gridLocalPosition = gridRenderBox.globalToLocal(globalPosition);
        final gridSize = gridRenderBox.size;
        
        // Calculate cell size
        final cellSize = gridSize.width / _currentGrid.width;
        
        // Get piece bounds to calculate center offset
        final bounds = _draggedPiece!.getBounds();
        final pieceCenterX = bounds.width / 2;
        final pieceCenterY = bounds.height / 2;
        
        // Calculate where the top-left corner of the piece should be
        // to center the piece on the drag position
        final pieceTopLeftX = gridLocalPosition.dx - (pieceCenterX * cellSize);
        final pieceTopLeftY = gridLocalPosition.dy - (pieceCenterY * cellSize);
        
        // Convert to grid coordinates
        final gridX = (pieceTopLeftX / cellSize).round();
        final gridY = (pieceTopLeftY / cellSize).round();
        
        // Try to place the piece
        if (gridX >= 0 && gridY >= 0) {
          await placePiece(gridX, gridY);
        }
      } catch (e) {
        // Handle any positioning errors gracefully
        print('Drop positioning error: $e');
      }
    }
    
    _draggedPiece = null;
    _dragPosition = null;
    _selectedPiece = null;
    clearPreview();
    notifyListeners();
  }

  // Updated showPreview method to also work with center-based positioning
  void showPreview(int gridX, int gridY) {
    final pieceToPreview = _selectedPiece ?? _draggedPiece;
    if (pieceToPreview == null) return;
    
    // Clear existing previews first
    _clearPreviews();
    
    // Check if we can place the piece at this position
    if (!_currentGrid.canPlacePiece(pieceToPreview, gridX, gridY)) {
      return;
    }
    
    // Add preview blocks
    for (final block in pieceToPreview.blocks) {
      final x = gridX + block.x;
      final y = gridY + block.y;
      
      if (x >= 0 && x < _currentGrid.width && y >= 0 && y < _currentGrid.height) {
        _currentGrid.setCell(x, y, _currentGrid.getCell(x, y).copyWith(
          state: CellState.preview,
          color: pieceToPreview.color.withOpacity(0.5),
        ));
      }
    }
    
    notifyListeners();
  }

  void cancelDrag() {
    _isDragging = false;
    _draggedPiece = null;
    _dragPosition = null;
    _selectedPiece = null;
    clearPreview();
    notifyListeners();
  }
  
  // NEW: Animate line clearing with glow effect
  Future<void> _animateLineClearing(List<int> lines, {required bool isRow}) async {
    // Mark cells as glowing
    _isShowingGlow = true;
    for (final lineIndex in lines) {
      if (isRow) {
        // Mark entire row as glowing
        for (int x = 0; x < _currentGrid.width; x++) {
          _currentGrid.setCell(x, lineIndex, 
            _currentGrid.getCell(x, lineIndex).copyWith(isGlowing: true));
        }
      } else {
        // Mark entire column as glowing
        for (int y = 0; y < _currentGrid.height; y++) {
          _currentGrid.setCell(lineIndex, y, 
            _currentGrid.getCell(lineIndex, y).copyWith(isGlowing: true));
        }
      }
    }
    
    notifyListeners();
    
    // Show glow for a very short time (150ms for better visibility)
    await Future.delayed(const Duration(milliseconds: 150));
    
    _isShowingGlow = false;
    notifyListeners();
  }
  
  // NEW: Animate gravity fall with smooth motion
  Future<void> _animateGravityFall() async {
    // Capture falling blocks before applying gravity
    _captureFallingBlocks();
    
    if (_fallingBlocks.isNotEmpty) {
      _isFallingAnimation = true;
      notifyListeners();
      
      // Show falling animation for a short duration
      await Future.delayed(const Duration(milliseconds: 300));
      
      _isFallingAnimation = false;
      _fallingBlocks.clear();
    }
    
    // Actually apply gravity to the grid
    _currentGrid.applyGravity();
    _audioService.playGravityFall();
    notifyListeners();
  }
  
  // NEW: Capture blocks that will fall for animation
  void _captureFallingBlocks() {
    _fallingBlocks.clear();
    
    // For each column, identify blocks that will fall
    for (int x = 0; x < _currentGrid.width; x++) {
      final columnBlocks = <GridCell>[];
      
      // Collect filled cells from bottom to top
      for (int y = _currentGrid.height - 1; y >= 0; y--) {
        final cell = _currentGrid.getCell(x, y);
        if (cell.state == CellState.filled) {
          // Check if this block will fall (has empty space below)
          bool willFall = false;
          for (int checkY = y + 1; checkY < _currentGrid.height; checkY++) {
            if (_currentGrid.getCell(x, checkY).state == CellState.empty) {
              willFall = true;
              break;
            }
          }
          
          if (willFall) {
            columnBlocks.add(cell.copyWith(state: CellState.falling));
          }
        }
      }
      
      if (columnBlocks.isNotEmpty) {
        _fallingBlocks.add(columnBlocks);
      }
    }
  }
  
  // NEW: Show "No More Moves" animation
  Future<void> _showNoMoreMovesAnimation() async {
    _isShowingGameOverAnimation = true;
    notifyListeners();
    
    // Highlight all pieces to show they can't be placed
    final originalPieces = List<GamePiece>.from(_availablePieces);
    
    // Show pulsing animation for pieces that can't be placed
    for (int i = 0; i < 3; i++) {
      // Flash all pieces red
      for (final piece in _availablePieces) {
        // This will be handled in the UI to show red highlighting
      }
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Reset highlighting
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    _isShowingGameOverAnimation = false;
    notifyListeners();
  }
  
  // FIXED: Simple game over check for internal use (no animation)
  bool _checkGameOverSimple() {
    if (_availablePieces.isEmpty) return true;
    
    // Game over if no available piece can be placed anywhere on the grid
    for (final piece in _availablePieces) {
      for (int y = 0; y < _currentGrid.height; y++) {
        for (int x = 0; x < _currentGrid.width; x++) {
          if (_currentGrid.canPlacePiece(piece, x, y)) {
            return false; // Found a valid placement
          }
        }
      }
    }
    return true; // No valid placements found
  }
  
  // Clear random blocks to create space with glow animation
  Future<void> _clearRandomBlocksWithAnimation() async {
    final random = Random();
    int blocksCleared = 0;
    final targetClears = 6 + random.nextInt(5); // Clear 6-10 blocks
    
    final blocksToGlow = <GridCell>[];
    
    // Try to clear blocks randomly, preferring edges and corners
    for (int attempts = 0; attempts < 50 && blocksCleared < targetClears; attempts++) {
      final x = random.nextInt(_currentGrid.width);
      final y = random.nextInt(_currentGrid.height);
      
      if (_currentGrid.getCell(x, y).state == CellState.filled) {
        final cellToGlow = _currentGrid.getCell(x, y).copyWith(isGlowing: true);
        _currentGrid.setCell(x, y, cellToGlow);
        blocksToGlow.add(cellToGlow);
        blocksCleared++;
      }
    }
    
    if (blocksToGlow.isNotEmpty) {
      // Show glow animation
      _isShowingGlow = true;
      notifyListeners();
      
      // Play a special reward clear sound
      _audioService.playLineClear();
      
      // Wait for glow animation
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Clear the glowing blocks
      for (final block in blocksToGlow) {
        _currentGrid.setCell(block.x, block.y, GridCell(x: block.x, y: block.y));
      }
      
      _isShowingGlow = false;
      notifyListeners();
      
      // Apply gravity with animation
      await _animateGravityFall();
    }
  }
  
  // Clear more blocks if still stuck with animation
  Future<void> _clearMoreBlocksWithAnimation() async {
    final blocksToGlow = <GridCell>[];
    
    // Clear entire rows/columns that are mostly full
    for (int y = 0; y < _currentGrid.height; y++) {
      int filledCount = 0;
      for (int x = 0; x < _currentGrid.width; x++) {
        if (_currentGrid.getCell(x, y).state == CellState.filled) {
          filledCount++;
        }
      }
      // If row is 70% or more filled, clear some blocks from it
      if (filledCount >= (_currentGrid.width * 0.7)) {
        for (int x = 0; x < _currentGrid.width; x += 2) {
          final cell = _currentGrid.getCell(x, y);
          if (cell.state == CellState.filled) {
            final cellToGlow = cell.copyWith(isGlowing: true);
            _currentGrid.setCell(x, y, cellToGlow);
            blocksToGlow.add(cellToGlow);
          }
        }
      }
    }
    
    if (blocksToGlow.isNotEmpty) {
      // Show glow animation
      _isShowingGlow = true;
      notifyListeners();
      
      // Play a special reward clear sound
      _audioService.playLineClear();
      
      // Wait for glow animation
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Clear the glowing blocks
      for (final block in blocksToGlow) {
        _currentGrid.setCell(block.x, block.y, GridCell(x: block.x, y: block.y));
      }
      
      _isShowingGlow = false;
      notifyListeners();
      
      // Apply gravity with animation
      await _animateGravityFall();
    }
  }
  
  // Generate pieces that are guaranteed to fit
  void _generatePlaceablePieces() {
    _availablePieces.clear();
    
    // FIXED: Get distinct colors for reward pieces
    final availableColors = List<Color>.from(PieceTemplates.futuristicColors);
    final random = Random();
    availableColors.shuffle(random);
    
    // Find available spaces and generate pieces that fit
    final spaces = _findAvailableSpaces();
    
    if (spaces.isNotEmpty) {
      // Generate pieces that can fit in available spaces
      for (int i = 0; i < PIECES_COUNT; i++) {
        final piece = _generatePieceForSpace(spaces, availableColors[i % availableColors.length]);
        if (piece != null) {
          _availablePieces.add(piece);
        }
      }
    }
    
    // If we still don't have enough pieces, add simple ones
    int colorIndex = _availablePieces.length;
    while (_availablePieces.length < PIECES_COUNT) {
      _availablePieces.add(_generateSimplePiece(availableColors[colorIndex % availableColors.length]));
      colorIndex++;
    }
    
    notifyListeners(); // Ensure UI updates
  }

  void _generateSimplePieces() {
    _availablePieces.clear();
    
    // FIXED: Get distinct colors for simple pieces
    final availableColors = List<Color>.from(PieceTemplates.futuristicColors);
    final random = Random();
    availableColors.shuffle(random);
    
    for (int i = 0; i < PIECES_COUNT; i++) {
      _availablePieces.add(_generateSimplePiece(availableColors[i % availableColors.length]));
    }
    
    notifyListeners(); // Ensure UI updates
  }
  
  GamePiece _generateSimplePiece([Color? color]) {
    return GamePiece(
      blocks: [BlockPosition(0, 0)], // Single block
      color: color ?? PieceTemplates.getRandomColor(),
      id: _nextPieceId++,
      name: 'simple_piece',
      texture: 'solid',
    );
  }

  // Find all available spaces on the grid
  List<Rect> _findAvailableSpaces() {
    final spaces = <Rect>[];
    
    // Look for rectangular areas of empty space
    for (int y = 0; y < _currentGrid.height; y++) {
      for (int x = 0; x < _currentGrid.width; x++) {
        if (_currentGrid.getCell(x, y).state == CellState.empty) {
          // Find the largest rectangle starting from this point
          final rect = _findLargestRectangle(x, y);
          if (rect.width >= 1 && rect.height >= 1) {
            spaces.add(rect);
          }
        }
      }
    }
    
    return spaces;
  }
  
  // Find largest rectangle of empty space from a starting point
  Rect _findLargestRectangle(int startX, int startY) {
    int maxWidth = 0;
    int maxHeight = 0;
    
    // Find max width from this point
    for (int x = startX; x < _currentGrid.width; x++) {
      if (_currentGrid.getCell(x, startY).state == CellState.empty) {
        maxWidth++;
      } else {
        break;
      }
    }
    
    // Find max height from this point
    for (int y = startY; y < _currentGrid.height; y++) {
      if (_currentGrid.getCell(startX, y).state == CellState.empty) {
        maxHeight++;
      } else {
        break;
      }
    }
    
    return Rect.fromLTWH(startX.toDouble(), startY.toDouble(), maxWidth.toDouble(), maxHeight.toDouble());
  }
  
  // Generate a piece that fits in available spaces
  GamePiece? _generatePieceForSpace(List<Rect> spaces, [Color? color]) {
    if (spaces.isEmpty) return null;
    
    final random = Random();
    final space = spaces[random.nextInt(spaces.length)];
    
    // Choose a shape that fits in this space
    final availableShapes = PieceTemplates.shapes.where((shape) {
      final height = shape.length;
      final width = shape.isNotEmpty ? shape.first.length : 0;
      return width <= space.width && height <= space.height;
    }).toList();
    
    if (availableShapes.isEmpty) {
      // Fallback to single block
      return _generateSimplePiece(color);
    }
    
    final shape = availableShapes[random.nextInt(availableShapes.length)];
    final blocks = <BlockPosition>[];
    
    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == 1) {
          blocks.add(BlockPosition(x, y));
        }
      }
    }
    
    return GamePiece(
      blocks: blocks,
      color: color ?? PieceTemplates.getRandomColor(),
      id: _nextPieceId++,
      name: 'reward_piece',
      texture: 'solid',
    );
  }

  void onRewardedAdDeclined() {
    _shouldShowRewardedAdOnDeath = false;
    notifyListeners();
  }
  
  Future<void> loadProgress() async {
    _score = await _storageService.getInt('score') ?? 0;
    _highScore = await _storageService.getInt('high_score') ?? 0;
    _level = await _storageService.getInt('level') ?? 1;
    _linesCleared = await _storageService.getInt('lines_cleared') ?? 0;
    _gamesPlayed = await _storageService.getInt('games_played') ?? 0;
    _hasShownFirstDeathReward = await _storageService.getBool('has_shown_first_death_reward') ?? false;
    
    // NEW: Load game state for Continue functionality
    await loadGameState();
    
    notifyListeners();
  }

  void _resetPieceState() {
    _selectedPiece = null;
    _draggedPiece = null;
    _isDragging = false;
    _dragPosition = null;
    _availablePieces.clear(); // Clear before generating new ones
    notifyListeners(); // Notify before generating to clear UI
  }

  void _clearPreviews() {
    for (int y = 0; y < _currentGrid.height; y++) {
      for (int x = 0; x < _currentGrid.width; x++) {
        final cell = _currentGrid.getCell(x, y);
        if (cell.state == CellState.preview) {
          _currentGrid.setCell(x, y, cell.copyWith(
            state: CellState.empty,
            color: Colors.transparent,
          ));
        }
      }
    }
  }
  
  void clearPreview() {
    _clearPreviews();
    notifyListeners();
  }
  
  // Get combo display text
  String getComboText() {
    if (_combo <= 1) return '';
    
    String baseText = 'COMBO x$_combo!';
    
    // Add cascade info if it was a multi-cycle clear
    if (_lastCascadeCycles > 1) {
      baseText += '\n${_lastCascadeClears} LINES in ${_lastCascadeCycles} CASCADES!';
    }
    
    return baseText;
  }
  
  // Get level progress (0.0 to 1.0)
  double getLevelProgress() {
    final currentLevelScore = _score % 5000;
    return currentLevelScore / 5000.0;
  }
  
  // Get points needed for next level
  int getPointsToNextLevel() {
    final currentLevelScore = _score % 5000;
    return 5000 - currentLevelScore;
  }
}