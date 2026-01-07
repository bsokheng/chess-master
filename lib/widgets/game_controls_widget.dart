import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// Game control buttons widget
class GameControlsWidget extends StatelessWidget {
  const GameControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ControlButton(
              icon: Icons.undo,
              label: 'Undo',
              onPressed: game.canUndo && !game.isAIThinking
                  ? () => game.undoMove()
                  : null,
            ),
            _ControlButton(
              icon: Icons.lightbulb_outline,
              label: 'Hint',
              onPressed: game.isPlayerTurn &&
                  !game.isAIThinking &&
                  !game.isGameOver
                  ? () => game.getHint()
                  : null,
            ),
            _ControlButton(
              icon: Icons.flip,
              label: 'Flip',
              onPressed: () => game.flipBoard(),
            ),
            _ControlButton(
              icon: Icons.refresh,
              label: 'New',
              onPressed: () => _showNewGameDialog(context),
            ),
          ],
        );
      },
    );
  }

  void _showNewGameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Game'),
        content: const Text('Start a new game? Current progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GameProvider>().newGame();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filled(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: isEnabled
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: isEnabled
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isEnabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal game controls
class CompactGameControlsWidget extends StatelessWidget {
  const CompactGameControlsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: game.canUndo && !game.isAIThinking
                  ? () => game.undoMove()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: 'Hint',
              onPressed: game.isPlayerTurn &&
                  !game.isAIThinking &&
                  !game.isGameOver
                  ? () => game.getHint()
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Flip board',
              onPressed: () => game.flipBoard(),
            ),
          ],
        );
      },
    );
  }
}
