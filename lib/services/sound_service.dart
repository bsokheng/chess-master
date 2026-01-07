import 'package:audioplayers/audioplayers.dart';

/// Sound types for chess game
enum SoundType {
  move,
  capture,
  check,
  checkmate,
  castle,
  illegal,
  gameStart,
  gameEnd,
}

/// Service for playing sound effects
class SoundService {
  final Map<SoundType, AudioPlayer> _players = {};
  bool _enabled = true;
  double _volume = 1.0;

  bool get enabled => _enabled;
  double get volume => _volume;

  Future<void> init() async {
    // Initialize audio players for each sound type
    for (final type in SoundType.values) {
      _players[type] = AudioPlayer();
    }
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  Future<void> play(SoundType type) async {
    if (!_enabled) return;

    final player = _players[type];
    if (player == null) return;

    try {
      // Generate simple tones since we don't have actual audio files
      await player.setVolume(_volume);

      // Use built-in system sounds or generate tones
      // In a production app, you'd load actual audio files here
      switch (type) {
        case SoundType.move:
          await _playTone(player, 440, 100);
          break;
        case SoundType.capture:
          await _playTone(player, 330, 150);
          break;
        case SoundType.check:
          await _playTone(player, 660, 200);
          break;
        case SoundType.checkmate:
          await _playTone(player, 880, 500);
          break;
        case SoundType.castle:
          await _playTone(player, 550, 200);
          break;
        case SoundType.illegal:
          await _playTone(player, 220, 100);
          break;
        case SoundType.gameStart:
          await _playTone(player, 523, 300);
          break;
        case SoundType.gameEnd:
          await _playTone(player, 392, 400);
          break;
      }
    } catch (e) {
      // Silently handle audio errors
    }
  }

  Future<void> _playTone(AudioPlayer player, int frequency, int durationMs) async {
    // Note: In a real app, you'd use pre-recorded sound files
    // This is a placeholder - audioplayers requires actual audio sources
    try {
      // Try to use a URL-based tone generator or fallback silently
      // For production, add actual .wav or .mp3 files to assets/sounds/
    } catch (e) {
      // Audio not available
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
