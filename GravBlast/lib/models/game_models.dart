import 'package:flutter/material.dart';

enum CellState {
  empty,
  filled,
  preview, // For showing where piece will be placed
  falling, // For gravity animation
}

class GridCell {
  final int x;
  final int y;
  final CellState state;
  final Color color;
  final bool isGlowing; // For line clear animations
  final int pieceId; // Which piece this cell belongs to
  final String texture; // Texture identifier for visual variety
  
  const GridCell({
    required this.x,
    required this.y,
    this.state = CellState.empty,
    this.color = Colors.transparent,
    this.isGlowing = false,
    this.pieceId = 0,
    this.texture = 'solid',
  });
  
  GridCell copyWith({
    int? x,
    int? y,
    CellState? state,
    Color? color,
    bool? isGlowing,
    int? pieceId,
    String? texture,
  }) {
    return GridCell(
      x: x ?? this.x,
      y: y ?? this.y,
      state: state ?? this.state,
      color: color ?? this.color,
      isGlowing: isGlowing ?? this.isGlowing,
      pieceId: pieceId ?? this.pieceId,
      texture: texture ?? this.texture,
    );
  }
}

class GameGrid {
  final List<List<GridCell>> cells;
  final int width;
  final int height;
  
  const GameGrid({
    required this.cells,
    required this.width,
    required this.height,
  });
  
  GameGrid.empty(int width, int height) : this(
    cells: List.generate(height, (y) => 
      List.generate(width, (x) => 
        GridCell(x: x, y: y))),
    width: width,
    height: height,
  );
  
  GridCell getCell(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return GridCell(x: x, y: y);
    }
    return cells[y][x];
  }
  
  void setCell(int x, int y, GridCell cell) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      cells[y][x] = cell;
    }
  }
  
  bool canPlacePiece(GamePiece piece, int startX, int startY) {
    for (final block in piece.blocks) {
      final x = startX + block.x;
      final y = startY + block.y;
      
      if (x < 0 || x >= width || y < 0 || y >= height) {
        return false;
      }
      
      if (cells[y][x].state == CellState.filled) {
        return false;
      }
    }
    return true;
  }
  
  void placePiece(GamePiece piece, int startX, int startY) {
    for (final block in piece.blocks) {
      final x = startX + block.x;
      final y = startY + block.y;
      
      if (x >= 0 && x < width && y >= 0 && y < height) {
        cells[y][x] = cells[y][x].copyWith(
          state: CellState.filled,
          color: piece.color,
          pieceId: piece.id,
          texture: piece.texture,
        );
      }
    }
  }
  
  List<int> getCompletedRows() {
    final completedRows = <int>[];
    for (int y = 0; y < height; y++) {
      bool isComplete = true;
      for (int x = 0; x < width; x++) {
        if (cells[y][x].state != CellState.filled) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completedRows.add(y);
      }
    }
    return completedRows;
  }
  
  List<int> getCompletedColumns() {
    final completedColumns = <int>[];
    for (int x = 0; x < width; x++) {
      bool isComplete = true;
      for (int y = 0; y < height; y++) {
        if (cells[y][x].state != CellState.filled) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        completedColumns.add(x);
      }
    }
    return completedColumns;
  }
  
  // Find connected groups of the same piece
  List<List<GridCell>> getConnectedGroups(int pieceId) {
    final visited = List.generate(height, (_) => List.filled(width, false));
    final groups = <List<GridCell>>[];
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (!visited[y][x] && cells[y][x].state == CellState.filled && cells[y][x].pieceId == pieceId) {
          final group = <GridCell>[];
          _floodFill(x, y, pieceId, visited, group);
          if (group.isNotEmpty) {
            groups.add(group);
          }
        }
      }
    }
    
    return groups;
  }
  
  void _floodFill(int x, int y, int pieceId, List<List<bool>> visited, List<GridCell> group) {
    if (x < 0 || x >= width || y < 0 || y >= height || visited[y][x]) return;
    if (cells[y][x].state != CellState.filled || cells[y][x].pieceId != pieceId) return;
    
    visited[y][x] = true;
    group.add(cells[y][x]);
    
    // Check 4-directional connectivity
    _floodFill(x + 1, y, pieceId, visited, group);
    _floodFill(x - 1, y, pieceId, visited, group);
    _floodFill(x, y + 1, pieceId, visited, group);
    _floodFill(x, y - 1, pieceId, visited, group);
  }
  
  void clearRows(List<int> rows) {
    for (final row in rows) {
      for (int x = 0; x < width; x++) {
        cells[row][x] = GridCell(x: x, y: row);
      }
    }
  }
  
  void clearColumns(List<int> columns) {
    for (final col in columns) {
      for (int y = 0; y < height; y++) {
        cells[y][col] = GridCell(x: col, y: y);
      }
    }
  }
  
  // Apply gravity - return true if any blocks moved
  bool applyGravity() {
    bool blocksMoved = false;
    
    // Process each column from bottom to top
    for (int x = 0; x < width; x++) {
      final filledCells = <GridCell>[];
      
      // Collect all filled cells in this column
      for (int y = height - 1; y >= 0; y--) {
        if (cells[y][x].state == CellState.filled) {
          filledCells.add(cells[y][x]);
          cells[y][x] = GridCell(x: x, y: y); // Clear original position
        }
      }
      
      // Place them at the bottom
      for (int i = 0; i < filledCells.length; i++) {
        final newY = height - 1 - i;
        final cell = filledCells[i];
        if (cell.y != newY) {
          blocksMoved = true;
        }
        cells[newY][x] = cell.copyWith(x: x, y: newY);
      }
    }
    
    return blocksMoved;
  }
  
  bool isEmpty() {
    for (final row in cells) {
      for (final cell in row) {
        if (cell.state == CellState.filled) {
          return false;
        }
      }
    }
    return true;
  }
  
  double getFilledPercentage() {
    int filledCells = 0;
    int totalCells = width * height;
    
    for (final row in cells) {
      for (final cell in row) {
        if (cell.state == CellState.filled) {
          filledCells++;
        }
      }
    }
    
    return filledCells / totalCells;
  }
}

