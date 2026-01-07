import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../models/game_state.dart';

/// Main chess board widget with piece rendering and interaction
class ChessBoardWidget extends StatelessWidget {
  const ChessBoardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, game, settings, child) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: _buildBoard(context, game, settings),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard(
    BuildContext context,
    GameProvider game,
    SettingsProvider settings,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final squareSize = constraints.maxWidth / 8;

        return Stack(
          children: [
            // Board squares
            Column(
              children: List.generate(8, (rank) {
                final displayRank = game.isBoardFlipped ? rank : 7 - rank;
                return Row(
                  children: List.generate(8, (file) {
                    final displayFile = game.isBoardFlipped ? 7 - file : file;
                    final square = _getSquareName(displayFile, displayRank);
                    final isLight = (displayFile + displayRank) % 2 == 1;

                    return _SquareWidget(
                      square: square,
                      isLight: isLight,
                      size: squareSize,
                      boardTheme: settings.boardTheme,
                      isSelected: game.selectedSquare == square,
                      isLegalMove: settings.showLegalMoves &&
                          game.legalMoves.contains(square),
                      isLastMoveFrom: settings.showLastMove &&
                          game.lastMoveFrom == square,
                      isLastMoveTo: settings.showLastMove &&
                          game.lastMoveTo == square,
                      isHintFrom: game.hintFrom == square,
                      isHintTo: game.hintTo == square,
                      isCheck: _isKingInCheck(game, square),
                      onTap: () => game.onSquareTap(square),
                      piece: game.chess.get(square),
                      showCoordinates: file == 0 || rank == 7,
                      rankLabel: file == 0 ? '${displayRank + 1}' : null,
                      fileLabel: rank == 7 ? String.fromCharCode('a'.codeUnitAt(0) + displayFile) : null,
                    );
                  }),
                );
              }),
            ),

            // Promotion dialog overlay
            if (game.hasPendingPromotion)
              _PromotionDialog(
                isWhite: game.chess.turn == chess_lib.Color.WHITE,
                squareSize: squareSize,
                onSelect: game.completePromotion,
                onCancel: game.cancelPromotion,
              ),

            // AI thinking indicator
            if (game.isAIThinking)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                  child: const Center(
                    child: _ThinkingIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getSquareName(int file, int rank) {
    return '${String.fromCharCode('a'.codeUnitAt(0) + file)}${rank + 1}';
  }

  bool _isKingInCheck(GameProvider game, String square) {
    if (!game.isInCheck) return false;
    final piece = game.chess.get(square);
    if (piece == null) return false;
    return piece.type == chess_lib.PieceType.KING &&
        piece.color == game.chess.turn;
  }
}

/// Individual square widget
class _SquareWidget extends StatelessWidget {
  final String square;
  final bool isLight;
  final double size;
  final BoardTheme boardTheme;
  final bool isSelected;
  final bool isLegalMove;
  final bool isLastMoveFrom;
  final bool isLastMoveTo;
  final bool isHintFrom;
  final bool isHintTo;
  final bool isCheck;
  final VoidCallback onTap;
  final chess_lib.Piece? piece;
  final bool showCoordinates;
  final String? rankLabel;
  final String? fileLabel;

  const _SquareWidget({
    required this.square,
    required this.isLight,
    required this.size,
    required this.boardTheme,
    required this.isSelected,
    required this.isLegalMove,
    required this.isLastMoveFrom,
    required this.isLastMoveTo,
    required this.isHintFrom,
    required this.isHintTo,
    required this.isCheck,
    required this.onTap,
    required this.piece,
    required this.showCoordinates,
    this.rankLabel,
    this.fileLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isLight
        ? Color(boardTheme.lightSquare)
        : Color(boardTheme.darkSquare);

    // Highlight colors
    if (isSelected) {
      backgroundColor = Colors.yellow.withValues(alpha: 0.5);
    } else if (isLastMoveFrom || isLastMoveTo) {
      backgroundColor = Colors.yellow.withValues(alpha: 0.3);
    } else if (isHintFrom || isHintTo) {
      backgroundColor = Colors.blue.withValues(alpha: 0.4);
    }

    if (isCheck) {
      backgroundColor = Colors.red.withValues(alpha: 0.6);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            // Legal move indicator
            if (isLegalMove)
              Center(
                child: piece != null
                    ? Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black.withOpacity(0.5),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(size / 2),
                        ),
                      )
                    : Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),

            // Piece
            if (piece != null)
              Center(
                child: _ChessPieceWidget(
                  piece: piece!,
                  size: size * 0.85,
                ),
              ),

            // Rank label (1-8)
            if (rankLabel != null)
              Positioned(
                top: 2,
                left: 2,
                child: Text(
                  rankLabel!,
                  style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: isLight
                        ? Color(boardTheme.darkSquare)
                        : Color(boardTheme.lightSquare),
                  ),
                ),
              ),

            // File label (a-h)
            if (fileLabel != null)
              Positioned(
                bottom: 2,
                right: 2,
                child: Text(
                  fileLabel!,
                  style: TextStyle(
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: isLight
                        ? Color(boardTheme.darkSquare)
                        : Color(boardTheme.lightSquare),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Chess piece widget using Unicode characters
class _ChessPieceWidget extends StatelessWidget {
  final chess_lib.Piece piece;
  final double size;

  const _ChessPieceWidget({
    required this.piece,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      _getPieceSymbol(),
      style: TextStyle(
        fontSize: size,
        height: 1,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  String _getPieceSymbol() {
    final isWhite = piece.color == chess_lib.Color.WHITE;

    switch (piece.type) {
      case chess_lib.PieceType.PAWN:
        return isWhite ? '♙' : '♟';
      case chess_lib.PieceType.KNIGHT:
        return isWhite ? '♘' : '♞';
      case chess_lib.PieceType.BISHOP:
        return isWhite ? '♗' : '♝';
      case chess_lib.PieceType.ROOK:
        return isWhite ? '♖' : '♜';
      case chess_lib.PieceType.QUEEN:
        return isWhite ? '♕' : '♛';
      case chess_lib.PieceType.KING:
        return isWhite ? '♔' : '♚';
      default:
        return '';
    }
  }
}

/// Promotion piece selection dialog
class _PromotionDialog extends StatelessWidget {
  final bool isWhite;
  final double squareSize;
  final Function(String) onSelect;
  final VoidCallback onCancel;

  const _PromotionDialog({
    required this.isWhite,
    required this.squareSize,
    required this.onSelect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = ['q', 'r', 'b', 'n'];
    final symbols = isWhite
        ? ['♕', '♖', '♗', '♘']
        : ['♛', '♜', '♝', '♞'];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose promotion piece',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) {
                    return GestureDetector(
                      onTap: () => onSelect(pieces[index]),
                      child: Container(
                        width: squareSize,
                        height: squareSize,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            symbols[index],
                            style: TextStyle(fontSize: squareSize * 0.7),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AI thinking indicator
class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI thinking...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
