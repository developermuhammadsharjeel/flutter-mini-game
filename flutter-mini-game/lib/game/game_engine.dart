// lib/game/game_engine.dart
// Core game logic for Block Blast - Enhanced version

import 'dart:math';
import 'piece_shapes.dart';

/// Main game engine handling all game logic
class GameEngine {
  static const int BOARD_SIZE = 8; // Changed from 9 to 8 as per requirements
  static const int PIECES_PER_SET = 3;
  static const int MAX_RETRY_ATTEMPTS = 10;

  // Game state
  List<List<int>> board; // 0 = empty, >0 = filled with color index
  int score = 0;
  int bestScore = 0;
  final Random _rng = Random();
  
  // Current piece set and history
  List<List<Cell>> currentSet = [];
  List<List<Cell>> lastSet = [];
  
  // Game statistics
  int totalLinesCleared = 0;
  int totalPiecesPlaced = 0;
  int currentCombo = 0;

  /// Initialize game engine
  GameEngine() : board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, 0)) {
    generateNewSet();
  }

  /// Generate a new set of 3 pieces ensuring no exact repeat of previous set
  void generateNewSet() {
    final library = List<List<Cell>>.from(PIECE_LIBRARY);
    List<List<Cell>> newSet = [];
    
    // Choose 3 pieces without replacement within this set
    for (int i = 0; i < PIECES_PER_SET && library.isNotEmpty; i++) {
      int idx = _rng.nextInt(library.length);
      newSet.add(normalizeShape(library.removeAt(idx)));
    }
    
    // Prevent exact same triple as lastSet (order-insensitive)
    int retries = 0;
    while (_sameSet(newSet, lastSet) && retries < MAX_RETRY_ATTEMPTS) {
      library.clear();
      library.addAll(PIECE_LIBRARY);
      newSet.clear();
      
      for (int i = 0; i < PIECES_PER_SET && library.isNotEmpty; i++) {
        int idx = _rng.nextInt(library.length);
        newSet.add(normalizeShape(library.removeAt(idx)));
      }
      retries++;
    }
    
    lastSet = List.from(currentSet);
    currentSet = newSet;
  }

  /// Compare two sets for equality (order-insensitive)
  bool _sameSet(List<List<Cell>> setA, List<List<Cell>> setB) {
    if (setA.length != setB.length) return false;
    if (setA.isEmpty) return false;
    
    final keysA = setA.map(_shapeKey).toList()..sort();
    final keysB = setB.map(_shapeKey).toList()..sort();
    
    for (int i = 0; i < keysA.length; i++) {
      if (keysA[i] != keysB[i]) return false;
    }
    return true;
  }

  /// Generate a unique key for a shape based on its cell coordinates
  String _shapeKey(List<Cell> shape) {
    final normalized = normalizeShape(shape);
    final coords = normalized.map((cell) => '${cell[0]},${cell[1]}').toList()..sort();
    return coords.join('|');
  }

  /// Check if a piece can be placed at the given position
  bool canPlacePieceAt(List<Cell> piece, int row, int col) {
    for (final cell in piece) {
      final r = row + cell[0];
      final c = col + cell[1];
      
      // Check bounds
      if (r < 0 || r >= BOARD_SIZE || c < 0 || c >= BOARD_SIZE) {
        return false;
      }
      
      // Check if cell is already occupied
      if (board[r][c] != 0) {
        return false;
      }
    }
    return true;
  }

  /// Place a piece on the board and handle scoring
  bool placePieceAt(List<Cell> piece, int row, int col, {int colorValue = 1}) {
    if (!canPlacePieceAt(piece, row, col)) return false;
    
    // Place the piece
    for (final cell in piece) {
      board[row + cell[0]][col + cell[1]] = colorValue;
    }
    
    totalPiecesPlaced++;
    
    // Clear completed lines and calculate score
    final clearedInfo = clearLines();
    final clearedCount = clearedInfo['total'] ?? 0;
    
    if (clearedCount > 0) {
      totalLinesCleared += clearedCount;
      currentCombo = clearedCount;
      score += _calculateScore(piece.length, clearedInfo);
    } else {
      currentCombo = 0;
      // Small bonus for placing piece
      score += piece.length * 5;
    }
    
    return true;
  }

  /// Clear completed rows and columns
  Map<String, int> clearLines() {
    final Set<int> rowsToClear = {};
    final Set<int> colsToClear = {};
    
    // Check for complete rows
    for (int r = 0; r < BOARD_SIZE; r++) {
      bool isComplete = true;
      for (int c = 0; c < BOARD_SIZE; c++) {
        if (board[r][c] == 0) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        rowsToClear.add(r);
      }
    }
    
    // Check for complete columns
    for (int c = 0; c < BOARD_SIZE; c++) {
      bool isComplete = true;
      for (int r = 0; r < BOARD_SIZE; r++) {
        if (board[r][c] == 0) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        colsToClear.add(c);
      }
    }
    
    // Clear the completed lines
    for (final r in rowsToClear) {
      for (int c = 0; c < BOARD_SIZE; c++) {
        board[r][c] = 0;
      }
    }
    
    for (final c in colsToClear) {
      for (int r = 0; r < BOARD_SIZE; r++) {
        board[r][c] = 0;
      }
    }
    
    return {
      'rows': rowsToClear.length,
      'cols': colsToClear.length,
      'total': rowsToClear.length + colsToClear.length,
      'cellsCleared': (rowsToClear.length * BOARD_SIZE) + (colsToClear.length * BOARD_SIZE),
    };
  }

  /// Calculate score based on pieces placed and lines cleared
  int _calculateScore(int pieceCellCount, Map<String, int> clearedInfo) {
    final int cellsCleared = clearedInfo['cellsCleared'] ?? 0;
    final int linesCleared = clearedInfo['total'] ?? 0;
    
    // Base points for placing piece
    int basePoints = pieceCellCount * 5;
    
    // Points for cleared cells
    int clearPoints = cellsCleared * 10;
    
    // Combo multiplier (1x for 1 line, 2x for 2 lines, 3x for 3+)
    int comboMultiplier = linesCleared > 0 ? linesCleared : 1;
    
    return (basePoints + clearPoints) * comboMultiplier;
  }

  /// Check if any move is available for current set
  bool anyMoveAvailableForCurrentSet() {
    for (final piece in currentSet) {
      for (int r = 0; r < BOARD_SIZE; r++) {
        for (int c = 0; c < BOARD_SIZE; c++) {
          if (canPlacePieceAt(piece, r, c)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Check if game is over
  bool isGameOver() {
    return !anyMoveAvailableForCurrentSet();
  }

  /// Remove a piece from current set (after successful placement)
  void removePieceFromSet(int index) {
    if (index >= 0 && index < currentSet.length) {
      currentSet.removeAt(index);
    }
    
    // Generate new set when all pieces are used
    if (currentSet.isEmpty) {
      generateNewSet();
    }
  }

  /// Reset the game to initial state
  void resetGame() {
    board = List.generate(BOARD_SIZE, (_) => List.filled(BOARD_SIZE, 0));
    score = 0;
    currentSet.clear();
    lastSet.clear();
    totalLinesCleared = 0;
    totalPiecesPlaced = 0;
    currentCombo = 0;
    generateNewSet();
  }

  /// Update best score if current score is higher
  void updateBestScore() {
    if (score > bestScore) {
      bestScore = score;
    }
  }

  /// Get hint for best possible move (basic implementation)
  Map<String, dynamic>? getHint() {
    int bestScore = -1;
    Map<String, dynamic>? bestMove;
    
    for (int pieceIndex = 0; pieceIndex < currentSet.length; pieceIndex++) {
      final piece = currentSet[pieceIndex];
      for (int r = 0; r < BOARD_SIZE; r++) {
        for (int c = 0; c < BOARD_SIZE; c++) {
          if (canPlacePieceAt(piece, r, c)) {
            // Calculate potential score for this move
            int moveScore = piece.length * 5;
            
            // Create temporary board to test line clears
            final tempBoard = board.map((row) => List<int>.from(row)).toList();
            
            // Simulate placement
            for (final cell in piece) {
              tempBoard[r + cell[0]][c + cell[1]] = 1;
            }
            
            // Check how many lines would be cleared
            int linesCleared = 0;
            // Check rows
            for (int row = 0; row < BOARD_SIZE; row++) {
              if (tempBoard[row].every((cell) => cell != 0)) {
                linesCleared++;
              }
            }
            // Check columns
            for (int col = 0; col < BOARD_SIZE; col++) {
              if (tempBoard.every((row) => row[col] != 0)) {
                linesCleared++;
              }
            }
            
            moveScore += linesCleared * 50; // Bonus for line clears
            
            if (moveScore > bestScore) {
              bestScore = moveScore;
              bestMove = {
                'pieceIndex': pieceIndex,
                'row': r,
                'col': c,
                'score': moveScore,
              };
            }
          }
        }
      }
    }
    
    return bestMove;
  }

  /// Get game statistics
  Map<String, dynamic> getGameStats() {
    return {
      'score': score,
      'bestScore': bestScore,
      'totalLinesCleared': totalLinesCleared,
      'totalPiecesPlaced': totalPiecesPlaced,
      'currentCombo': currentCombo,
      'piecesInSet': currentSet.length,
    };
  }
}