// lib/game/ai_helper.dart
// AI helper for providing hints and game analysis

import 'dart:math';
import 'game_engine.dart';
import 'piece_shapes.dart';

/// AI helper class for providing hints and game analysis
class AIHelper {
  static const int BOARD_SIZE = GameEngine.BOARD_SIZE;

  /// Analyze the board and find the best move for the current pieces
  static Map<String, dynamic>? findBestMove(GameEngine engine) {
    if (engine.currentSet.isEmpty) return null;

    Move? bestMove;
    int bestScore = -1;

    for (int pieceIndex = 0; pieceIndex < engine.currentSet.length; pieceIndex++) {
      final piece = engine.currentSet[pieceIndex];
      
      for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
          if (engine.canPlacePieceAt(piece, row, col)) {
            final moveScore = _evaluateMove(engine.board, piece, row, col);
            
            if (moveScore > bestScore) {
              bestScore = moveScore;
              bestMove = Move(
                pieceIndex: pieceIndex,
                row: row,
                col: col,
                score: moveScore,
                piece: piece,
              );
            }
          }
        }
      }
    }

    if (bestMove == null) return null;

    return {
      'pieceIndex': bestMove.pieceIndex,
      'row': bestMove.row,
      'col': bestMove.col,
      'score': bestMove.score,
      'confidence': _calculateConfidence(bestScore),
    };
  }

  /// Evaluate the score potential of a move
  static int _evaluateMove(List<List<int>> board, List<Cell> piece, int row, int col) {
    // Create a copy of the board to simulate the move
    final tempBoard = board.map((r) => List<int>.from(r)).toList();
    
    // Place the piece
    for (final cell in piece) {
      tempBoard[row + cell[0]][col + cell[1]] = 1;
    }

    int score = 0;

    // Base score for piece placement
    score += piece.length * 5;

    // Score for line clears
    final clearedLines = _countLineClears(tempBoard);
    score += clearedLines['total']! * 100;
    
    // Bonus for multiple line clears (combos)
    if (clearedLines['total']! > 1) {
      score += clearedLines['total']! * 50; // Combo bonus
    }

    // Penalty for creating holes or isolated cells
    score -= _countIsolatedCells(tempBoard) * 10;

    // Bonus for creating opportunities (near-complete lines)
    score += _countNearCompleteLines(tempBoard) * 25;

    // Bonus for keeping the board compact
    score += _evaluateCompactness(tempBoard) * 5;

    return score;
  }

  /// Count how many lines would be cleared from the current board state
  static Map<String, int> _countLineClears(List<List<int>> board) {
    int rowsCleared = 0;
    int colsCleared = 0;

    // Check rows
    for (int r = 0; r < BOARD_SIZE; r++) {
      if (board[r].every((cell) => cell != 0)) {
        rowsCleared++;
      }
    }

    // Check columns
    for (int c = 0; c < BOARD_SIZE; c++) {
      if (board.every((row) => row[c] != 0)) {
        colsCleared++;
      }
    }

    return {
      'rows': rowsCleared,
      'cols': colsCleared,
      'total': rowsCleared + colsCleared,
    };
  }

  /// Count isolated empty cells (empty cells surrounded by filled cells)
  static int _countIsolatedCells(List<List<int>> board) {
    int isolatedCells = 0;

    for (int r = 1; r < BOARD_SIZE - 1; r++) {
      for (int c = 1; c < BOARD_SIZE - 1; c++) {
        if (board[r][c] == 0) {
          // Check if surrounded by non-empty cells
          bool isolated = true;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue; // Skip center cell
              if (board[r + dr][c + dc] == 0) {
                isolated = false;
                break;
              }
            }
            if (!isolated) break;
          }
          if (isolated) isolatedCells++;
        }
      }
    }

    return isolatedCells;
  }

  /// Count lines that are almost complete (missing 1-2 cells)
  static int _countNearCompleteLines(List<List<int>> board) {
    int nearCompleteLines = 0;

    // Check rows
    for (int r = 0; r < BOARD_SIZE; r++) {
      int emptyCells = board[r].where((cell) => cell == 0).length;
      if (emptyCells >= 1 && emptyCells <= 2) {
        nearCompleteLines++;
      }
    }

    // Check columns
    for (int c = 0; c < BOARD_SIZE; c++) {
      int emptyCells = 0;
      for (int r = 0; r < BOARD_SIZE; r++) {
        if (board[r][c] == 0) emptyCells++;
      }
      if (emptyCells >= 1 && emptyCells <= 2) {
        nearCompleteLines++;
      }
    }

    return nearCompleteLines;
  }

  /// Evaluate how compact the board layout is (filled cells close together)
  static int _evaluateCompactness(List<List<int>> board) {
    int compactness = 0;
    
    for (int r = 0; r < BOARD_SIZE; r++) {
      for (int c = 0; c < BOARD_SIZE; c++) {
        if (board[r][c] != 0) {
          // Count adjacent filled cells
          int adjacentFilled = 0;
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              if (dr == 0 && dc == 0) continue;
              final nr = r + dr;
              final nc = c + dc;
              if (nr >= 0 && nr < BOARD_SIZE && nc >= 0 && nc < BOARD_SIZE) {
                if (board[nr][nc] != 0) adjacentFilled++;
              }
            }
          }
          compactness += adjacentFilled;
        }
      }
    }

    return compactness;
  }

  /// Calculate confidence level of the move recommendation
  static double _calculateConfidence(int score) {
    // Normalize score to confidence (0.0 to 1.0)
    if (score <= 0) return 0.0;
    if (score >= 500) return 1.0;
    return score / 500.0;
  }

  /// Check if the current game state can be survived (has possible moves)
  static bool canSurvive(GameEngine engine) {
    return engine.anyMoveAvailableForCurrentSet();
  }

  /// Get emergency suggestions when game is near over
  static List<Map<String, dynamic>> getEmergencySuggestions(GameEngine engine) {
    final suggestions = <Map<String, dynamic>>[];
    
    if (!canSurvive(engine)) {
      suggestions.add({
        'type': 'gameOver',
        'message': 'No valid moves available. Game Over!',
        'action': 'restart',
      });
      return suggestions;
    }

    // Check if board is getting too full
    final fillPercentage = _getBoardFillPercentage(engine.board);
    if (fillPercentage > 0.7) {
      suggestions.add({
        'type': 'warning',
        'message': 'Board is getting full! Focus on clearing lines.',
        'action': 'clearLines',
      });
    }

    // Check for near-complete lines
    final nearComplete = _countNearCompleteLines(engine.board);
    if (nearComplete > 2) {
      suggestions.add({
        'type': 'opportunity',
        'message': 'Multiple lines are almost complete! Focus on completing them.',
        'action': 'completeLines',
      });
    }

    return suggestions;
  }

  /// Calculate what percentage of the board is filled
  static double _getBoardFillPercentage(List<List<int>> board) {
    int filledCells = 0;
    int totalCells = BOARD_SIZE * BOARD_SIZE;

    for (int r = 0; r < BOARD_SIZE; r++) {
      for (int c = 0; c < BOARD_SIZE; c++) {
        if (board[r][c] != 0) filledCells++;
      }
    }

    return filledCells / totalCells;
  }
}

/// Represents a potential move
class Move {
  final int pieceIndex;
  final int row;
  final int col;
  final int score;
  final List<Cell> piece;

  Move({
    required this.pieceIndex,
    required this.row,
    required this.col,
    required this.score,
    required this.piece,
  });

  @override
  String toString() {
    return 'Move(piece: $pieceIndex, pos: ($row, $col), score: $score)';
  }
}