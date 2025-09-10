// test/game_engine_test.dart
// Unit tests for the Block Blast game engine

import 'package:flutter_test/flutter_test.dart';
import 'package:block_blast/game/game_engine.dart';
import 'package:block_blast/game/piece_shapes.dart';

void main() {
  group('GameEngine Tests', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('should initialize with empty 8x8 board', () {
      expect(engine.board.length, equals(8));
      expect(engine.board[0].length, equals(8));
      
      // Check all cells are empty
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          expect(engine.board[r][c], equals(0));
        }
      }
    });

    test('should generate initial piece set', () {
      expect(engine.currentSet.length, equals(3));
      expect(engine.currentSet.every((piece) => piece.isNotEmpty), isTrue);
    });

    test('should validate piece placement correctly', () {
      // Test valid placement
      final singleBlock = [[0, 0]];
      expect(engine.canPlacePieceAt(singleBlock, 0, 0), isTrue);
      expect(engine.canPlacePieceAt(singleBlock, 7, 7), isTrue);
      expect(engine.canPlacePieceAt(singleBlock, 3, 3), isTrue);

      // Test invalid placement (out of bounds)
      expect(engine.canPlacePieceAt(singleBlock, -1, 0), isFalse);
      expect(engine.canPlacePieceAt(singleBlock, 0, -1), isFalse);
      expect(engine.canPlacePieceAt(singleBlock, 8, 0), isFalse);
      expect(engine.canPlacePieceAt(singleBlock, 0, 8), isFalse);

      // Test placement on occupied cell
      engine.board[3][3] = 1; // Place a block
      expect(engine.canPlacePieceAt(singleBlock, 3, 3), isFalse);
    });

    test('should place piece and update board correctly', () {
      final piece = [[0, 0], [0, 1], [1, 0]]; // L-shape
      final initialScore = engine.score;
      
      final success = engine.placePieceAt(piece, 2, 2, colorValue: 5);
      
      expect(success, isTrue);
      expect(engine.board[2][2], equals(5));
      expect(engine.board[2][3], equals(5));
      expect(engine.board[3][2], equals(5));
      expect(engine.score, greaterThan(initialScore));
    });

    test('should not place piece at invalid position', () {
      final piece = [[0, 0], [0, 1]]; // 2-block horizontal
      final initialScore = engine.score;
      
      // Try to place out of bounds
      final success = engine.placePieceAt(piece, 0, 7, colorValue: 1); // Would go to column 8
      
      expect(success, isFalse);
      expect(engine.score, equals(initialScore));
      expect(engine.board[0][7], equals(0));
    });

    test('should clear completed rows correctly', () {
      // Fill a complete row
      for (int c = 0; c < 8; c++) {
        engine.board[0][c] = 1;
      }
      
      final clearedInfo = engine.clearLines();
      
      expect(clearedInfo['rows'], equals(1));
      expect(clearedInfo['cols'], equals(0));
      expect(clearedInfo['total'], equals(1));
      
      // Check row is cleared
      for (int c = 0; c < 8; c++) {
        expect(engine.board[0][c], equals(0));
      }
    });

    test('should clear completed columns correctly', () {
      // Fill a complete column
      for (int r = 0; r < 8; r++) {
        engine.board[r][0] = 1;
      }
      
      final clearedInfo = engine.clearLines();
      
      expect(clearedInfo['rows'], equals(0));
      expect(clearedInfo['cols'], equals(1));
      expect(clearedInfo['total'], equals(1));
      
      // Check column is cleared
      for (int r = 0; r < 8; r++) {
        expect(engine.board[r][0], equals(0));
      }
    });

    test('should clear multiple rows and columns simultaneously', () {
      // Fill two complete rows
      for (int c = 0; c < 8; c++) {
        engine.board[0][c] = 1;
        engine.board[1][c] = 1;
      }
      
      // Fill one complete column
      for (int r = 0; r < 8; r++) {
        engine.board[r][7] = 1;
      }
      
      final clearedInfo = engine.clearLines();
      
      expect(clearedInfo['rows'], equals(2));
      expect(clearedInfo['cols'], equals(1));
      expect(clearedInfo['total'], equals(3));
    });

    test('should detect game over correctly', () {
      // Fill board leaving only small spaces
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (r != 7 || c != 7) { // Leave only one cell empty
            engine.board[r][c] = 1;
          }
        }
      }
      
      // Set current pieces to be larger than available space
      engine.currentSet = [
        [[0, 0], [0, 1]], // 2-block piece
        [[0, 0], [1, 0]], // 2-block piece
        [[0, 0], [0, 1], [0, 2]], // 3-block piece
      ];
      
      expect(engine.isGameOver(), isTrue);
    });

    test('should detect available moves correctly', () {
      // Empty board should have moves available
      expect(engine.anyMoveAvailableForCurrentSet(), isTrue);
      
      // Fill board completely
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          engine.board[r][c] = 1;
        }
      }
      
      expect(engine.anyMoveAvailableForCurrentSet(), isFalse);
    });

    test('should not generate identical consecutive sets', () {
      // Generate many sets and ensure no immediate repeats
      for (int i = 0; i < 20; i++) {
        final previousSet = List.from(engine.currentSet);
        engine.generateNewSet();
        
        // Sets should not be identical (order-insensitive)
        final previousKeys = previousSet.map((piece) => _normalizeShapeKey(piece)).toList()..sort();
        final currentKeys = engine.currentSet.map((piece) => _normalizeShapeKey(piece)).toList()..sort();
        
        expect(previousKeys.join('|'), isNot(equals(currentKeys.join('|'))));
      }
    });

    test('should reset game correctly', () {
      // Modify game state
      engine.board[0][0] = 1;
      engine.score = 100;
      engine.totalLinesCleared = 5;
      engine.totalPiecesPlaced = 10;
      
      engine.resetGame();
      
      // Check everything is reset
      expect(engine.score, equals(0));
      expect(engine.totalLinesCleared, equals(0));
      expect(engine.totalPiecesPlaced, equals(0));
      expect(engine.currentCombo, equals(0));
      
      // Check board is empty
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          expect(engine.board[r][c], equals(0));
        }
      }
      
      // Check new pieces are generated
      expect(engine.currentSet.length, equals(3));
    });

    test('should calculate score correctly', () {
      final initialScore = engine.score;
      final piece = [[0, 0], [0, 1], [0, 2]]; // 3-block piece
      
      engine.placePieceAt(piece, 0, 0, colorValue: 1);
      
      // Score should increase by at least the base points for piece placement
      expect(engine.score, greaterThan(initialScore));
      expect(engine.score - initialScore, greaterThanOrEqualTo(15)); // 3 cells * 5 points
    });

    test('should remove piece from set after placement', () {
      final initialSetLength = engine.currentSet.length;
      final piece = engine.currentSet[0];
      
      engine.placePieceAt(piece, 0, 0, colorValue: 1);
      engine.removePieceFromSet(0);
      
      expect(engine.currentSet.length, equals(initialSetLength - 1));
    });

    test('should generate new set when all pieces used', () {
      // Use all pieces
      while (engine.currentSet.isNotEmpty) {
        engine.removePieceFromSet(0);
      }
      
      // Should automatically generate new set
      expect(engine.currentSet.length, equals(3));
    });
  });

  group('Piece Shapes Tests', () {
    test('should normalize shapes correctly', () {
      final shape = [[1, 1], [1, 2], [2, 1]]; // L-shape not at origin
      final normalized = normalizeShape(shape);
      
      expect(normalized, equals([[0, 0], [0, 1], [1, 0]]));
    });

    test('should calculate shape dimensions correctly', () {
      final shape = [[0, 0], [0, 1], [0, 2]]; // 1x3 horizontal
      final dimensions = getShapeDimensions(shape);
      
      expect(dimensions['width'], equals(3));
      expect(dimensions['height'], equals(1));
      
      final verticalShape = [[0, 0], [1, 0], [2, 0]]; // 3x1 vertical
      final verticalDimensions = getShapeDimensions(verticalShape);
      
      expect(verticalDimensions['width'], equals(1));
      expect(verticalDimensions['height'], equals(3));
    });

    test('should have valid piece library', () {
      expect(PIECE_LIBRARY.isNotEmpty, isTrue);
      
      // All pieces should be non-empty
      for (final piece in PIECE_LIBRARY) {
        expect(piece.isNotEmpty, isTrue);
        
        // All cells should have valid coordinates
        for (final cell in piece) {
          expect(cell.length, equals(2));
          expect(cell[0], isA<int>());
          expect(cell[1], isA<int>());
        }
      }
    });

    test('should get random shapes without repetition in same call', () {
      final shapes = getRandomShapes(3);
      
      expect(shapes.length, equals(3));
      
      // Convert to normalized keys for comparison
      final keys = shapes.map(_normalizeShapeKey).toList();
      final uniqueKeys = keys.toSet();
      
      // Should not have duplicates within the same set
      expect(uniqueKeys.length, equals(keys.length));
    });
  });
}

/// Helper function to create a normalized key for a shape
String _normalizeShapeKey(List<Cell> shape) {
  final normalized = normalizeShape(shape);
  final coords = normalized.map((cell) => '${cell[0]},${cell[1]}').toList()..sort();
  return coords.join('|');
}