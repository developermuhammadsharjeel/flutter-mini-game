// lib/utils/audio_manager.dart
// Audio management for Block Blast game

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages all audio/sound effects for the game
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  late AudioPlayer _sfxPlayer;
  late AudioPlayer _musicPlayer;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _initialized = false;

  /// Initialize the audio manager
  Future<void> initialize() async {
    if (_initialized) return;

    _sfxPlayer = AudioPlayer();
    _musicPlayer = AudioPlayer();
    
    // Load sound preferences
    await _loadPreferences();
    
    _initialized = true;
  }

  /// Load audio preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _musicEnabled = prefs.getBool('music_enabled') ?? true;
    } catch (e) {
      print('Error loading audio preferences: $e');
      _soundEnabled = true;
      _musicEnabled = true;
    }
  }

  /// Save audio preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sound_enabled', _soundEnabled);
      await prefs.setBool('music_enabled', _musicEnabled);
    } catch (e) {
      print('Error saving audio preferences: $e');
    }
  }

  /// Play a sound effect
  Future<void> playSfx(SoundEffect effect) async {
    if (!_initialized || !_soundEnabled) return;

    try {
      final soundFile = _getSoundFile(effect);
      if (soundFile.isNotEmpty) {
        await _sfxPlayer.play(AssetSource('sfx/$soundFile'));
      }
    } catch (e) {
      print('Error playing sound effect: $e');
    }
  }

  /// Play background music
  Future<void> playMusic(String musicFile) async {
    if (!_initialized || !_musicEnabled) return;

    try {
      await _musicPlayer.play(AssetSource('sfx/$musicFile'));
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    if (!_initialized) return;
    
    try {
      await _musicPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  /// Toggle sound effects on/off
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _savePreferences();
  }

  /// Toggle background music on/off
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    await _savePreferences();
    
    if (!_musicEnabled) {
      await stopMusic();
    }
  }

  /// Set sound effects volume
  Future<void> setSfxVolume(double volume) async {
    if (!_initialized) return;
    
    try {
      await _sfxPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting SFX volume: $e');
    }
  }

  /// Set music volume
  Future<void> setMusicVolume(double volume) async {
    if (!_initialized) return;
    
    try {
      await _musicPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Error setting music volume: $e');
    }
  }

  /// Get the sound file name for a sound effect
  String _getSoundFile(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.placePiece:
        return 'place_piece.mp3';
      case SoundEffect.clearLine:
        return 'clear_line.mp3';
      case SoundEffect.clearCombo:
        return 'clear_combo.mp3';
      case SoundEffect.gameOver:
        return 'game_over.mp3';
      case SoundEffect.buttonClick:
        return 'button_click.mp3';
      case SoundEffect.invalidMove:
        return 'invalid_move.mp3';
      case SoundEffect.newHighScore:
        return 'new_high_score.mp3';
      case SoundEffect.hint:
        return 'hint.mp3';
      default:
        return '';
    }
  }

  /// Dispose of audio resources
  Future<void> dispose() async {
    if (!_initialized) return;
    
    try {
      await _sfxPlayer.dispose();
      await _musicPlayer.dispose();
    } catch (e) {
      print('Error disposing audio players: $e');
    }
    
    _initialized = false;
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get isInitialized => _initialized;
}

/// Available sound effects
enum SoundEffect {
  placePiece,
  clearLine,
  clearCombo,
  gameOver,
  buttonClick,
  invalidMove,
  newHighScore,
  hint,
}

/// Placeholder sound files for development
/// TODO: Replace with actual sound assets
class SoundAssets {
  static const String buttonClick = 'assets/sfx/button_click.mp3';
  static const String placePiece = 'assets/sfx/place_piece.mp3';
  static const String clearLine = 'assets/sfx/clear_line.mp3';
  static const String clearCombo = 'assets/sfx/clear_combo.mp3';
  static const String gameOver = 'assets/sfx/game_over.mp3';
  static const String invalidMove = 'assets/sfx/invalid_move.mp3';
  static const String newHighScore = 'assets/sfx/new_high_score.mp3';
  static const String hint = 'assets/sfx/hint.mp3';
  static const String backgroundMusic = 'assets/sfx/background_music.mp3';
}