class BlockPosition {
  final int x;
  final int y;
  
  const BlockPosition(this.x, this.y);
  
  BlockPosition operator +(BlockPosition other) {
    return BlockPosition(x + other.x, y + other.y);
  }
}

class GamePiece {
  final List<BlockPosition> blocks;
  final Color color;
  final int id;
  final String name;
  final String texture;
  
  const GamePiece({
    required this.blocks,
    required this.color,
    required this.id,
    required this.name,
    this.texture = 'solid',
  });
  
  GamePiece copyWith({
    List<BlockPosition>? blocks,
    Color? color,
    int? id,
    String? name,
    String? texture,
  }) {
    return GamePiece(
      blocks: blocks ?? this.blocks,
      color: color ?? this.color,
      id: id ?? this.id,
      name: name ?? this.name,
      texture: texture ?? this.texture,
    );
  }
  
  // Get bounding box of the piece
  Rect getBounds() {
    if (blocks.isEmpty) return Rect.zero;
    
    int minX = blocks.first.x;
    int maxX = blocks.first.x;
    int minY = blocks.first.y;
    int maxY = blocks.first.y;
    
    for (final block in blocks) {
      minX = minX < block.x ? minX : block.x;
      maxX = maxX > block.x ? maxX : block.x;
      minY = minY < block.y ? minY : block.y;
      maxY = maxY > block.y ? maxY : block.y;
    }
    
    return Rect.fromLTRB(
      minX.toDouble(), 
      minY.toDouble(), 
      (maxX + 1).toDouble(), 
      (maxY + 1).toDouble()
    );
  }
  
  int get blockCount => blocks.length;
}

class GameState {
  final GameGrid currentGrid;
  final List<GamePiece> availablePieces;
  final GamePiece? selectedPiece;
  final int score;
  final int highScore;
  final int level;
  final int linesCleared;
  final int combo;
  final bool isGameOver;
  final bool isAnimating;
  
  const GameState({
    required this.currentGrid,
    this.availablePieces = const [],
    this.selectedPiece,
    this.score = 0,
    this.highScore = 0,
    this.level = 1,
    this.linesCleared = 0,
    this.combo = 0,
    this.isGameOver = false,
    this.isAnimating = false,
  });
  
