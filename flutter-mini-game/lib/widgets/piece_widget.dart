// lib/widgets/piece_widget.dart
// Enhanced piece widget for displaying and dragging game pieces

import 'package:flutter/material.dart';
import '../game/piece_shapes.dart';

/// Widget for displaying and interacting with game pieces
class PieceWidget extends StatefulWidget {
  final List<List<Cell>> pieces;
  final Function(int index) onPieceDragStarted;

  const PieceWidget({
    Key? key,
    required this.pieces,
    required this.onPieceDragStarted,
  }) : super(key: key);

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget> {
  int? _draggingIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.pieces.length,
        (index) => _buildPieceContainer(index),
      ),
    );
  }

  Widget _buildPieceContainer(int index) {
    final piece = widget.pieces[index];
    final isDragging = _draggingIndex == index;

    return Draggable<int>(
      data: index,
      feedback: Material(
        color: Colors.transparent,
        child: _buildPieceDisplay(
          piece,
          cellSize: 32,
          opacity: 0.8,
          glowEffect: true,
        ),
      ),
      childWhenDragging: _buildPieceDisplay(
        piece,
        cellSize: 24,
        opacity: 0.3,
      ),
      onDragStarted: () {
        setState(() {
          _draggingIndex = index;
        });
        widget.onPieceDragStarted(index);
      },
      onDragEnd: (_) {
        setState(() {
          _draggingIndex = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDragging 
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isDragging
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: Center(
          child: _buildPieceDisplay(piece, cellSize: 24),
        ),
      ),
    );
  }

  Widget _buildPieceDisplay(
    List<Cell> piece, {
    required double cellSize,
    double opacity = 1.0,
    bool glowEffect = false,
  }) {
    if (piece.isEmpty) {
      return const SizedBox.shrink();
    }

    final dimensions = getShapeDimensions(piece);
    final width = dimensions['width']! * cellSize;
    final height = dimensions['height']! * cellSize;

    return Container(
      width: width,
      height: height,
      decoration: glowEffect
        ? BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: _getPieceColor(piece).withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          )
        : null,
      child: Stack(
        children: piece.map((cell) {
          return Positioned(
            left: cell[1] * cellSize,
            top: cell[0] * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _getPieceColor(piece).withOpacity(opacity),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: Colors.white.withOpacity(opacity * 0.8),
                  width: 1,
                ),
                boxShadow: glowEffect
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPieceColor(List<Cell> piece) {
    // Generate color based on piece shape for consistency
    final hash = piece.length + piece.first[0] + piece.first[1];
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
    
    return colors[hash % colors.length];
  }
}