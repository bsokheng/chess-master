import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// Widget displaying the move history in algebraic notation
class MoveHistoryWidget extends StatelessWidget {
  final double? maxHeight;

  const MoveHistoryWidget({
    super.key,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        if (game.moveHistory.isEmpty) {
          return Container(
            constraints: BoxConstraints(maxHeight: maxHeight ?? 120),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No moves yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(maxHeight: maxHeight ?? 120),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _buildMoveWidgets(context, game),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMoveWidgets(BuildContext context, GameProvider game) {
    final widgets = <Widget>[];

    for (int i = 0; i < game.moveHistory.length; i += 2) {
      final moveNumber = (i ~/ 2) + 1;
      final whiteMove = game.moveHistory[i];
      final blackMove = i + 1 < game.moveHistory.length
          ? game.moveHistory[i + 1]
          : null;

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$moveNumber.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              _MoveText(
                notation: whiteMove.algebraicNotation,
                isCheck: whiteMove.isCheck,
                isCheckmate: whiteMove.isCheckmate,
                isCapture: whiteMove.capturedPiece != null,
              ),
              if (blackMove != null) ...[
                const SizedBox(width: 8),
                _MoveText(
                  notation: blackMove.algebraicNotation,
                  isCheck: blackMove.isCheck,
                  isCheckmate: blackMove.isCheckmate,
                  isCapture: blackMove.capturedPiece != null,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}

class _MoveText extends StatelessWidget {
  final String notation;
  final bool isCheck;
  final bool isCheckmate;
  final bool isCapture;

  const _MoveText({
    required this.notation,
    required this.isCheck,
    required this.isCheckmate,
    required this.isCapture,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = Theme.of(context).colorScheme.onSurface;

    if (isCheckmate) {
      textColor = Colors.red;
    } else if (isCheck) {
      textColor = Colors.orange;
    } else if (isCapture) {
      textColor = Theme.of(context).colorScheme.primary;
    }

    return Text(
      notation,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: textColor,
        fontWeight: isCheckmate ? FontWeight.bold : FontWeight.normal,
        fontFamily: 'monospace',
      ),
    );
  }
}

/// Compact move history for inline display
class CompactMoveHistoryWidget extends StatelessWidget {
  const CompactMoveHistoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        if (game.moveHistory.isEmpty) {
          return const SizedBox.shrink();
        }

        final lastMove = game.moveHistory.last;
        final moveNumber = (game.moveHistory.length + 1) ~/ 2;
        final isWhiteMove = game.moveHistory.length % 2 == 1;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '$moveNumber${isWhiteMove ? '.' : '...'} ${lastMove.algebraicNotation}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
