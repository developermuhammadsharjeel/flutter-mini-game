// lib/game/piece_shapes.dart
// Piece shape definitions for Block Blast game
// A piece is defined as a list of (row,col) offsets relative to an origin (0,0)

typedef Cell = List<int>;

/// Comprehensive library of piece shapes for Block Blast
/// Each shape is represented as a list of [row, column] offsets from origin (0,0)
final List<List<Cell>> PIECE_LIBRARY = [
  // Single block
  [[0, 0]],

  // 2-block shapes
  [[0, 0], [0, 1]], // horizontal 2-block
  [[0, 0], [1, 0]], // vertical 2-block

  // 3-block shapes
  [[0, 0], [0, 1], [0, 2]], // horizontal 3-block
  [[0, 0], [1, 0], [2, 0]], // vertical 3-block
  [[0, 0], [1, 0], [0, 1]], // L-shape (small)
  [[0, 0], [0, 1], [1, 1]], // corner shape

  // 4-block shapes
  [[0, 0], [0, 1], [1, 0], [1, 1]], // 2x2 square
  [[0, 0], [0, 1], [0, 2], [0, 3]], // horizontal 4-block
  [[0, 0], [1, 0], [2, 0], [3, 0]], // vertical 4-block
  [[0, 0], [1, 0], [2, 0], [1, 1]], // T-shape
  [[0, 0], [1, 0], [2, 0], [0, 1]], // L-shape (large)
  [[0, 0], [1, 0], [2, 0], [2, 1]], // L-shape (reverse)

  // 5-block shapes
  [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], // horizontal 5-block
  [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], // vertical 5-block
  [[0, 0], [0, 1], [0, 2], [1, 1], [2, 1]], // plus/cross shape
  [[0, 0], [1, 0], [2, 0], [1, 1], [1, 2]], // T-shape (extended)

  // 6-block shapes
  [[0, 0], [0, 1], [1, 0], [1, 1], [2, 0], [2, 1]], // 3x2 rectangle
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2]], // 2x3 rectangle

  // 8-block shapes
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 2]], // hollow square

  // 9-block shapes (3x3 square)
  [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]], // full 3x3 square
];

/// Get a random selection of shapes for the piece queue
/// This is used by the game engine to generate new sets
List<List<Cell>> getRandomShapes(int count) {
  final shapes = List<List<Cell>>.from(PIECE_LIBRARY);
  shapes.shuffle();
  return shapes.take(count).toList();
}

/// Calculate the bounding box dimensions of a shape
Map<String, int> getShapeDimensions(List<Cell> shape) {
  if (shape.isEmpty) return {'width': 0, 'height': 0};
  
  int minRow = shape.map((cell) => cell[0]).reduce((a, b) => a < b ? a : b);
  int maxRow = shape.map((cell) => cell[0]).reduce((a, b) => a > b ? a : b);
  int minCol = shape.map((cell) => cell[1]).reduce((a, b) => a < b ? a : b);
  int maxCol = shape.map((cell) => cell[1]).reduce((a, b) => a > b ? a : b);
  
  return {
    'width': maxCol - minCol + 1,
    'height': maxRow - minRow + 1,
  };
}

/// Normalize a shape to start at origin (0,0)
List<Cell> normalizeShape(List<Cell> shape) {
  if (shape.isEmpty) return shape;
  
  int minRow = shape.map((cell) => cell[0]).reduce((a, b) => a < b ? a : b);
  int minCol = shape.map((cell) => cell[1]).reduce((a, b) => a < b ? a : b);
  
  return shape.map((cell) => [cell[0] - minRow, cell[1] - minCol]).toList();
}