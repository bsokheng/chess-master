/// Application constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Chess Master';
  static const String appVersion = '1.0.0';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Board dimensions
  static const int boardSize = 8;
  static const int totalSquares = 64;

  // Timer defaults
  static const int defaultTimerMinutes = 10;
  static const int minTimerMinutes = 1;
  static const int maxTimerMinutes = 60;

  // AI configuration
  static const int aiMoveDelayMs = 100;
  static const int maxSearchDepth = 8;

  // Storage keys
  static const String gameStateKey = 'saved_game_state';
  static const String statisticsKey = 'player_statistics';
  static const String settingsKey = 'app_settings';
}

/// Chess notation helpers
class ChessNotation {
  ChessNotation._();

  static const List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const List<String> ranks = ['1', '2', '3', '4', '5', '6', '7', '8'];

  /// Convert file index (0-7) to letter (a-h)
  static String fileToLetter(int file) => files[file];

  /// Convert rank index (0-7) to number string (1-8)
  static String rankToNumber(int rank) => ranks[rank];

  /// Convert file letter to index
  static int letterToFile(String letter) => files.indexOf(letter.toLowerCase());

  /// Convert rank number to index
  static int numberToRank(String number) => ranks.indexOf(number);

  /// Get square name from file and rank indices
  static String getSquareName(int file, int rank) =>
      '${fileToLetter(file)}${rankToNumber(rank)}';

  /// Parse square name into file and rank indices
  static (int, int) parseSquare(String square) {
    final file = letterToFile(square[0]);
    final rank = numberToRank(square[1]);
    return (file, rank);
  }
}
