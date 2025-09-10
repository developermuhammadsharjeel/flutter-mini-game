import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const BlockBlastApp());
}

class BlockBlastApp extends StatelessWidget {
  const BlockBlastApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Blast',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GamePage(),
      debugShowCheckedModeBanner: false,
      // Enable this to see widget boundaries for debugging
      // debugShowMaterialGrid: true,
    );
  }
}

// Model classes for game elements
class Block {
  final Color color;

  Block({required this.color});

  Block copyWith({Color? color}) {
    return Block(color: color ?? this.color);
  }
}

class Point {
  final int x;
  final int y;

  const Point(this.x, this.y);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point && other.x == x && other.y == y;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Point operator +(Point other) => Point(x + other.x, y + other.y);
}

class Shape {
  final List<Point> blocks;
  final Color color;

  const Shape({required this.blocks, required this.color});

  Shape copyWith({List<Point>? blocks, Color? color}) {
    return Shape(
      blocks: blocks ?? this.blocks,
      color: color ?? this.color,
    );
  }

  // Get shape width and height for boundary checks
  int get width {
    if (blocks.isEmpty) return 0;
    int minX = blocks.map((p) => p.x).reduce(min);
    int maxX = blocks.map((p) => p.x).reduce(max);
    return maxX - minX + 1;
  }

  int get height {
    if (blocks.isEmpty) return 0;
    int minY = blocks.map((p) => p.y).reduce(min);
    int maxY = blocks.map((p) => p.y).reduce(max);
    return maxY - minY + 1;
  }

  // Normalize shape to start at 0,0
  Shape get normalized {
    if (blocks.isEmpty) return this;
    int minX = blocks.map((p) => p.x).reduce(min);
    int minY = blocks.map((p) => p.y).reduce(min);

    return Shape(
      blocks: blocks.map((p) => Point(p.x - minX, p.y - minY)).toList(),
      color: color,
    );
  }
}

class GameController extends ChangeNotifier {
  // Game settings
  static const int gridSize = 9;
  static const int queueSize = 3;

  // Game state
  late List<List<Block?>> board;
  late List<Shape> blockQueue;
  int currentScore = 0;
  int highScore = 0;
  bool isGameOver = false;

  // Available shapes
  static final List<List<Point>> shapeTemplates = [
    // Single block
    [const Point(0, 0)],

    // 2-block shapes
    [const Point(0, 0), const Point(1, 0)],
    [const Point(0, 0), const Point(0, 1)],

    // 3-block shapes
    [const Point(0, 0), const Point(1, 0), const Point(2, 0)], // I-shape (horizontal)
    [const Point(0, 0), const Point(0, 1), const Point(0, 2)], // I-shape (vertical)
    [const Point(0, 0), const Point(1, 0), const Point(0, 1)], // L-shape
    [const Point(0, 0), const Point(0, 1), const Point(1, 1)], // Z-shape

    // 4-block shapes
    [const Point(0, 0), const Point(1, 0), const Point(0, 1), const Point(1, 1)], // Square
    [const Point(0, 0), const Point(1, 0), const Point(2, 0), const Point(1, 1)], // T-shape
    [const Point(0, 0), const Point(1, 0), const Point(2, 0), const Point(0, 1)], // L-shape
  ];