  GameState copyWith({
    GameGrid? currentGrid,
    List<GamePiece>? availablePieces,
    GamePiece? selectedPiece,
    int? score,
    int? highScore,
    int? level,
    int? linesCleared,
    int? combo,
    bool? isGameOver,
    bool? isAnimating,
  }) {
    return GameState(
      currentGrid: currentGrid ?? this.currentGrid,
      availablePieces: availablePieces ?? this.availablePieces,
      selectedPiece: selectedPiece,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
      level: level ?? this.level,
      linesCleared: linesCleared ?? this.linesCleared,
      combo: combo ?? this.combo,
      isGameOver: isGameOver ?? this.isGameOver,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

class ScoreEvent {
  final int points;
  final String type;
  final DateTime timestamp;
  final int multiplier;
  
  const ScoreEvent({
    required this.points,
    required this.type,
    required this.timestamp,
    this.multiplier = 1,
  });
}

// Pre-defined piece shapes with better variety
class PieceTemplates {
  static const List<List<List<int>>> shapes = [
    // Single block
    [[1]],
    
    // Line pieces
    [[1, 1]],
    [[1, 1, 1]],
    [[1, 1, 1, 1]],
    [[1], [1]],
    [[1], [1], [1]],
    [[1], [1], [1], [1]],
    
    // L-shapes
    [[1, 0], [1, 1]],
    [[1, 1], [1, 0]],
    [[1], [1], [1, 1]],
    [[1, 1], [0, 1], [0, 1]],
    
    // Squares
    [[1, 1], [1, 1]],
    [[1, 1, 1], [1, 1, 1], [1, 1, 1]],
    
    // T-shapes
    [[1, 1, 1], [0, 1, 0]],
    [[1, 0], [1, 1], [1, 0]],
    [[0, 1, 0], [1, 1, 1]],
    [[0, 1], [1, 1], [0, 1]],
    
    // Z-shapes
    [[1, 1, 0], [0, 1, 1]],
    [[0, 1], [1, 1], [1, 0]],
    [[0, 1, 1], [1, 1, 0]],
    [[1, 0], [1, 1], [0, 1]],
    
    // Plus shape
    [[0, 1, 0], [1, 1, 1], [0, 1, 0]],
    
    // Corner shapes
    [[1, 0, 0], [1, 0, 0], [1, 1, 1]],
    [[0, 0, 1], [0, 0, 1], [1, 1, 1]],
    [[1, 1, 1], [1, 0, 0], [1, 0, 0]],
    [[1, 1, 1], [0, 0, 1], [0, 0, 1]],

    // Diagonal line
    [[1, 0, 0], [0, 1, 0], [0, 0, 1]],
    
    // Anti-diagonal line
    [[0, 0, 1], [0, 1, 0], [1, 0, 0]],
    
    // C-shape
    [[1, 1, 1], [1, 0, 0], [1, 1, 1]],
    
    // U-shape
    [[1, 0, 1], [1, 0, 1], [1, 1, 1]],

    // New 2x3 shapes
    [[1, 0, 1], [1, 1, 1]],
    [[1, 1, 0], [1, 0, 1]],
    [[1, 0, 1], [0, 1, 1]],

    // New 3x3 shapes
    [[1, 1, 0], [1, 0, 1], [0, 1, 1]],
    [[0, 1, 1], [1, 0, 1], [1, 1, 0]],
    [[1, 0, 1], [0, 1, 0], [1, 0, 1]],
  ];
  
  static List<String> get textures => [
    'solid',
    'gradient',
    'metallic',
    'neon',
    'crystal',
    'plasma',
  ];
  
  static List<Color> get futuristicColors => [
    const Color(0xFF00D4FF), // Cyan
    const Color(0xFFFF0080), // Hot Pink
    const Color(0xFF00FF41), // Neon Green
    const Color(0xFFFFD700), // Gold
    const Color(0xFF9D00FF), // Purple
    const Color(0xFFFF4500), // Orange Red
    const Color(0xFF1E90FF), // Dodger Blue
    const Color(0xFFFF1493), // Deep Pink
    const Color(0xFF00FF7F), // Spring Green
    const Color(0xFFFF6347), // Tomato
    const Color(0xFF8A2BE2), // Blue Violet
    const Color(0xFF32CD32), // Lime Green
  ];
  
  static Color getRandomColor() {
    final colors = futuristicColors;
    return colors[DateTime.now().millisecondsSinceEpoch % colors.length];
  }
  
  static String getRandomTexture() {
    final textureList = textures;
    return textureList[DateTime.now().microsecondsSinceEpoch % textureList.length];
  }
}