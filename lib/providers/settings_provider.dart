import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/storage_service.dart';

/// Provider for managing application settings
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;

  // Settings with defaults
  bool _isDarkMode = false;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  bool _showLegalMoves = true;
  bool _showLastMove = true;
  bool _autoQueen = false;
  double _soundVolume = 1.0;
  AIDifficulty _difficulty = AIDifficulty.medium;
  BoardTheme _boardTheme = BoardTheme.classic;
  PlayerColor _playerColor = PlayerColor.white;
  bool _timerEnabled = false;
  int _timerMinutes = 10;

  SettingsProvider(this._storageService) {
    _loadSettings();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  bool get showLegalMoves => _showLegalMoves;
  bool get showLastMove => _showLastMove;
  bool get autoQueen => _autoQueen;
  double get soundVolume => _soundVolume;
  AIDifficulty get difficulty => _difficulty;
  BoardTheme get boardTheme => _boardTheme;
  PlayerColor get playerColor => _playerColor;
  bool get timerEnabled => _timerEnabled;
  int get timerMinutes => _timerMinutes;

  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSettings();

    _isDarkMode = settings['isDarkMode'] ?? false;
    _soundEnabled = settings['soundEnabled'] ?? true;
    _hapticEnabled = settings['hapticEnabled'] ?? true;
    _showLegalMoves = settings['showLegalMoves'] ?? true;
    _showLastMove = settings['showLastMove'] ?? true;
    _autoQueen = settings['autoQueen'] ?? false;
    _soundVolume = (settings['soundVolume'] ?? 1.0).toDouble();
    _difficulty = AIDifficulty.values[settings['difficulty'] ?? 1];
    _boardTheme = BoardTheme.values[settings['boardTheme'] ?? 0];
    _playerColor = PlayerColor.values[settings['playerColor'] ?? 0];
    _timerEnabled = settings['timerEnabled'] ?? false;
    _timerMinutes = settings['timerMinutes'] ?? 10;

    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _storageService.saveSetting('isDarkMode', _isDarkMode);
    await _storageService.saveSetting('soundEnabled', _soundEnabled);
    await _storageService.saveSetting('hapticEnabled', _hapticEnabled);
    await _storageService.saveSetting('showLegalMoves', _showLegalMoves);
    await _storageService.saveSetting('showLastMove', _showLastMove);
    await _storageService.saveSetting('autoQueen', _autoQueen);
    await _storageService.saveSetting('soundVolume', _soundVolume);
    await _storageService.saveSetting('difficulty', _difficulty.index);
    await _storageService.saveSetting('boardTheme', _boardTheme.index);
    await _storageService.saveSetting('playerColor', _playerColor.index);
    await _storageService.saveSetting('timerEnabled', _timerEnabled);
    await _storageService.saveSetting('timerMinutes', _timerMinutes);
  }

  // Setters
  void setDarkMode(bool value) {
    _isDarkMode = value;
    _saveSettings();
    notifyListeners();
  }

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setHapticEnabled(bool value) {
    _hapticEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowLegalMoves(bool value) {
    _showLegalMoves = value;
    _saveSettings();
    notifyListeners();
  }

  void setShowLastMove(bool value) {
    _showLastMove = value;
    _saveSettings();
    notifyListeners();
  }

  void setAutoQueen(bool value) {
    _autoQueen = value;
    _saveSettings();
    notifyListeners();
  }

  void setSoundVolume(double value) {
    _soundVolume = value.clamp(0.0, 1.0);
    _saveSettings();
    notifyListeners();
  }

  void setDifficulty(AIDifficulty value) {
    _difficulty = value;
    _saveSettings();
    notifyListeners();
  }

  void setBoardTheme(BoardTheme value) {
    _boardTheme = value;
    _saveSettings();
    notifyListeners();
  }

  void setPlayerColor(PlayerColor value) {
    _playerColor = value;
    _saveSettings();
    notifyListeners();
  }

  void setTimerEnabled(bool value) {
    _timerEnabled = value;
    _saveSettings();
    notifyListeners();
  }

  void setTimerMinutes(int value) {
    _timerMinutes = value.clamp(1, 60);
    _saveSettings();
    notifyListeners();
  }
}
