// lib/widgets/board_widget.dart
// Enhanced game board widget with drag & drop functionality

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_engine.dart';
import '../game/piece_shapes.dart';

/// Enhanced board widget for the 8x8 game grid
class BoardWidget extends StatefulWidget {
  final GameEngine gameEngine;
  final Function(int pieceIndex, int row, int col) onPiecePlaced;
  final bool showHint;
  final Map<String, dynamic>? hint;

  const BoardWidget({
    Key? key,
    required this.gameEngine,
    required this.onPiecePlaced,
    this.showHint = false,
    this.hint,
  }) : super(key: key);

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> with TickerProviderStateMixin {
  int? _hoverRow;
  int? _hoverCol;
  int? _draggingPieceIndex;
  bool _canPlace = false;
  
  late AnimationController _lineCompletionController;
  late AnimationController _invalidPlacementController;
  
  Set<int> _completedRows = {};
  Set<int> _completedCols = {};

  @override
  void initState() {
    super.initState();
    _lineCompletionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _invalidPlacementController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _lineCompletionController.dispose();
    _invalidPlacementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = screenWidth - 32; // Account for padding
    final cellSize = boardSize / GameEngine.BOARD_SIZE;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DragTarget<int>(
          onWillAccept: (data) => data != null,
          onAccept: (pieceIndex) {
            if (_hoverRow != null && _hoverCol != null && _canPlace) {
              widget.onPiecePlaced(pieceIndex, _hoverRow!, _hoverCol!);
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.lightImpact();
              _invalidPlacementController.forward().then((_) {
                _invalidPlacementController.reverse();
              });
            }
            _resetDragState();
          },
          onLeave: (_) => _resetDragState(),
          onMove: (details) => _updateDragPosition(details, cellSize),
          builder: (context, candidateData, rejectedData) {
            return AnimatedBuilder(
              animation: _invalidPlacementController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    _invalidPlacementController.value * 10 * 
                    ((_invalidPlacementController.value * 4).floor() % 2 == 0 ? 1 : -1),
                    0,
                  ),
                  child: _buildBoard(cellSize),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBoard(double cellSize) {
    return Stack(
      children: [
        // Grid background
        _buildGridBackground(cellSize),
        
        // Filled cells
        _buildFilledCells(cellSize),
        
        // Hover preview
        if (_hoverRow != null && _hoverCol != null && _draggingPieceIndex != null)
          _buildHoverPreview(cellSize),
          
        // Hint overlay
        if (widget.showHint && widget.hint != null)
          _buildHintOverlay(cellSize),
          
        // Line completion animation overlay
        _buildLineCompletionOverlay(cellSize),
      ],
    );
  }

  Widget _buildGridBackground(double cellSize) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: CustomPaint(
        painter: GridPainter(
          cellSize: cellSize,
          gridSize: GameEngine.BOARD_SIZE,
          lineColor: Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }

  Widget _buildFilledCells(double cellSize) {
    final cells = <Widget>[];
    
    for (int row = 0; row < GameEngine.BOARD_SIZE; row++) {
      for (int col = 0; col < GameEngine.BOARD_SIZE; col++) {
        final cellValue = widget.gameEngine.board[row][col];
        if (cellValue > 0) {
          cells.add(
            Positioned(
              left: col * cellSize,
              top: row * cellSize,
              width: cellSize,
              height: cellSize,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: _getCellColor(cellValue),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }
    
    return Stack(children: cells);
  }

  Widget _buildHoverPreview(double cellSize) {
    if (_draggingPieceIndex == null || 
        _draggingPieceIndex! >= widget.gameEngine.currentSet.length) {
      return const SizedBox.shrink();
    }

    final piece = widget.gameEngine.currentSet[_draggingPieceIndex!];
    final cells = <Widget>[];

    for (final cell in piece) {
      final cellRow = _hoverRow! + cell[0];
      final cellCol = _hoverCol! + cell[1];
      
      if (cellRow >= 0 && cellRow < GameEngine.BOARD_SIZE &&
          cellCol >= 0 && cellCol < GameEngine.BOARD_SIZE) {
        cells.add(
          Positioned(
            left: cellCol * cellSize,
            top: cellRow * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _canPlace 
                  ? Colors.white.withOpacity(0.6)
                  : Colors.red.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _canPlace ? Colors.white : Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: cells);
  }

  Widget _buildHintOverlay(double cellSize) {
    final hint = widget.hint!;
    final pieceIndex = hint['pieceIndex'] as int;
    final hintRow = hint['row'] as int;
    final hintCol = hint['col'] as int;
    
    if (pieceIndex >= widget.gameEngine.currentSet.length) {
      return const SizedBox.shrink();
    }

    final piece = widget.gameEngine.currentSet[pieceIndex];
    final cells = <Widget>[];

    for (final cell in piece) {
      final cellRow = hintRow + cell[0];
      final cellCol = hintCol + cell[1];
      
      if (cellRow >= 0 && cellRow < GameEngine.BOARD_SIZE &&
          cellCol >= 0 && cellCol < GameEngine.BOARD_SIZE) {
        cells.add(
          Positioned(
            left: cellCol * cellSize,
            top: cellRow * cellSize,
            width: cellSize,
            height: cellSize,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.yellow,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.lightbulb,
                color: Colors.yellow,
                size: 16,
              ),
            ),
          ),
        );
      }
    }

    return Stack(children: cells);
  }

  Widget _buildLineCompletionOverlay(double cellSize) {
    final overlays = <Widget>[];
    
    // Row completion animations
    for (final row in _completedRows) {
      overlays.add(
        Positioned(
          left: 0,
          top: row * cellSize,
          width: GameEngine.BOARD_SIZE * cellSize,
          height: cellSize,
          child: AnimatedBuilder(
            animation: _lineCompletionController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(
                    0.5 * (1 - _lineCompletionController.value),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    // Column completion animations
    for (final col in _completedCols) {
      overlays.add(
        Positioned(
          left: col * cellSize,
          top: 0,
          width: cellSize,
          height: GameEngine.BOARD_SIZE * cellSize,
          child: AnimatedBuilder(
            animation: _lineCompletionController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(
                    0.5 * (1 - _lineCompletionController.value),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    
    return Stack(children: overlays);
  }

  void _updateDragPosition(DragTargetDetails<int> details, double cellSize) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || details.data == null) return;

    final localOffset = box.globalToLocal(details.offset);
    final col = (localOffset.dx / cellSize).floor();
    final row = (localOffset.dy / cellSize).floor();

    if (row >= 0 && row < GameEngine.BOARD_SIZE && 
        col >= 0 && col < GameEngine.BOARD_SIZE) {
      setState(() {
        _hoverRow = row;
        _hoverCol = col;
        _draggingPieceIndex = details.data;

        if (_draggingPieceIndex != null &&
            _draggingPieceIndex! < widget.gameEngine.currentSet.length) {
          _canPlace = widget.gameEngine.canPlacePieceAt(
            widget.gameEngine.currentSet[_draggingPieceIndex!],
            row,
            col,
          );
        }
      });
    }
  }

  void _resetDragState() {
    setState(() {
      _hoverRow = null;
      _hoverCol = null;
      _draggingPieceIndex = null;
      _canPlace = false;
    });
  }

  Color _getCellColor(int cellValue) {
    final colors = [
      Colors.red.shade400,
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.lime.shade400,
    ];
    
    return colors[(cellValue - 1) % colors.length];
  }

  void _triggerLineCompletionAnimation(Set<int> rows, Set<int> cols) {
    setState(() {
      _completedRows = rows;
      _completedCols = cols;
    });
    
    _lineCompletionController.forward().then((_) {
      _lineCompletionController.reset();
      setState(() {
        _completedRows.clear();
        _completedCols.clear();
      });
    });
  }
}

/// Custom painter for the grid background
class GridPainter extends CustomPainter {
  final double cellSize;
  final int gridSize;
  final Color lineColor;

  GridPainter({
    required this.cellSize,
    required this.gridSize,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw vertical lines
    for (int i = 0; i <= gridSize; i++) {
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (int i = 0; i <= gridSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}