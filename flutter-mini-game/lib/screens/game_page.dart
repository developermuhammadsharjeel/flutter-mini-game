// lib/screens/game_page.dart
// Enhanced game screen with modern UI and improved UX

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import '../game/game_engine.dart';
import '../game/ai_helper.dart';
import '../widgets/board_widget.dart';
import '../widgets/piece_widget.dart';
import '../utils/audio_manager.dart';

/// Game state provider
final gameEngineProvider = StateNotifierProvider<GameEngineNotifier, GameEngine>((ref) {
  return GameEngineNotifier();
});

/// Game engine state notifier
class GameEngineNotifier extends StateNotifier<GameEngine> {
  GameEngineNotifier() : super(GameEngine());

  bool _undoAvailable = false;
  List<List<int>>? _previousBoard;
  int _previousScore = 0;

  bool get undoAvailable => _undoAvailable;

  void placePiece(int pieceIndex, int row, int col) {
    if (pieceIndex >= state.currentSet.length) return;

    final piece = state.currentSet[pieceIndex];
    if (!state.canPlacePieceAt(piece, row, col)) {
      AudioManager().playSfx(SoundEffect.invalidMove);
      return;
    }

    // Save state for undo
    _previousBoard = state.board.map((r) => List<int>.from(r)).toList();
    _previousScore = state.score;
    _undoAvailable = true;

    // Place the piece
    final success = state.placePieceAt(piece, row, col, colorValue: pieceIndex + 1);
    
    if (success) {
      AudioManager().playSfx(SoundEffect.placePiece);
      
      // Check for line clears
      if (state.currentCombo > 0) {
        if (state.currentCombo == 1) {
          AudioManager().playSfx(SoundEffect.clearLine);
        } else {
          AudioManager().playSfx(SoundEffect.clearCombo);
        }
      }

      // Remove piece from set
      state.removePieceFromSet(pieceIndex);
      
      // Check for game over
      if (state.isGameOver()) {
        AudioManager().playSfx(SoundEffect.gameOver);
        _saveHighScore();
      }

      // Trigger rebuild
      state = GameEngine()
        ..board = state.board
        ..score = state.score
        ..bestScore = state.bestScore
        ..currentSet = state.currentSet
        ..lastSet = state.lastSet
        ..totalLinesCleared = state.totalLinesCleared
        ..totalPiecesPlaced = state.totalPiecesPlaced
        ..currentCombo = state.currentCombo;
    }
  }

  void undoLastMove() {
    if (!_undoAvailable || _previousBoard == null) return;

    state.board = _previousBoard!;
    state.score = _previousScore;
    _undoAvailable = false;
    _previousBoard = null;

    // Trigger rebuild
    state = GameEngine()
      ..board = state.board
      ..score = state.score
      ..bestScore = state.bestScore
      ..currentSet = state.currentSet
      ..lastSet = state.lastSet
      ..totalLinesCleared = state.totalLinesCleared
      ..totalPiecesPlaced = state.totalPiecesPlaced
      ..currentCombo = state.currentCombo;
  }

  void restartGame() {
    state.resetGame();
    _undoAvailable = false;
    _previousBoard = null;
    _previousScore = 0;

    // Trigger rebuild
    state = GameEngine()
      ..board = state.board
      ..score = state.score
      ..bestScore = state.bestScore
      ..currentSet = state.currentSet
      ..lastSet = state.lastSet;
  }

  Future<void> _saveHighScore() async {
    if (state.score > state.bestScore) {
      state.updateBestScore();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('high_score', state.bestScore);
        AudioManager().playSfx(SoundEffect.newHighScore);
      } catch (e) {
        print('Error saving high score: $e');
      }
    }
  }

  Map<String, dynamic>? getHint() {
    return AIHelper.findBestMove(state);
  }
}

/// Enhanced game page with modern UI
class GamePage extends ConsumerStatefulWidget {
  const GamePage({Key? key}) : super(key: key);

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _scoreAnimationController;
  late AnimationController _comboAnimationController;
  