  // Colors for blocks
  static final List<Color> blockColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
  ];

  // Constructor
  GameController() {
    _initGame();
    _loadHighScore();
  }

  // Initialize a new game
  void _initGame() {
    board = List.generate(
        gridSize,
            (_) => List.generate(gridSize, (_) => null)
    );
    blockQueue = [];
    _refillQueue();
    currentScore = 0;
    isGameOver = false;
    notifyListeners();
  }

  // Load high score from persistent storage
  Future<void> _loadHighScore() async {
    try {
      // Comment this out if having issues with shared_preferences
      // final prefs = await SharedPreferences.getInstance();
      // highScore = prefs.getInt('highScore') ?? 0;

      // Use default value for now
      highScore = 0;
    } catch (e) {
      print('Error loading high score: $e');
      highScore = 0;
    }
    notifyListeners();
  }

  // Save high score to persistent storage
  Future<void> _saveHighScore() async {
    if (currentScore > highScore) {
      highScore = currentScore;
      try {
        // Comment this out if having issues with shared_preferences
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setInt('highScore', highScore);
      } catch (e) {
        print('Error saving high score: $e');
      }
    }
    notifyListeners();
  }

  // Fill the queue with random shapes
  void _refillQueue() {
    final random = Random();

    while (blockQueue.length < queueSize) {
      // Select a random shape template
      final templateIndex = random.nextInt(shapeTemplates.length);
      final template = shapeTemplates[templateIndex];

      // Select a random color
      final colorIndex = random.nextInt(blockColors.length);
      final color = blockColors[colorIndex];

      // Create the shape and add to queue
      blockQueue.add(Shape(blocks: template, color: color).normalized);
    }

    notifyListeners();
  }

  // Check if a shape can be placed at the given position
  bool canPlaceShape(Shape shape, int boardX, int boardY) {
    for (final point in shape.blocks) {
      final x = boardX + point.x;
      final y = boardY + point.y;

      // Check boundaries
      if (x < 0 || x >= gridSize || y < 0 || y >= gridSize) {
        return false;
      }

      // Check if cell is already occupied
      if (board[y][x] != null) {
        return false;
      }
    }

    return true;
  }

  // Place a shape on the board
  void placeShape(int queueIndex, int boardX, int boardY) {
    if (queueIndex < 0 || queueIndex >= blockQueue.length) return;

    final shape = blockQueue[queueIndex];
    if (!canPlaceShape(shape, boardX, boardY)) return;

    // Place each block
    for (final point in shape.blocks) {
      final x = boardX + point.x;
      final y = boardY + point.y;
      board[y][x] = Block(color: shape.color);
    }

    // Remove the shape from the queue
    blockQueue.removeAt(queueIndex);

    // Check for completed lines
    final clearedLines = _checkForCompletedLines();

    // Calculate score
    if (clearedLines > 0) {
      _updateScore(clearedLines, shape.blocks.length);
    }

    // Refill the queue
    _refillQueue();

    // Check for game over
    if (_checkGameOver()) {
      isGameOver = true;
      _saveHighScore();
    }

    notifyListeners();
  }

  // Check for completed lines (horizontal and vertical)
  int _checkForCompletedLines() {
    final Set<int> rowsToClear = {};
    final Set<int> colsToClear = {};

    // Check horizontal lines
    for (int y = 0; y < gridSize; y++) {
      bool isComplete = true;
      for (int x = 0; x < gridSize; x++) {
        if (board[y][x] == null) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        rowsToClear.add(y);
      }
    }

    // Check vertical lines
    for (int x = 0; x < gridSize; x++) {
      bool isComplete = true;
      for (int y = 0; y < gridSize; y++) {
        if (board[y][x] == null) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        colsToClear.add(x);
      }
    }

    // Clear the lines
    for (final row in rowsToClear) {
      for (int x = 0; x < gridSize; x++) {
        board[row][x] = null;
      }
    }

    for (final col in colsToClear) {
      for (int y = 0; y < gridSize; y++) {
        board[y][col] = null;
      }
    }

    return rowsToClear.length + colsToClear.length;
  }

  // Update score based on cleared lines and block count
  void _updateScore(int clearedLines, int blockCount) {
    // Base points
    int basePoints = blockCount * 10;

    // Combo bonus
    int comboBonus = 0;
    if (clearedLines == 2) {
      comboBonus = 30;
    } else if (clearedLines >= 3) {
      comboBonus = 50;
    }

    currentScore += basePoints + comboBonus;
    notifyListeners();
  }

  // Check if game is over (no shape can be placed anywhere)
  bool _checkGameOver() {
    for (final shape in blockQueue) {
      for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
          if (canPlaceShape(shape, x, y)) {
            return false;  // Found a valid move
          }
        }
      }
    }
    return true;  // No valid moves found
  }

  // Restart the game
  void restartGame() {
    _initGame();
  }
}

class GamePage extends StatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  late GameController gameController;
  int? draggingShapeIndex;

  @override
  void initState() {
    super.initState();
    gameController = GameController();
  }

  @override
  void dispose() {
    gameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Blast'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              gameController.restartGame();
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: gameController,
        builder: (context, _) {
          return Column(
            children: [
              // Score display
              ScoreDisplay(
                currentScore: gameController.currentScore,
                highScore: gameController.highScore,
              ),

              // Game board
              GameBoard(
                gameController: gameController,
                onBlockPlaced: (queueIndex, x, y) {
                  gameController.placeShape(queueIndex, x, y);
                },
              ),

              // Block queue
              BlockQueue(
                shapes: gameController.blockQueue,
                onDragStarted: (index) {
                  setState(() {
                    draggingShapeIndex = index;
                  });
                },
                onDragEnded: () {
                  setState(() {
                    draggingShapeIndex = null;
                  });
                },
              ),
            ],
          );
        },
      ),
      // Game over overlay
      floatingActionButton: gameController.isGameOver
          ? FloatingActionButton.extended(
        onPressed: () {
          gameController.restartGame();
        },
        label: const Text('Game Over - Restart'),
        icon: const Icon(Icons.refresh),
      )
          : null,
    );
  }
}

class ScoreDisplay extends StatelessWidget {
  final int currentScore;
  final int highScore;

