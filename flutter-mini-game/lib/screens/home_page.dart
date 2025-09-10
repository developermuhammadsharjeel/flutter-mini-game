// lib/screens/home_page.dart
// Modern home screen for Block Blast game

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_page.dart';
import '../utils/audio_manager.dart';

/// Provider for high score
final highScoreProvider = FutureProvider<int>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('high_score') ?? 0;
  } catch (e) {
    return 0;
  }
});

/// Provider for settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, GameSettings>((ref) {
  return SettingsNotifier();
});

/// Settings model
class GameSettings {
  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticEnabled;
  final String theme;

  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticEnabled = true,
    this.theme = 'default',
  });

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticEnabled,
    String? theme,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      theme: theme ?? this.theme,
    );
  }
}

/// Settings state notifier
class SettingsNotifier extends StateNotifier<GameSettings> {
  SettingsNotifier() : super(const GameSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = GameSettings(
        soundEnabled: prefs.getBool('sound_enabled') ?? true,
        musicEnabled: prefs.getBool('music_enabled') ?? true,
        hapticEnabled: prefs.getBool('haptic_enabled') ?? true,
        theme: prefs.getString('theme') ?? 'default',
      );
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', state.soundEnabled);
      await prefs.setBool('music_enabled', state.musicEnabled);
      await prefs.setBool('haptic_enabled', state.hapticEnabled);
      await prefs.setString('theme', state.theme);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
    AudioManager().toggleSound();
    _saveSettings();
  }

  void toggleMusic() {
    state = state.copyWith(musicEnabled: !state.musicEnabled);
    AudioManager().toggleMusic();
    _saveSettings();
  }

  void toggleHaptic() {
    state = state.copyWith(hapticEnabled: !state.hapticEnabled);
    _saveSettings();
  }
}

/// Modern home page with animations and settings
class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highScore = ref.watch(highScoreProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade900,
              Colors.purple.shade700,
              Colors.pink.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Game Title
              Hero(
                tag: 'game_title',
                child: Text(
                  'Block Blast',
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 4),
                        blurRadius: 8,
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              
              Text(
                'Enhanced Edition',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 60),

              // TODO: Add Lottie animation here
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.extension,
                    size: 80,
                    color: Colors.white70,
                  ),
                ),
              ),

              const Spacer(),

              // High Score Display
              highScore.when(
                data: (score) => _buildHighScoreCard(score),
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (_, __) => _buildHighScoreCard(0),
              ),

              const SizedBox(height: 30),

              // Main Buttons
              _buildMainButtons(context, ref),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighScoreCard(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Best Score: ${score.toString().padLeft(6, '0')}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Play Button
        SizedBox(
          width: 200,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () async {
              await AudioManager().playSfx(SoundEffect.buttonClick);
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const GamePage(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            icon: const Icon(Icons.play_arrow, size: 28),
            label: Text(
              'PLAY',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.green.shade900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Settings Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSettingsButton(
              icon: ref.watch(settingsProvider).soundEnabled ? Icons.volume_up : Icons.volume_off,
              onTap: () {
                AudioManager().playSfx(SoundEffect.buttonClick);
                ref.read(settingsProvider.notifier).toggleSound();
              },
            ),
            _buildSettingsButton(
              icon: ref.watch(settingsProvider).musicEnabled ? Icons.music_note : Icons.music_off,
              onTap: () {
                AudioManager().playSfx(SoundEffect.buttonClick);
                ref.read(settingsProvider.notifier).toggleMusic();
              },
            ),
            _buildSettingsButton(
              icon: Icons.info_outline,
              onTap: () {
                AudioManager().playSfx(SoundEffect.buttonClick);
                _showInfoDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Block Blast - Enhanced',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'How to Play:\n\n'
          '• Drag pieces from the bottom to the 8x8 grid\n'
          '• Complete rows or columns to clear them\n'
          '• Game ends when no pieces can be placed\n'
          '• Try to get the highest score possible!\n\n'
          'Features:\n'
          '• Enhanced graphics and animations\n'
          '• Sound effects and music\n'
          '• Smooth gameplay experience',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}