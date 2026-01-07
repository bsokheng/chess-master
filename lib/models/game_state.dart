import 'package:chess/chess.dart' as chess_lib;

/// Represents a single move in the game
class ChessMove {
  final String from;
  final String to;
  final String? promotion;
  final String algebraicNotation;
  final String? capturedPiece;
  final bool isCheck;
  final bool isCheckmate;
  final bool isCastling;
  final bool isEnPassant;

  ChessMove({
    required this.from,
    required this.to,
    this.promotion,
    required this.algebraicNotation,
    this.capturedPiece,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isCastling = false,
    this.isEnPassant = false,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'promotion': promotion,
    'algebraicNotation': algebraicNotation,
    'capturedPiece': capturedPiece,
    'isCheck': isCheck,
    'isCheckmate': isCheckmate,
    'isCastling': isCastling,
    'isEnPassant': isEnPassant,
  };

  factory ChessMove.fromJson(Map<String, dynamic> json) => ChessMove(
    from: json['from'],
    to: json['to'],
    promotion: json['promotion'],
    algebraicNotation: json['algebraicNotation'],
    capturedPiece: json['capturedPiece'],
    isCheck: json['isCheck'] ?? false,
    isCheckmate: json['isCheckmate'] ?? false,
    isCastling: json['isCastling'] ?? false,
    isEnPassant: json['isEnPassant'] ?? false,
  );
}

/// Game result enumeration
enum GameResult {
  ongoing,
  whiteWins,
  blackWins,
  draw,
  stalemate,
}

/// AI difficulty levels
enum AIDifficulty {
  easy(2, 'Easy'),
  medium(4, 'Medium'),
  hard(6, 'Hard');

  final int depth;
  final String displayName;

  const AIDifficulty(this.depth, this.displayName);
}

/// Player color enumeration
enum PlayerColor {
  white,
  black;

  chess_lib.Color get chessColor =>
      this == PlayerColor.white ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;

  PlayerColor get opposite =>
      this == PlayerColor.white ? PlayerColor.black : PlayerColor.white;
}

/// Board theme options
enum BoardTheme {
  classic('Classic', 0xFFF0D9B5, 0xFFB58863),
  blue('Blue', 0xFFDEE3E6, 0xFF8CA2AD),
  green('Green', 0xFFEEEED2, 0xFF769656),
  purple('Purple', 0xFFE8E0F0, 0xFF9070A0),
  wood('Wood', 0xFFE8C999, 0xFFAD7F4F);

  final String displayName;
  final int lightSquare;
  final int darkSquare;

  const BoardTheme(this.displayName, this.lightSquare, this.darkSquare);
}

/// Complete game state for persistence
class GameState {
  final String fen;
  final List<ChessMove> moveHistory;
  final PlayerColor playerColor;
  final AIDifficulty difficulty;
  final GameResult result;
  final DateTime startTime;
  final int whiteTimeSeconds;
  final int blackTimeSeconds;

  GameState({
    required this.fen,
    required this.moveHistory,
    required this.playerColor,
    required this.difficulty,
    required this.result,
    required this.startTime,
    this.whiteTimeSeconds = 600,
    this.blackTimeSeconds = 600,
  });

  Map<String, dynamic> toJson() => {
    'fen': fen,
    'moveHistory': moveHistory.map((m) => m.toJson()).toList(),
    'playerColor': playerColor.index,
    'difficulty': difficulty.index,
    'result': result.index,
    'startTime': startTime.toIso8601String(),
    'whiteTimeSeconds': whiteTimeSeconds,
    'blackTimeSeconds': blackTimeSeconds,
  };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
    fen: json['fen'],
    moveHistory: (json['moveHistory'] as List)
        .map((m) => ChessMove.fromJson(m))
        .toList(),
    playerColor: PlayerColor.values[json['playerColor']],
    difficulty: AIDifficulty.values[json['difficulty']],
    result: GameResult.values[json['result']],
    startTime: DateTime.parse(json['startTime']),
    whiteTimeSeconds: json['whiteTimeSeconds'] ?? 600,
    blackTimeSeconds: json['blackTimeSeconds'] ?? 600,
  );
}