  const ScoreDisplay({
    Key? key,
    required this.currentScore,
    required this.highScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Score: $currentScore',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'High: $highScore',
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class GameBoard extends StatefulWidget {
  final GameController gameController;
  final Function(int queueIndex, int x, int y) onBlockPlaced;

  const GameBoard({
    Key? key,
    required this.gameController,
    required this.onBlockPlaced,
  }) : super(key: key);

  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  int? hoverX;
  int? hoverY;
  int? draggingShapeIndex;
  bool canPlace = false;

  @override
  Widget build(BuildContext context) {
    final gridSize = GameController.gridSize;
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = screenWidth / gridSize;

    return Expanded(
      child: DragTarget<int>(
        onWillAccept: (data) => true,
        onAccept: (queueIndex) {
          if (hoverX != null && hoverY != null && canPlace) {
            widget.onBlockPlaced(queueIndex, hoverX!, hoverY!);
          }
          setState(() {
            hoverX = null;
            hoverY = null;
            draggingShapeIndex = null;
            canPlace = false;
          });
        },
        onLeave: (_) {
          setState(() {
            hoverX = null;
            hoverY = null;
            canPlace = false;
          });
        },
        onMove: (details) {
          if (details.data == null) return; // Add null check

          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box == null) return; // Add null check for render box

          final localOffset = box.globalToLocal(details.offset);
          final x = (localOffset.dx / cellSize).floor();
          final y = (localOffset.dy / cellSize).floor();

          if (x >= 0 && x < gridSize && y >= 0 && y < gridSize) {
            setState(() {
              hoverX = x;
              hoverY = y;
              draggingShapeIndex = details.data;

              if (draggingShapeIndex != null &&
                  draggingShapeIndex! < widget.gameController.blockQueue.length) {
                canPlace = widget.gameController.canPlaceShape(
                  widget.gameController.blockQueue[draggingShapeIndex!],
                  x,
                  y,
                );
              }
            });
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            color: Colors.grey[200],
            width: screenWidth, // Explicit width
            height: screenWidth, // Make it square
            child: Stack(
              children: [
                // Grid cells
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                  ),
                  itemCount: gridSize * gridSize,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final x = index % gridSize;
                    final y = index ~/ gridSize;
                    final block = widget.gameController.board[y][x];

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: block?.color ?? Colors.white,
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                    );
                  },
                ),

                // Hover preview
                if (hoverX != null && hoverY != null && draggingShapeIndex != null &&
                    draggingShapeIndex! < widget.gameController.blockQueue.length) // Added safety check
                  Positioned(
                    left: hoverX! * cellSize,
                    top: hoverY! * cellSize,
                    child: ShapePreview(
                      shape: widget.gameController.blockQueue[draggingShapeIndex!],
                      cellSize: cellSize,
                      isValid: canPlace,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BlockQueue extends StatelessWidget {
  final List<Shape> shapes;
  final Function(int index) onDragStarted;
  final VoidCallback onDragEnded;

  const BlockQueue({
    Key? key,
    required this.shapes,
    required this.onDragStarted,
    required this.onDragEnded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure we have explicit dimensions for the queue area
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 120, // Fixed height
      width: screenWidth, // Full width
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[300],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(shapes.length, (index) {
          // Add a key to help Flutter track widgets correctly
          return Draggable<int>(
            key: ValueKey('draggable_shape_$index'),
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: ShapePreview(
                shape: shapes[index],
                cellSize: 30,
                isValid: true,
              ),
            ),
            childWhenDragging: Container(
              width: 80, // Fixed width
              height: 80, // Fixed height
              color: Colors.transparent,
              child: ShapeDisplay(
                shape: shapes[index],
                cellSize: 25,
                opacity: 0.3,
              ),
            ),
            onDragStarted: () => onDragStarted(index),
            onDragEnd: (_) => onDragEnded(),
            child: Container(
              width: 80, // Fixed width
              height: 80, // Fixed height
              color: Colors.white.withOpacity(0.6),
              padding: const EdgeInsets.all(4),
              child: ShapeDisplay(
                shape: shapes[index],
                cellSize: 25,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class ShapeDisplay extends StatelessWidget {
  final Shape shape;
  final double cellSize;
  final double opacity;

  const ShapeDisplay({
    Key? key,
    required this.shape,
    required this.cellSize,
    this.opacity = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure minimum dimensions
    final width = max((shape.width * cellSize), 30.0);
    final height = max((shape.height * cellSize), 30.0);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: shape.blocks.map((point) {
          return Positioned(
            left: point.x * cellSize,
            top: point.y * cellSize,
            width: cellSize, // Explicit width
            height: cellSize, // Explicit height
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: shape.color.withOpacity(opacity),
                border: Border.all(color: Colors.grey[400]!),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ShapePreview extends StatelessWidget {
  final Shape shape;
  final double cellSize;
  final bool isValid;

  const ShapePreview({
    Key? key,
    required this.shape,
    required this.cellSize,
    required this.isValid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use Material widget to ensure proper rendering
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: shape.width * cellSize,
        height: shape.height * cellSize,
        child: Stack(
          children: shape.blocks.map((point) {
            return Positioned(
              left: point.x * cellSize,
              top: point.y * cellSize,
              width: cellSize, // Explicit width
              height: cellSize, // Explicit height
              child: Container(
                decoration: BoxDecoration(
                  color: isValid
                      ? shape.color.withOpacity(0.7)
                      : Colors.red.withOpacity(0.5),
                  border: Border.all(
                    color: isValid ? Colors.white : Colors.red,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}