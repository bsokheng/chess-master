import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import '../models/game_state.dart';

/// Chess AI Service using Minimax algorithm with Alpha-Beta Pruning
///
/// The AI evaluates positions based on:
/// 1. Material value (piece values)
/// 2. Piece-square tables (positional bonuses)
/// 3. Basic tactical evaluation (checks, captures)
///
/// Alpha-beta pruning significantly reduces the search space by eliminating
/// branches that cannot affect the final decision.
class ChessAIService {
  // Standard piece values in centipawns
  static final Map<chess_lib.PieceType, int> _pieceValues = {
    chess_lib.PieceType.PAWN: 100,
    chess_lib.PieceType.KNIGHT: 320,
    chess_lib.PieceType.BISHOP: 330,
    chess_lib.PieceType.ROOK: 500,
    chess_lib.PieceType.QUEEN: 900,
    chess_lib.PieceType.KING: 20000,
  };

  // Piece-square tables for positional evaluation
  // Values are from white's perspective (flipped for black)

  // Pawns should advance and control the center
  static const List<List<int>> _pawnTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5,  5, 10, 25, 25, 10,  5,  5],
    [0,  0,  0, 20, 20,  0,  0,  0],
    [5, -5,-10,  0,  0,-10, -5,  5],
    [5, 10, 10,-20,-20, 10, 10,  5],
    [0,  0,  0,  0,  0,  0,  0,  0],
  ];

  // Knights are best in the center
  static const List<List<int>> _knightTable = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];

  // Bishops like long diagonals
  static const List<List<int>> _bishopTable = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];

  // Rooks like open files and 7th rank
  static const List<List<int>> _rookTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [0,  0,  0,  5,  5,  0,  0,  0],
  ];

  // Queen combines rook and bishop
  static const List<List<int>> _queenTable = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [-5,  0,  5,  5,  5,  5,  0, -5],
    [0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20],
  ];

  // King in middlegame should stay safe (castled)
  static const List<List<int>> _kingMiddleGameTable = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [20, 20,  0,  0,  0,  0, 20, 20],
    [20, 30, 10,  0,  0, 10, 30, 20],
  ];

  // King in endgame should be active
  static const List<List<int>> _kingEndGameTable = [
    [-50,-40,-30,-20,-20,-30,-40,-50],
    [-30,-20,-10,  0,  0,-10,-20,-30],
    [-30,-10, 20, 30, 30, 20,-10,-30],
    [-30,-10, 30, 40, 40, 30,-10,-30],
    [-30,-10, 30, 40, 40, 30,-10,-30],
    [-30,-10, 20, 30, 30, 20,-10,-30],
    [-30,-30,  0,  0,  0,  0,-30,-30],
    [-50,-30,-30,-30,-30,-30,-30,-50],
  ];

  final Random _random = Random();

  /// Find the best move for the AI using minimax with alpha-beta pruning
  ///
  /// [chess] - Current chess game state
  /// [difficulty] - AI difficulty determining search depth
  /// Returns the best move info as a Map
  Future<Map<String, dynamic>?> findBestMoveInfo(
    chess_lib.Chess chess,
    AIDifficulty difficulty,
  ) async {
    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) return null;

    // Create a copy of the chess object for search to avoid modifying the original
    final searchChess = chess_lib.Chess.fromFEN(chess.fen);

    // Create a proper list copy to avoid cast issues
    final movesList = List<Map<String, dynamic>>.from(
      moves.map((m) => Map<String, dynamic>.from(m as Map)),
    );

    // Easy mode: mostly random moves (beatable by beginners)
    if (difficulty == AIDifficulty.easy) {
      // 80% chance of random move for Easy - very beatable
      if (_random.nextDouble() < 0.8) {
        return movesList[_random.nextInt(movesList.length)];
      }
    }

    // Medium mode: 50% random moves
    if (difficulty == AIDifficulty.medium) {
      if (_random.nextDouble() < 0.5) {
        // Prefer captures when making random moves (slightly smarter)
        final captures = movesList.where((m) => m['captured'] != null).toList();
        if (captures.isNotEmpty && _random.nextDouble() < 0.6) {
          return captures[_random.nextInt(captures.length)];
        }
        return movesList[_random.nextInt(movesList.length)];
      }
    }

    // Hard mode: 20% random moves
    if (difficulty == AIDifficulty.hard) {
      if (_random.nextDouble() < 0.2) {
        return movesList[_random.nextInt(movesList.length)];
      }
    }

    // Expert mode: no random moves, pure minimax

    Map<String, dynamic>? bestMove = movesList.first;
    int bestValue = -100000;
    final int depth = difficulty.depth;

    // Shuffle moves to add variety when multiple moves have equal value
    movesList.shuffle(_random);

    // Sort moves for better alpha-beta pruning (captures first)
    _orderMoves(searchChess, movesList);

    for (final move in movesList) {
      final moveSuccess = searchChess.move(move);
      if (moveSuccess == false) continue;

      // Minimax with alpha-beta pruning
      final value = -_minimax(
        searchChess,
        depth - 1,
        -100000,
        100000,
        false,
      );

      searchChess.undo();

      if (value > bestValue) {
        bestValue = value;
        bestMove = move;
      }
    }

    return bestMove;
  }

  /// Minimax algorithm with alpha-beta pruning
  ///
  /// [chess] - Current position
  /// [depth] - Remaining search depth
  /// [alpha] - Best value the maximizer can guarantee
  /// [beta] - Best value the minimizer can guarantee
  /// [isMaximizing] - True if maximizing player's turn
  ///
  /// Alpha-beta pruning works by maintaining a window [alpha, beta].
  /// If we find a move that's worse than what we already have, we can prune.
  int _minimax(
    chess_lib.Chess chess,
    int depth,
    int alpha,
    int beta,
    bool isMaximizing,
  ) {
    // Terminal conditions - just evaluate, no quiescence search for speed
    if (depth == 0) {
      return _evaluatePosition(chess);
    }

    if (chess.in_checkmate) {
      return isMaximizing ? -50000 + depth : 50000 - depth;
    }

    if (chess.in_stalemate || chess.in_draw) {
      return 0;
    }

    final moves = chess.moves({'verbose': true});
    _orderMoves(chess, moves);

    if (isMaximizing) {
      int maxEval = -100000;

      for (final move in moves) {
        chess.move(move);
        final eval = _minimax(chess, depth - 1, alpha, beta, false);
        chess.undo();

        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);

        // Beta cutoff - opponent wouldn't allow this line
        if (beta <= alpha) break;
      }

      return maxEval;
    } else {
      int minEval = 100000;

      for (final move in moves) {
        chess.move(move);
        final eval = _minimax(chess, depth - 1, alpha, beta, true);
        chess.undo();

        minEval = min(minEval, eval);
        beta = min(beta, eval);

        // Alpha cutoff
        if (beta <= alpha) break;
      }

      return minEval;
    }
  }

  /// Quiescence search to avoid horizon effect
  ///
  /// Continues searching capture sequences to avoid evaluating
  /// in the middle of tactical exchanges
  int _quiescenceSearch(
    chess_lib.Chess chess,
    int alpha,
    int beta,
    int depth,
  ) {
    final standPat = _evaluatePosition(chess);

    if (depth == 0) return standPat;

    if (standPat >= beta) return beta;
    if (alpha < standPat) alpha = standPat;

    final moves = chess.moves({'verbose': true});

    // Only search captures
    final captures = moves.where((m) => m['captured'] != null).toList();
    _orderMoves(chess, captures);

    for (final move in captures) {
      chess.move(move);
      final score = -_quiescenceSearch(chess, -beta, -alpha, depth - 1);
      chess.undo();

      if (score >= beta) return beta;
      if (score > alpha) alpha = score;
    }

    return alpha;
  }

  /// Order moves for better alpha-beta pruning efficiency
  ///
  /// Prioritizes: captures (MVV-LVA), checks, center moves
  void _orderMoves(chess_lib.Chess chess, List<dynamic> moves) {
    moves.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      // Captures (Most Valuable Victim - Least Valuable Attacker)
      if (a['captured'] != null) {
        scoreA += 10 * _getPieceValue(a['captured']) - _getPieceValue(a['piece']);
      }
      if (b['captured'] != null) {
        scoreB += 10 * _getPieceValue(b['captured']) - _getPieceValue(b['piece']);
      }

      // Promotions
      if (a['promotion'] != null) scoreA += 900;
      if (b['promotion'] != null) scoreB += 900;

      // Checks (approximate by looking at queen/rook moves to back rank)
      if (a['san'].endsWith('+')) scoreA += 50;
      if (b['san'].endsWith('+')) scoreB += 50;

      return scoreB - scoreA;
    });
  }

  /// Get numeric piece value from piece (handles both String and PieceType)
  int _getPieceValue(dynamic piece) {
    if (piece == null) return 0;

    // Handle PieceType enum directly
    if (piece is chess_lib.PieceType) {
      return _pieceValues[piece] ?? 0;
    }

    // Handle String representation
    final str = piece.toString().toLowerCase();
    if (str.contains('pawn') || str == 'p') return 100;
    if (str.contains('knight') || str == 'n') return 320;
    if (str.contains('bishop') || str == 'b') return 330;
    if (str.contains('rook') || str == 'r') return 500;
    if (str.contains('queen') || str == 'q') return 900;
    if (str.contains('king') || str == 'k') return 20000;

    return 0;
  }

  /// Evaluate the current position
  ///
  /// Positive values favor white, negative favor black
  int _evaluatePosition(chess_lib.Chess chess) {
    if (chess.in_checkmate) {
      return chess.turn == chess_lib.Color.WHITE ? -50000 : 50000;
    }

    if (chess.in_stalemate || chess.in_draw) {
      return 0;
    }

    int score = 0;
    final bool isEndgame = _isEndgame(chess);

    // Evaluate each square
    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final square = _getSquareName(file, rank);
        final piece = chess.get(square);

        if (piece != null) {
          int pieceScore = _pieceValues[piece.type] ?? 0;
          pieceScore += _getPieceSquareValue(piece, file, rank, isEndgame);

          if (piece.color == chess_lib.Color.WHITE) {
            score += pieceScore;
          } else {
            score -= pieceScore;
          }
        }
      }
    }

    // Add mobility bonus
    final moves = chess.moves();
    score += chess.turn == chess_lib.Color.WHITE ? moves.length * 2 : -moves.length * 2;

    // Check bonus
    if (chess.in_check) {
      score += chess.turn == chess_lib.Color.WHITE ? -30 : 30;
    }

    return score;
  }

  /// Get the positional value for a piece on a given square
  int _getPieceSquareValue(
    chess_lib.Piece piece,
    int file,
    int rank,
    bool isEndgame,
  ) {
    // Flip rank for black pieces
    final tableRank = piece.color == chess_lib.Color.WHITE ? rank : 7 - rank;

    switch (piece.type) {
      case chess_lib.PieceType.PAWN:
        return _pawnTable[tableRank][file];
      case chess_lib.PieceType.KNIGHT:
        return _knightTable[tableRank][file];
      case chess_lib.PieceType.BISHOP:
        return _bishopTable[tableRank][file];
      case chess_lib.PieceType.ROOK:
        return _rookTable[tableRank][file];
      case chess_lib.PieceType.QUEEN:
        return _queenTable[tableRank][file];
      case chess_lib.PieceType.KING:
        return isEndgame
            ? _kingEndGameTable[tableRank][file]
            : _kingMiddleGameTable[tableRank][file];
      default:
        return 0;
    }
  }

  /// Determine if the position is in the endgame phase
  bool _isEndgame(chess_lib.Chess chess) {
    int totalMaterial = 0;

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = chess.get(_getSquareName(file, rank));
        if (piece != null && piece.type != chess_lib.PieceType.KING) {
          totalMaterial += _pieceValues[piece.type] ?? 0;
        }
      }
    }

    // Endgame if total material (excluding kings) < ~2600
    // (roughly queen + rook or less per side)
    return totalMaterial < 2600;
  }

  /// Convert file and rank indices to square name
  String _getSquareName(int file, int rank) {
    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${8 - rank}';
  }

  /// Get a move hint for the player
  Future<Map<String, dynamic>?> getHintInfo(chess_lib.Chess chess) async {
    return findBestMoveInfo(chess, AIDifficulty.medium);
  }

  /// Evaluate material balance
  ///
  /// Returns the material difference in centipawns
  /// Positive = white advantage, Negative = black advantage
  int getMaterialBalance(chess_lib.Chess chess) {
    int balance = 0;

    for (int rank = 0; rank < 8; rank++) {
      for (int file = 0; file < 8; file++) {
        final piece = chess.get(_getSquareName(file, rank));
        if (piece != null && piece.type != chess_lib.PieceType.KING) {
          final value = _pieceValues[piece.type] ?? 0;
          balance += piece.color == chess_lib.Color.WHITE ? value : -value;
        }
      }
    }

    return balance;
  }
}