  bool _showHint = false;
  Map<String, dynamic>? _currentHint;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _comboAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scoreAnimationController.dispose();
    _comboAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameEngineProvider);
    final gameNotifier = ref.read(gameEngineProvider.notifier);

    // Trigger animations based on game state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (game.currentCombo > 0) {
        _scoreAnimationController.forward().then((_) {
          _scoreAnimationController.reverse();
        });
        
        if (game.currentCombo > 1) {
          _comboAnimationController.forward().then((_) {
            _comboAnimationController.reverse();
          });
          _confettiController.play();
        }
      }
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo.shade800,
              Colors.indigo.shade600,
              Colors.indigo.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(game, gameNotifier),
              
              // Game board
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BoardWidget(
                    gameEngine: game,
                    onPiecePlaced: gameNotifier.placePiece,
                    showHint: _showHint,
                    hint: _currentHint,
                  ),
                ),
              ),
              
              // Piece queue
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: PieceWidget(
                    pieces: game.currentSet,
                    onPieceDragStarted: (index) {
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ),
              
              // Bottom controls
              _buildBottomControls(gameNotifier),
            ],
          ),
        ),
      ),
      // Confetti overlay
      floatingActionButton: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: 1.5708, // radians - 90 degrees
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.1,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      // Game over overlay
      body: Stack(
        children: [
          // Main game content (already built above)
          Column(
            children: [
              _buildTopBar(game, gameNotifier),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BoardWidget(
                    gameEngine: game,
                    onPiecePlaced: gameNotifier.placePiece,
                    showHint: _showHint,
                    hint: _currentHint,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: PieceWidget(
                    pieces: game.currentSet,
                    onPieceDragStarted: (index) {
                      HapticFeedback.lightImpact();
                    },
                  ),
                ),
              ),
              _buildBottomControls(gameNotifier),
            ],
          ),
          
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 1.5708,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
            ),
          ),
          
          // Game over overlay
          if (game.isGameOver()) _buildGameOverOverlay(game, gameNotifier),
        ],
      ),
    );
  }

  Widget _buildTopBar(GameEngine game, GameEngineNotifier gameNotifier) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () {
              AudioManager().playSfx(SoundEffect.buttonClick);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.home, color: Colors.white, size: 28),
          ),
          
          const Spacer(),
          
          // Score display
          Column(
            children: [
              AnimatedBuilder(
                animation: _scoreAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_scoreAnimationController.value * 0.2),
                    child: Text(
                      '${game.score}',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              Text(
                'Best: ${game.bestScore}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Combo indicator
          if (game.currentCombo > 1)
            AnimatedBuilder(
              animation: _comboAnimationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_comboAnimationController.value * 0.3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${game.currentCombo}x',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            )
          else
            const SizedBox(width: 60), // Placeholder to maintain layout
        ],
      ),
    );
  }

  Widget _buildBottomControls(GameEngineNotifier gameNotifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo button
          _buildControlButton(
            icon: Icons.undo,
            label: 'Undo',
            enabled: gameNotifier.undoAvailable,
            onTap: () {
              AudioManager().playSfx(SoundEffect.buttonClick);
              gameNotifier.undoLastMove();
            },
          ),
          
          // Hint button
          _buildControlButton(
            icon: Icons.lightbulb_outline,
            label: 'Hint',
            onTap: () {
              AudioManager().playSfx(SoundEffect.hint);
              _toggleHint(gameNotifier);
            },
          ),
          
          // Restart button
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Restart',
            onTap: () {
              AudioManager().playSfx(SoundEffect.buttonClick);
              _showRestartDialog(gameNotifier);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? Colors.white : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: enabled ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(GameEngine game, GameEngineNotifier gameNotifier) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Over!',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                'Final Score',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              
              Text(
                '${game.score}',
                style: GoogleFonts.poppins(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade600,
                ),
              ),
              
              if (game.score == game.bestScore) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'New High Score!',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 30),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AudioManager().playSfx(SoundEffect.buttonClick);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AudioManager().playSfx(SoundEffect.buttonClick);
                        gameNotifier.restartGame();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleHint(GameEngineNotifier gameNotifier) {
    setState(() {
      if (_showHint) {
        _showHint = false;
        _currentHint = null;
      } else {
        _currentHint = gameNotifier.getHint();
        _showHint = _currentHint != null;
      }
    });
  }

  void _showRestartDialog(GameEngineNotifier gameNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Restart Game?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to restart? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              gameNotifier.restartGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restart', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}