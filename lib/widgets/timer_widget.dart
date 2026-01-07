import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';

/// Chess clock / timer display widget
class TimerWidget extends StatelessWidget {
  final bool isWhite;

  const TimerWidget({
    super.key,
    required this.isWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, SettingsProvider>(
      builder: (context, game, settings, child) {
        if (!settings.timerEnabled) {
          return const SizedBox.shrink();
        }

        final timeSeconds = isWhite
            ? game.whiteTimeSeconds
            : game.blackTimeSeconds;

        final isActive = !game.isGameOver &&
            ((isWhite && game.chess.turn.toString() == 'Color.WHITE') ||
                (!isWhite && game.chess.turn.toString() == 'Color.BLACK'));

        final isLowTime = timeSeconds < 60;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isLowTime
                    ? Colors.red.withOpacity(0.2)
                    : Theme.of(context).colorScheme.primaryContainer)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(
                    color: isLowTime
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 20,
                color: isActive
                    ? (isLowTime
                        ? Colors.red
                        : Theme.of(context).colorScheme.onPrimaryContainer)
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(timeSeconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? (isLowTime
                          ? Colors.red
                          : Theme.of(context).colorScheme.onPrimaryContainer)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Dual timer display showing both players
class DualTimerWidget extends StatelessWidget {
  const DualTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        if (!settings.timerEnabled) {
          return const SizedBox.shrink();
        }

        return const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TimerWidget(isWhite: true),
            TimerWidget(isWhite: false),
          ],
        );
      },
    );
  }
}
