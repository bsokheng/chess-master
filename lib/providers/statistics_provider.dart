import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../models/statistics.dart';
import '../services/storage_service.dart';

/// Provider for managing player statistics
class StatisticsProvider extends ChangeNotifier {
  final StorageService _storageService;
  Statistics _statistics = Statistics();

  StatisticsProvider(this._storageService) {
    _loadStatistics();
  }

  Statistics get statistics => _statistics;

  Future<void> _loadStatistics() async {
    _statistics = await _storageService.loadStatistics();
    notifyListeners();
  }

  Future<void> _saveStatistics() async {
    await _storageService.saveStatistics(_statistics);
  }

  /// Record a game result
  Future<void> recordGame({
    required GameResult result,
    required PlayerColor playerColor,
    required AIDifficulty difficulty,
    required int moveCount,
  }) async {
    final isWin = (result == GameResult.whiteWins && playerColor == PlayerColor.white) ||
        (result == GameResult.blackWins && playerColor == PlayerColor.black);
    final isLoss = (result == GameResult.whiteWins && playerColor == PlayerColor.black) ||
        (result == GameResult.blackWins && playerColor == PlayerColor.white);
    final isDraw = result == GameResult.draw || result == GameResult.stalemate;

    int newWins = _statistics.wins;
    int newLosses = _statistics.losses;
    int newDraws = _statistics.draws;
    int newWinsAsWhite = _statistics.winsAsWhite;
    int newWinsAsBlack = _statistics.winsAsBlack;
    int newCurrentStreak = _statistics.currentWinStreak;
    int newLongestStreak = _statistics.longestWinStreak;
    Map<String, int> newWinsPerDifficulty = Map.from(_statistics.winsPerDifficulty);

    if (isWin) {
      newWins++;
      newCurrentStreak++;
      if (newCurrentStreak > newLongestStreak) {
        newLongestStreak = newCurrentStreak;
      }
      if (playerColor == PlayerColor.white) {
        newWinsAsWhite++;
      } else {
        newWinsAsBlack++;
      }
      final diffKey = difficulty.displayName.toLowerCase();
      newWinsPerDifficulty[diffKey] = (newWinsPerDifficulty[diffKey] ?? 0) + 1;
    } else if (isLoss) {
      newLosses++;
      newCurrentStreak = 0;
    } else if (isDraw) {
      newDraws++;
      // Don't reset streak on draw
    }

    _statistics = _statistics.copyWith(
      gamesPlayed: _statistics.gamesPlayed + 1,
      wins: newWins,
      losses: newLosses,
      draws: newDraws,
      winsAsWhite: newWinsAsWhite,
      winsAsBlack: newWinsAsBlack,
      totalMovesPlayed: _statistics.totalMovesPlayed + moveCount,
      longestWinStreak: newLongestStreak,
      currentWinStreak: newCurrentStreak,
      winsPerDifficulty: newWinsPerDifficulty,
      lastPlayed: DateTime.now(),
    );

    await _saveStatistics();
    notifyListeners();
  }

  /// Reset all statistics
  Future<void> resetStatistics() async {
    _statistics = Statistics();
    await _saveStatistics();
    notifyListeners();
  }
}
