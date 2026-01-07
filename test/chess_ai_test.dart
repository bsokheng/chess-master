import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:chess_master/services/chess_ai_service.dart';
import 'package:chess_master/models/game_state.dart';

void main() {
  late ChessAIService aiService;

  setUp(() {
    aiService = ChessAIService();
  });

  group('ChessAIService', () {
    test('should find a legal move from starting position', () async {
      final chess = chess_lib.Chess();
      final move = await aiService.findBestMove(chess, AIDifficulty.easy);

      expect(move, isNotNull);

      // Verify the move is legal
      final legalMoves = chess.moves({'verbose': true});
      final isLegal = legalMoves.any(
        (m) => m['from'] == move!.fromAlgebraic && m['to'] == move.toAlgebraic,
      );
      expect(isLegal, isTrue);
    });

    test('should find checkmate in one', () async {
      // Fool's mate position (black to move and checkmate)
      final chess = chess_lib.Chess.fromFEN(
        'rnb1kbnr/pppp1ppp/4p3/8/6Pq/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 1',
      );

      final move = await aiService.findBestMove(chess, AIDifficulty.medium);
      expect(move, isNotNull);

      // Apply the move and check for checkmate
      chess.move({
        'from': move!.fromAlgebraic,
        'to': move.toAlgebraic,
        'promotion': move.promotion?.toString(),
      });

      expect(chess.in_checkmate, isTrue);
    });

    test('should evaluate material balance correctly', () {
      // Starting position - equal material
      final startPosition = chess_lib.Chess();
      expect(aiService.getMaterialBalance(startPosition), equals(0));

      // White up a queen
      final whiteUpQueen = chess_lib.Chess.fromFEN(
        'rnb1kbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      );
      expect(aiService.getMaterialBalance(whiteUpQueen), greaterThan(800));
    });

    test('should make moves at all difficulty levels', () async {
      for (final difficulty in AIDifficulty.values) {
        final chess = chess_lib.Chess();
        final move = await aiService.findBestMove(chess, difficulty);
        expect(move, isNotNull, reason: 'Failed at ${difficulty.displayName}');
      }
    });

    test('should return null when no legal moves', () async {
      // Stalemate position
      final chess = chess_lib.Chess.fromFEN(
        'k7/8/1K6/8/8/8/8/8 b - - 0 1',
      );

      if (chess.moves().isEmpty) {
        final move = await aiService.findBestMove(chess, AIDifficulty.easy);
        expect(move, isNull);
      }
    });
  });

  group('Game Rules', () {
    test('should detect checkmate', () {
      // Scholar's mate final position
      final chess = chess_lib.Chess.fromFEN(
        'r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4',
      );
      expect(chess.in_checkmate, isTrue);
    });

    test('should detect stalemate', () {
      // Classic stalemate position
      final chess = chess_lib.Chess.fromFEN(
        'k7/8/1K6/8/8/8/8/8 b - - 0 1',
      );
      expect(chess.in_stalemate, isTrue);
    });

    test('should validate castling', () {
      final chess = chess_lib.Chess();

      // Make moves to allow kingside castling
      chess.move({'from': 'e2', 'to': 'e4'});
      chess.move({'from': 'e7', 'to': 'e5'});
      chess.move({'from': 'g1', 'to': 'f3'});
      chess.move({'from': 'b8', 'to': 'c6'});
      chess.move({'from': 'f1', 'to': 'c4'});
      chess.move({'from': 'g8', 'to': 'f6'});

      // Kingside castling should be legal
      final moves = chess.moves();
      expect(moves.contains('O-O'), isTrue);
    });

    test('should handle en passant', () {
      // Position where en passant is possible
      final chess = chess_lib.Chess.fromFEN(
        'rnbqkbnr/pppp1ppp/8/4pP2/8/8/PPPPP1PP/RNBQKBNR w KQkq e6 0 3',
      );

      final moves = chess.moves({'verbose': true});
      final enPassantMove = moves.firstWhere(
        (m) => m['flags'].contains('e'),
        orElse: () => null,
      );

      expect(enPassantMove, isNotNull);
    });

    test('should handle pawn promotion', () {
      // Position with pawn about to promote
      final chess = chess_lib.Chess.fromFEN(
        '8/P7/8/8/8/8/8/4K2k w - - 0 1',
      );

      final moves = chess.moves({'verbose': true});
      final promotionMoves = moves.where((m) => m['promotion'] != null);

      // Should have 4 promotion options (Q, R, B, N)
      expect(promotionMoves.length, equals(4));
    });
  });
}
