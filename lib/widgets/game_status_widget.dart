import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';

/// Widget displaying current game status
class GameStatusWidget extends StatelessWidget {
  const GameStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        String status;
        Color? statusColor;
        IconData statusIcon;

        if (game.isGameOver) {
          switch (game.gameResult) {
            case GameResult.whiteWins:
              status = 'Checkmate! White wins';
              statusColor = Colors.green;
              statusIcon = Icons.emoji_events;
              break;
            case GameResult.blackWins:
              status = 'Checkmate! Black wins';
              statusColor = Colors.green;
              statusIcon = Icons.emoji_events;
              break;
            case GameResult.draw:
              status = 'Draw';
              statusColor = Colors.orange;
              statusIcon = Icons.handshake;
              break;
            case GameResult.stalemate:
              status = 'Stalemate';
              statusColor = Colors.orange;
              statusIcon = Icons.block;
              break;
            default:
              status = 'Game Over';
              statusColor = Theme.of(context).colorScheme.primary;
              statusIcon = Icons.flag;
          }
        } else if (game.isAIThinking) {
          status = 'AI is thinking...';
          statusColor = Theme.of(context).colorScheme.secondary;
          statusIcon = Icons.psychology;
        } else if (game.isInCheck) {
          status = 'Check!';
          statusColor = Colors.red;
          statusIcon = Icons.warning;
        } else if (game.isPlayerTurn) {
          status = 'Your turn';
          statusColor = Theme.of(context).colorScheme.primary;
          statusIcon = Icons.touch_app;
        } else {
          status = "Opponent's turn";
          statusColor = Theme.of(context).colorScheme.secondary;
          statusIcon = Icons.hourglass_empty;
        }

        final effectiveColor = statusColor ?? Theme.of(context).colorScheme.primary;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 18, color: effectiveColor),
              const SizedBox(width: 8),
              Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: effectiveColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Player info display (name, color, captured pieces)
class PlayerInfoWidget extends StatelessWidget {
  final bool isTop;

  const PlayerInfoWidget({
    super.key,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        // Determine which player to show based on position and board flip
        final showBlack = isTop != game.isBoardFlipped;
        final isPlayer = (showBlack && game.playerColor == PlayerColor.black) ||
            (!showBlack && game.playerColor == PlayerColor.white);
        final isActive = showBlack
            ? game.chess.turn.toString() == 'Color.BLACK'
            : game.chess.turn.toString() == 'Color.WHITE';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Player indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: showBlack ? Colors.black87 : Colors.white,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    showBlack ? '♚' : '♔',
                    style: TextStyle(
                      fontSize: 18,
                      color: showBlack ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Player name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isPlayer ? 'You' : 'AI (${game.difficulty.displayName})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      showBlack ? 'Black' : 'White',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Active indicator
              if (isActive && !game.isGameOver)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
