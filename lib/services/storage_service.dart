import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/statistics.dart';

/// Service for persisting game data using SharedPreferences
class StorageService {
  static const String _gameStateKey = 'saved_game_state';
  static const String _statisticsKey = 'player_statistics';
  static const String _settingsKey = 'app_settings';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Game State persistence
  Future<void> saveGameState(GameState state) async {
    final json = jsonEncode(state.toJson());
    await _prefs.setString(_gameStateKey, json);
  }

  Future<GameState?> loadGameState() async {
    final json = _prefs.getString(_gameStateKey);
    if (json == null) return null;
    try {
      return GameState.fromJson(jsonDecode(json));
    } catch (e) {
      // If saved state is corrupted, delete it
      await clearGameState();
      return null;
    }
  }

  Future<void> clearGameState() async {
    await _prefs.remove(_gameStateKey);
  }

  bool hasSavedGame() {
    return _prefs.containsKey(_gameStateKey);
  }

  // Statistics persistence
  Future<void> saveStatistics(Statistics stats) async {
    final json = jsonEncode(stats.toJson());
    await _prefs.setString(_statisticsKey, json);
  }

  Future<Statistics> loadStatistics() async {
    final json = _prefs.getString(_statisticsKey);
    if (json == null) return Statistics();
    try {
      return Statistics.fromJson(jsonDecode(json));
    } catch (e) {
      return Statistics();
    }
  }

  // Settings persistence
  Future<void> saveSetting(String key, dynamic value) async {
    final settings = await loadSettings();
    settings[key] = value;
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final json = _prefs.getString(_settingsKey);
    if (json == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (e) {
      return {};
    }
  }

  Future<T?> getSetting<T>(String key) async {
    final settings = await loadSettings();
    return settings[key] as T?;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
